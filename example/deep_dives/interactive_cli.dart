// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Example demonstrating interactive agent CLI loop, custom tools, and tool approval.
///
/// This example shows how to:
/// 1. Define custom Tools (including pirate math tools) and register them in AgentConfig.
/// 2. Configure hook-based tool approval policy with CLI confirmation.
/// 3. Listen to agent question interaction prompts using a custom OnInteractionHook.
/// 4. Run an interactive terminal conversation loop displaying realtime streaming chunks.
///
/// To run:
///   dart run example/deep_dives/interactive_cli.dart [--show_usage]
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';

// Path to the Dart MCP server relative to the project root.
// Resolved at runtime so it works regardless of where the script is invoked.
String _mcpServerPath() {
  final script = File(Platform.script.toFilePath());
  // script is example/deep_dives/interactive_cli.dart → go up two levels to project root
  final projectRoot = script.parent.parent.parent;
  return '${projectRoot.path}${Platform.pathSeparator}example'
      '${Platform.pathSeparator}resources'
      '${Platform.pathSeparator}mcp_server.dart';
}

// --- Input Helper ---

Future<String> asyncInput(String prompt) async {
  stdout.write(prompt);
  final line = stdin.readLineSync() ?? '';
  return line;
}

// --- Custom Tool ---

final readFileUpsideDownTool = Tool(
  name: 'read_file_upside_down',
  description:
      'Reads the file at the given path and returns its content with lines inverted.',
  schema: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'The path to the file to read.',
      },
    },
    'required': ['path'],
  },
  handler: (args, context) async {
    final path = args['path'] as String;
    final file = File(path);
    if (!await file.exists()) {
      return 'Error: File does not exist';
    }
    final lines = await file.readAsLines();
    return lines.reversed.join('\n');
  },
);

// --- Custom Hooks & Policies ---

class AskQuestionHook extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec data,
  ) async {
    final questions = data.questions;
    final List<QuestionResponse> responses = [];

    try {
      for (final q in questions) {
        print('\nQuestion: ${q.question}');
        final options = q.options;
        for (int idx = 0; idx < options.length; idx++) {
          print('  ${idx + 1}. ${options[idx].text}');
        }

        final ans = (await asyncInput('Response: ')).trim();
        if (ans.isEmpty) {
          responses.add(QuestionResponse(skipped: true));
          continue;
        }

        // Try to match by option number
        String? matchedId;
        if (options.isNotEmpty) {
          try {
            final selectedIdx = int.parse(ans) - 1;
            if (selectedIdx >= 0 && selectedIdx < options.length) {
              matchedId = options[selectedIdx].id;
            }
          } catch (_) {}

          // Try to match by exact option text or ID
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

Future<bool> askUserHandler(ToolCall tc) async {
  print('\nPolicy check: Tool execution requested: ${tc.name}');
  if (tc.args.isNotEmpty) {
    print('Arguments: ${tc.args}');
  }

  try {
    final ans = await asyncInput('Allow execution? (y/n) [n]: ');
    return ans.trim().toLowerCase() == 'y' || ans.trim().toLowerCase() == 'yes';
  } catch (_) {
    return false;
  }
}

// --- Telemetry Logger ---

void printTelemetry(
  UsageMetadata? turnUsage,
  UsageMetadata cumul,
  List<Step> history,
) {
  print('\n--- Turn Token Usage ---');
  if (turnUsage != null) {
    print('  Prompt tokens:   ${turnUsage.promptTokenCount}');
    print('  Cached tokens:   ${turnUsage.cachedContentTokenCount}');
    print('  Output tokens:   ${turnUsage.candidatesTokenCount}');
    print('  Thinking tokens: ${turnUsage.thoughtsTokenCount}');
    print('  Total tokens:    ${turnUsage.totalTokenCount}');
  } else {
    print('  Usage data not available for this turn.');
  }

  // Cumulative session usage.
  print('\n--- Session Cumulative Usage ---');
  print('  Prompt tokens:   ${cumul.promptTokenCount}');
  print('  Cached tokens:   ${cumul.cachedContentTokenCount}');
  print('  Output tokens:   ${cumul.candidatesTokenCount}');
  print('  Thinking tokens: ${cumul.thoughtsTokenCount}');
  print('  Total tokens:    ${cumul.totalTokenCount}');

  // Trajectory summary.
  print('\n--- Trajectory (${history.length} steps) ---');
  for (int i = 0; i < history.length; i++) {
    final s = history[i];
    var label =
        '    [$i] ${s.type.value} (${s.source.value}) - ${s.status.value}';
    if (s.toolCalls.isNotEmpty) {
      final names = s.toolCalls.map((tc) => tc.name).join(', ');
      label += ' [$names]';
    }
    print(label);
  }
  print('');
}

// --- Main Runner ---

Future<void> main(List<String> args) async {
  String modelName = 'gemini-3.5-flash';
  String? systemInstruction;
  bool disableRunCommand = false;
  bool showUsage = false;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--model_name' && i + 1 < args.length) {
      modelName = args[i + 1];
      i++;
    } else if (args[i] == '--system_instruction' && i + 1 < args.length) {
      systemInstruction = args[i + 1];
      i++;
    } else if (args[i] == '--disable_run_command') {
      disableRunCommand = true;
    } else if (args[i] == '--show_usage') {
      showUsage = true;
    } else if (args[i] == '--help' || args[i] == '-h') {
      print(
        'Usage: dart run example/deep_dives/interactive_cli.dart [options]',
      );
      print('Options:');
      print(
        '  --model_name <name>        The Gemini model to use (default: gemini-3.5-flash)',
      );
      print('  --system_instruction <txt> System instructions for the agent');
      print('  --disable_run_command      Disable the run_command tool');
      print(
        '  --show_usage               Display token usage and trajectory after each turn',
      );
      return;
    }
  }

  // Pirate math tools are served by the external MCP server (mcp_server.dart)
  // via the stdio transport, discovered automatically at agent start.
  final mcpServer = McpStdioServer(
    name: 'pirate-math',
    command: 'dart',
    args: ['run', _mcpServerPath()],
  );

  final config = LocalAgentConfig(
    model: modelName,
    systemInstructions: systemInstruction,
    tools: [readFileUpsideDownTool],
    mcpServers: [mcpServer],
    policies: [askUser('*', handler: askUserHandler)],
    hooks: [AskQuestionHook()],
    capabilities: CapabilitiesConfig(
      disabledTools: disableRunCommand ? [BuiltinTools.runCommand] : null,
    ),
  );

  final agent = Agent(config);
  await agent.start();

  try {
    print('\nGoogle Antigravity SDK Interactive CLI Demo');
    print(
      'Type your message and press Enter • Type "exit" or "quit" to end the session\n',
    );

    while (true) {
      final userInput = (await asyncInput('\n→ ')).trim();
      if (userInput.isEmpty) {
        continue;
      }
      if (userInput.toLowerCase() == 'exit' ||
          userInput.toLowerCase() == 'quit') {
        print('\nGoodbye! 👋');
        break;
      }

      try {
        final response = await agent.chat(userInput);

        // Stream the response to stdout
        await for (final chunk in response.textStream) {
          stdout.write(chunk);
        }
        print('');

        if (showUsage) {
          printTelemetry(
            agent.conversation.lastTurnUsage,
            agent.conversation.totalUsage,
            agent.conversation.history,
          );
        }
      } catch (e) {
        print('\nError during turn: $e');
      }
    }
  } finally {
    await agent.stop();
  }
}
