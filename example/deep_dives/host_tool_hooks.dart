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

/// Example demonstrating every supported lifecycle hook in Dart.
///
/// Registers one hook for each supported lifecycle event and logs what was received.
///
/// Run with:
///   dart run example/deep_dives/host_tool_hooks.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';

import 'package:antigravity/antigravity.dart';

// =============================================================================
// Hook implementations — each one simply logs what it received.
// =============================================================================

class LogSessionStart extends OnSessionStartHook {
  @override
  Future<void> run(HookContext context, void data) async {
    print('[Hook] Session started.');
  }
}

class LogSessionEnd extends OnSessionEndHook {
  @override
  Future<void> run(HookContext context, void data) async {
    print('[Hook] Session ended.');
  }
}

class LogPreTurn extends PreTurnHook {
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    print('[Hook] Pre-turn — user prompt: \'$data\'');
    return HookResult(allow: true);
  }
}

class LogPostTurn extends PostTurnHook {
  @override
  Future<void> run(HookContext context, String data) async {
    print('[Hook] Post-turn — response: \'${data.trim()}\'');
  }
}

class LogPreToolCallDecide extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    print('[Hook] Pre-tool-call (decide) — tool: ${data.name}');
    if (data.name == BuiltinTools.startSubagent.value) {
      print('[Hook] Pre-subagent-call — tool_call: ${data.name}');
    }
    return HookResult(allow: true);
  }
}

class LogPostToolCall extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    print('[Hook] Post-tool-call — result: ${data.result}');
    if (data.name == BuiltinTools.startSubagent.value) {
      print('[Hook] Post-subagent-call — result: ${data.result}');
    }
  }
}

class LogToolError extends OnToolErrorHook {
  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    print('[Hook] Tool error — $data');
    return null; // Let the error propagate
  }
}

class LogCompaction extends OnCompactionHook {
  @override
  Future<void> run(HookContext context, dynamic data) async {
    print('[Hook] Compaction — step: $data');
  }
}

class LogInteraction extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec data,
  ) async {
    print(
      '[Hook] Interaction — spec: ${data.questions.map((q) => q.question).toList()}',
    );
    final responses = <QuestionResponse>[];
    for (final q in data.questions) {
      if (q.options.isNotEmpty) {
        responses.add(
          QuestionResponse(selectedOptionIds: [q.options.first.id]),
        );
      } else {
        responses.add(QuestionResponse(freeformResponse: 'auto-response'));
      }
    }
    return QuestionHookResult(responses: responses);
  }
}

// =============================================================================
// Custom tools to trigger tool hooks
// =============================================================================

String greet(String name) {
  return "Hello, $name!";
}

final greetTool = Tool(
  name: 'greet',
  description: 'Greets a user by name.',
  schema: {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'The name to greet.'},
    },
    'required': ['name'],
  },
  handler: (args, _) async => greet(args['name'] as String),
);

String brokenTool() {
  throw StateError("This tool is intentionally broken!");
}

final brokenToolWrapper = Tool(
  name: 'brokenTool',
  description: 'A tool that is intentionally broken.',
  schema: {'type': 'object', 'properties': {}},
  handler: (_, _) async => brokenTool(),
);

// =============================================================================
// Helper to run a single prompt and print the response
// =============================================================================

Future<void> runPrompt(Agent agent, String prompt) async {
  print('\n${'=' * 60}');
  print('--- Sending: \'$prompt\' ---');
  print('=' * 60);

  await agent.conversation.send(prompt);
  await for (final step in agent.conversation.receiveSteps()) {
    if (step.id == 'idle_sentinel') {
      break;
    }
    if (step.isCompleteResponse ?? false) {
      final cascadeId = step.cascadeId;
      final trajectoryId = step.trajectoryId;
      final isParent = cascadeId.isEmpty || trajectoryId == cascadeId;
      final label = isParent ? "Final response" : "Subagent response";
      print('\n--- $label ---\n${step.content}\n');
    }
  }
}

// =============================================================================
// Main
// =============================================================================

Future<void> main() async {
  final config = LocalAgentConfig(
    hooks: [
      LogSessionStart(),
      LogSessionEnd(),
      LogPreTurn(),
      LogPostTurn(),
      LogPreToolCallDecide(),
      LogPostToolCall(),
      LogToolError(),
      LogCompaction(),
      LogInteraction(),
    ],
    tools: [greetTool, brokenToolWrapper],
    capabilities: CapabilitiesConfig(enableSubagents: true),
  );

  final agent = Agent(config);
  await agent.start();

  try {
    // 1. Tool hooks: greet triggers pre/post tool call.
    await runPrompt(agent, "Please greet Alice using the greet tool.");

    // 2. Tool error hook: brokenTool always raises.
    await runPrompt(agent, "Please call the brokenTool tool.");

    // 3. Interaction hook: ask_question triggers OnInteraction.
    await runPrompt(agent, "Ask me a multiple-choice trivia question.");

    // 4. Subagent hooks: invoke_subagent triggers pre/post subagent.
    await runPrompt(
      agent,
      "Invoke a subagent to write a short poem about nature.",
    );

    print('\n--- All prompts complete ---');
  } finally {
    await agent.stop();
  }
}
