import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../agent.dart';
import '../hooks/hooks.dart';
import '../hooks/policy.dart' as policy_module;
import '../types.dart';
import '../connections/connection.dart';

// A shared broadcast stream for stdin lines to prevent "Stream has already been listened to" errors.
Stream<String>? _stdinLines;

/// Formats CLI interactive step spinner messages for single, concurrent, compaction, or reasoning steps.
String? formatStepSpinnerMessage(Step step) {
  if (step.type == StepType.toolCall) {
    if (step.toolCalls.length == 1) {
      return "Running tool '${step.toolCalls.first.name}'...";
    } else if (step.toolCalls.length > 1) {
      final toolNames = step.toolCalls.map((tc) => "'${tc.name}'").join(', ');
      return 'Running tools $toolNames...';
    }
    return 'Running tool...';
  } else if (step.type == StepType.compaction) {
    return 'Compacting context...';
  } else if (step.source == StepSource.model && step.thinkingDelta.isNotEmpty) {
    return 'Reasoning...';
  }
  return null;
}

Stream<String> get _getStdinLines {
  _stdinLines ??= stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .asBroadcastStream();
  return _stdinLines!;
}

/// Helper to read input asynchronously from standard input.
Future<String> asyncInput(String prompt) async {
  stdout.write(prompt);
  final lines = _getStdinLines;
  final completer = Completer<String>();
  late StreamSubscription<String> sub;
  sub = lines.listen(
    (line) {
      sub.cancel();
      completer.complete(line);
    },
    onError: (err) {
      sub.cancel();
      completer.completeError(err);
    },
    onDone: () {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const OSError("stdin closed"));
      }
    },
  );
  return completer.future;
}

/// Hook that prompts the user for confirmation before executing a tool.
class ToolConfirmationHook extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall toolCall) async {
    Spinner.pauseActive();
    try {
      print("\nTool execution requested: ${toolCall.name}");
      if (toolCall.args.isNotEmpty) {
        print("Arguments: ${toolCall.args}");
      }
      try {
        final ans = await asyncInput("Allow execution? (y/n) [n]: ");
        if (ans.trim().toLowerCase() == 'y' ||
            ans.trim().toLowerCase() == 'yes') {
          return HookResult(allow: true);
        }
      } catch (_) {}
      return HookResult(allow: false, message: "User denied tool call.");
    } finally {
      Spinner.resumeActive();
    }
  }
}

/// A policy handler that prompts the user for confirmation before executing a tool.
Future<bool> askUserHandler(ToolCall tc) async {
  Spinner.pauseActive();
  try {
    print("\nPolicy check: Tool execution requested: ${tc.name}");
    if (tc.args.isNotEmpty) {
      print("Arguments: ${tc.args}");
    }
    try {
      final ans = await asyncInput("Allow execution? (y/n) [n]: ");
      return ans.trim().toLowerCase() == 'y' ||
          ans.trim().toLowerCase() == 'yes';
    } catch (_) {
      return false;
    }
  } finally {
    Spinner.resumeActive();
  }
}

/// Hook that prompts the user to answer questions asked by the agent.
class AskQuestionHook extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec spec,
  ) async {
    Spinner.pauseActive();
    try {
      final responses = <QuestionResponse>[];
      try {
        for (final q in spec.questions) {
          responses.add(await _promptSingleQuestion(q));
        }
      } catch (_) {
        return QuestionHookResult(responses: responses, cancelled: true);
      }
      return QuestionHookResult(responses: responses);
    } finally {
      Spinner.resumeActive();
    }
  }

  static Future<QuestionResponse> _promptSingleQuestion(AskQuestionEntry q) async {
    print("\nQuestion: ${q.question}");
    for (var i = 0; i < q.options.length; i++) {
      print("  ${i + 1}. ${q.options[i].text}");
    }
    final ans = (await asyncInput("Response: ")).trim();
    if (ans.isEmpty) {
      return QuestionResponse(skipped: true);
    }

    final matchedId = _resolveSelectedOptionId(q.options, ans);
    if (matchedId != null) {
      return QuestionResponse(selectedOptionIds: [matchedId]);
    }
    return QuestionResponse(freeformResponse: ans);
  }

  static String? _resolveSelectedOptionId(List<AskQuestionOption> options, String ans) {
    if (options.isEmpty) return null;

    final parsedIdx = int.tryParse(ans);
    if (parsedIdx != null) {
      final idx = parsedIdx - 1;
      if (idx >= 0 && idx < options.length) {
        return options[idx].id;
      }
    }

    final lowerAns = ans.toLowerCase();
    for (final opt in options) {
      if (lowerAns == opt.text.toLowerCase() || lowerAns == opt.id.toLowerCase()) {
        return opt.id;
      }
    }
    return null;
  }
}

List<policy_module.Policy> _upgradePoliciesList(
    List<policy_module.Policy> policies) {
  final upgraded = <policy_module.Policy>[];
  for (final p in policies) {
    if (p.tool == BuiltinTools.runCommand.value &&
        p.decision == policy_module.Decision.deny &&
        p.when == null) {
      upgraded.add(
        policy_module.askUser(
          BuiltinTools.runCommand.value,
          handler: askUserHandler,
          name: p.name.isNotEmpty ? p.name : 'interactive_confirm',
        ),
      );
    } else {
      upgraded.add(p);
    }
  }
  return upgraded;
}

/// Runs an interactive CLI loop for debugging and development.
Future<void> runInteractiveLoop(
  AgentConfig config, {
  Agent Function(AgentConfig config)? agentFactory,
}) async {
  final hooksList = List<Hook>.from(config.hooks);
  if (!hooksList.any((hook) => hook is AskQuestionHook)) {
    hooksList.add(AskQuestionHook());
  }

  final policiesList = _upgradePoliciesList(config.policies);
  final upgradedConfig = config.copyWith(
    hooks: hooksList,
    policies: policiesList,
  );

  final agent = agentFactory != null
      ? agentFactory(upgradedConfig)
      : Agent(upgradedConfig);
  await agent.start();

  try {
    print("Starting interactive loop. Type 'exit' or 'quit' to end.");
    while (true) {
      final shouldContinue = await _executeInteractiveTurn(agent);
      if (!shouldContinue) break;
    }
  } finally {
    await agent.stop();
  }
}

Future<bool> _executeInteractiveTurn(Agent agent) async {
  try {
    final userInput = (await asyncInput("User: ")).trim();
    if (userInput.isEmpty) return true;
    if (userInput.toLowerCase() == 'exit' || userInput.toLowerCase() == 'quit') {
      print("Goodbye!");
      return false;
    }

    await _streamAgentTurn(agent, userInput);
    return true;
  } on OSError catch (_) {
    print("\nGoodbye!");
    return false;
  } catch (e) {
    print("Error: $e");
    return true;
  }
}

Future<void> _streamAgentTurn(Agent agent, String userInput) async {
  await agent.conversation.send(userInput);

  final spinner = Spinner(message: "Thinking...");
  spinner.start();

  Step? finalStep;
  await for (final step in agent.conversation.receiveSteps()) {
    final spinnerMsg = formatStepSpinnerMessage(step);
    if (spinnerMsg != null) {
      spinner.update(spinnerMsg);
    }
    if (step.isCompleteResponse == true) {
      finalStep = step;
      break;
    }
  }

  spinner.stop();
  if (finalStep != null) {
    print("Agent: ${finalStep.content}");
  }
}

/// A lightweight terminal spinner for async processing feedback.
class Spinner {
  static Spinner? _activeSpinner;

  /// Pauses the currently active spinner.
  static void pauseActive() {
    _activeSpinner?.pause();
  }

  /// Resumes the currently active spinner.
  static void resumeActive() {
    _activeSpinner?.resume();
  }

  String _currentMessage;
  bool _running = false;
  Timer? _timer;
  final List<String> _frames = [
    "⠋",
    "⠙",
    "⠹",
    "⠸",
    "⠼",
    "⠴",
    "⠦",
    "⠧",
    "⠇",
    "⠏",
  ];
  final bool _enabled;

  Spinner({String message = "Thinking..."})
      : _currentMessage = message,
        _enabled = stdout.hasTerminal;

  void update(String message) {
    _currentMessage = message;
  }

  void _runTimer() {
    int idx = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }
      stdout.write("\r\x1b[K${_frames[idx]} $_currentMessage");
      idx = (idx + 1) % _frames.length;
    });
  }

  void start() {
    _activeSpinner = this;
    if (!_enabled) return;
    _running = true;
    _runTimer();
  }

  void pause() {
    if (!_enabled || !_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    stdout.write("\r\x1b[K");
  }

  void resume() {
    if (!_enabled || _running) return;
    _running = true;
    _runTimer();
  }

  void stop() {
    if (_activeSpinner == this) {
      _activeSpinner = null;
    }
    if (!_enabled) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    stdout.write("\r\x1b[K");
  }
}
