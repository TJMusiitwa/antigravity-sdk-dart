import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../agent.dart';
import '../hooks/hooks.dart';
import '../hooks/policy.dart' as policy_module;
import '../types.dart';

// A shared broadcast stream for stdin lines to prevent "Stream has already been listened to" errors.
Stream<String>? _stdinLines;

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
  }
}

/// A policy handler that prompts the user for confirmation before executing a tool.
Future<bool> askUserHandler(ToolCall tc) async {
  print("\nPolicy check: Tool execution requested: ${tc.name}");
  if (tc.args.isNotEmpty) {
    print("Arguments: ${tc.args}");
  }
  try {
    final ans = await asyncInput("Allow execution? (y/n) [n]: ");
    return ans.trim().toLowerCase() == 'y' || ans.trim().toLowerCase() == 'yes';
  } catch (_) {
    return false;
  }
}

/// Hook that prompts the user to answer questions asked by the agent.
class AskQuestionHook extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec spec,
  ) async {
    final responses = <QuestionResponse>[];
    try {
      for (final q in spec.questions) {
        print("\nQuestion: ${q.question}");
        final options = q.options;
        for (var i = 0; i < options.length; i++) {
          print("  ${i + 1}. ${options[i].text}");
        }
        final ans = (await asyncInput("Response: ")).trim();
        if (ans.isEmpty) {
          responses.add(QuestionResponse(skipped: true));
          continue;
        }

        String? matchedId;
        if (options.isNotEmpty) {
          try {
            final selectedIdx = int.parse(ans) - 1;
            if (selectedIdx >= 0 && selectedIdx < options.length) {
              matchedId = options[selectedIdx].id;
            }
          } catch (_) {}

          if (matchedId == null) {
            for (final opt in options) {
              if (ans.toLowerCase() == opt.text.toLowerCase() ||
                  ans.toLowerCase() == opt.id.toLowerCase()) {
                matchedId = opt.id;
                break;
              }
            }
          }
        }

        if (matchedId != null) {
          responses.add(QuestionResponse(selectedOptionIds: [matchedId]));
        } else {
          responses.add(QuestionResponse(freeformResponse: ans));
        }
      }
    } catch (_) {
      return QuestionHookResult(responses: responses, cancelled: true);
    }
    return QuestionHookResult(responses: responses);
  }
}

void _upgradeToInteractiveConfirmation(Agent agent) {
  final config = agent.config;
  final upgraded = <policy_module.Policy>[];
  for (final p in config.policies) {
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

  config.policies.clear();
  config.policies.addAll(upgraded);

  final newHook = policy_module.enforce(upgraded);
  final runner = agent.hookRunner;
  if (runner == null) {
    throw StateError("Agent must be started before upgrading policies.");
  }

  final list = runner.preToolCallDecideHooks;
  for (var i = 0; i < list.length; i++) {
    if (list[i] is policy_module.PolicyDecideHook) {
      list[i] = newHook;
      return;
    }
  }
  list.add(newHook);
}

/// Runs an interactive CLI loop for debugging and development.
Future<void> runInteractiveLoop(Agent agent) async {
  if (!agent.isStarted) {
    throw StateError("Agent session not started. Call 'await agent.start()'.");
  }

  agent.registerHook(AskQuestionHook());
  _upgradeToInteractiveConfirmation(agent);

  print("Starting interactive loop. Type 'exit' or 'quit' to end.");
  while (true) {
    try {
      final userInput = (await asyncInput("User: ")).trim();
      if (userInput.isEmpty) {
        continue;
      }
      if (userInput.toLowerCase() == 'exit' ||
          userInput.toLowerCase() == 'quit') {
        print("Goodbye!");
        break;
      }

      await agent.conversation.send(userInput);

      final spinner = Spinner(message: "Thinking...");
      spinner.start();

      Step? finalStep;
      await for (final step in agent.conversation.receiveSteps()) {
        if (step.type == StepType.toolCall) {
          final toolName = step.toolCalls.isNotEmpty
              ? step.toolCalls.first.name
              : "tool";
          spinner.update("Running tool '$toolName'...");
        } else if (step.type == StepType.compaction) {
          spinner.update("Compacting context...");
        } else if (step.source == StepSource.model &&
            step.thinkingDelta.isNotEmpty) {
          spinner.update("Reasoning...");
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
    } on OSError catch (_) {
      print("\nGoodbye!");
      break;
    } catch (e) {
      print("Error: $e");
    }
  }
}

/// A lightweight terminal spinner for async processing feedback.
class Spinner {
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

  void start() {
    if (!_enabled) return;
    _running = true;
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

  void stop() {
    if (!_enabled) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    stdout.write("\r\x1b[K");
  }
}
