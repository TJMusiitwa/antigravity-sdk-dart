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

/// Example demonstrating all supported lifecycle hooks.
///
/// This example shows how to implement hook classes for various lifecycle
/// events: session, turn, tool, interaction, and compaction.
///
/// To run:
///   dart run example/getting_started/hooks.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. Session lifecycle hooks (OnSessionStart, OnSessionEnd) fire.
///   3. Turn hooks (PreTurn, PostTurn) fire around agent chat calls.
///   4. Tool hooks (PreToolCallDecide, PostToolCall) fire when greet is used.
///   5. The OnToolError hook fires when the agent calls broken_tool.
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';
import 'package:antigravity/antigravity.dart';

// -----------------------------------------------------------------------------
// Session Hooks
// -----------------------------------------------------------------------------

class MySessionStartHook extends OnSessionStartHook {
  @override
  Future<void> run(HookContext context, void data) async {
    print('\n  [Hook] Session started');
  }
}

class MySessionEndHook extends OnSessionEndHook {
  @override
  Future<void> run(HookContext context, void data) async {
    print('\n  [Hook] Session ended');
  }
}

// -----------------------------------------------------------------------------
// Turn Hooks
// -----------------------------------------------------------------------------

class MyPreTurnHook extends PreTurnHook {
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async {
    print(
      '\n  [Hook] Pre-turn: Intercepted prompt -> ${data.toString().length > 60 ? '${data.toString().substring(0, 60)}…' : data}',
    );
    return HookResult(allow: true);
  }
}

class MyPostTurnHook extends PostTurnHook {
  @override
  Future<void> run(HookContext context, String data) async {
    final preview = data.length > 60 ? '${data.substring(0, 60)}…' : data;
    print('\n  [Hook] Post-turn: Final response -> $preview');
  }
}

// -----------------------------------------------------------------------------
// Tool Hooks
// -----------------------------------------------------------------------------

class MyPreToolHook extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    print('\n  [Hook] Pre-tool-call: Approving tool -> ${data.name}');
    return HookResult(allow: true);
  }
}

class MyPostToolHook extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    print('\n  [Hook] Post-tool-call: Result -> ${data.result ?? data.error}');
  }
}

class MyOnToolErrorHook extends OnToolErrorHook {
  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    print('\n  [Hook] Tool error: $data');
    return null; // Let the error propagate.
  }
}

// -----------------------------------------------------------------------------
// Interaction Hook
// -----------------------------------------------------------------------------

class MyOnInteractionHook extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec data,
  ) async {
    print(
      '\n  [Hook] Interaction requested: ${data.questions.map((q) => q.question).toList()}',
    );
    // Auto-select the first option if available, or provide a default answer.
    final responses = data.questions.map((q) {
      if (q.options.isNotEmpty) {
        return QuestionResponse(selectedOptionIds: [q.options.first.id]);
      }
      return QuestionResponse(freeformResponse: 'Auto-response');
    }).toList();
    return QuestionHookResult(responses: responses);
  }
}

// -----------------------------------------------------------------------------
// Compaction Hook
// -----------------------------------------------------------------------------

class MyOnCompactionHook extends OnCompactionHook {
  @override
  Future<void> run(HookContext context, dynamic data) async {
    print('\n  [Hook] Context compaction occurred at step: $data');
  }
}

// -----------------------------------------------------------------------------
// Helper Tools
// -----------------------------------------------------------------------------

final greetTool = Tool(
  name: 'greet',
  description: 'Greets a person by name.',
  schema: {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'The name to greet.'},
    },
    'required': ['name'],
  },
  handler: (args, _) async => 'Hello, ${args['name']}!',
);

final brokenTool = Tool(
  name: 'broken_tool',
  description: 'Fails always with an exception.',
  schema: {'type': 'object', 'properties': {}},
  handler: (args, ctx) async =>
      throw Exception('This tool is intentionally broken!'),
);

// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

Future<void> main() async {
  final config = LocalAgentConfig(
    hooks: [
      MySessionStartHook(),
      MySessionEndHook(),
      MyPreTurnHook(),
      MyPostTurnHook(),
      MyPreToolHook(),
      MyPostToolHook(),
      MyOnToolErrorHook(),
      MyOnInteractionHook(),
      MyOnCompactionHook(),
    ],
    tools: [greetTool, brokenTool],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    print('  --- Starting Interaction ---');

    // 1. Trigger Turn Hooks.
    print('\n  --- Prompt 1: Simple Chat ---');
    final r1 = await agent.chat("Say 'Hello World!'");
    stdout.write('  Agent Response: ');
    await for (final chunk in r1.textStream) {
      stdout.write(chunk);
    }
    print('');

    // 2. Trigger Tool Hooks.
    print('\n  --- Prompt 2: Tool Usage ---');
    final r2 = await agent.chat('Please greet Alice using the greet tool.');
    stdout.write('  Agent Response: ');
    await for (final chunk in r2.textStream) {
      stdout.write(chunk);
    }
    print('');

    // 3. Trigger Tool Error Hook.
    print('\n  --- Prompt 3: Tool Error ---');
    final r3 = await agent.chat('Please call the broken_tool tool.');
    stdout.write('  Agent Response: ');
    await for (final chunk in r3.textStream) {
      stdout.write(chunk);
    }
    print('');

    // 4. Trigger Interaction Hook (agent asks a question).
    print('\n  --- Prompt 4: Interaction ---');
    final r4 = await agent.chat('Ask me a multiple-choice trivia question.');
    stdout.write('  Agent Response: ');
    await for (final chunk in r4.textStream) {
      stdout.write(chunk);
    }
    print('');

    print('\n  --- Finished Interaction ---');
  } finally {
    await agent.stop();
  }
}
