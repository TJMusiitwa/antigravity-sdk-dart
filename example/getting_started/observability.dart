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

/// Example demonstrating observability features.
///
/// This example shows how to:
/// - Use hooks to create a basic audit log of tool calls.
/// - Access token usage metadata, including thinking tokens.
///
/// To run:
///   dart run example/getting_started/observability.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent calls the get_weather tool and returns weather information.
///   3. The audit log hook fires and logs the tool call result.
///   4. Token usage metadata is printed, showing prompt, output, and total
///      token counts.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// A simple tool to demonstrate tool call hooks.
// ---------------------------------------------------------------------------
final getWeatherTool = Tool(
  name: 'get_weather',
  description: 'Gets the weather for a location.',
  schema: {
    'type': 'object',
    'properties': {
      'location': {
        'type': 'string',
        'description': 'The location to get weather for.',
      },
    },
    'required': ['location'],
  },
  handler: (args, _) async => 'The weather in ${args['location']} is sunny.',
);

// ---------------------------------------------------------------------------
// Post-tool hook used to create a simple audit log of tool calls.
// ---------------------------------------------------------------------------
class AuditLogToolCallHook extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    print(
      '\n  [AUDIT] Tool execution completed. Result: ${data.result ?? data.error}',
    );
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
Future<void> main() async {
  final config = LocalAgentConfig(
    tools: [getWeatherTool],
    hooks: [AuditLogToolCallHook()],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'What is the weather in Seattle?';
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    // Stream the response to stdout.
    stdout.write('  Agent: ');
    await for (final chunk in response.textStream) {
      stdout.write(chunk);
    }
    print('');

    // Access token usage from the conversation.
    final usage = agent.conversation.totalUsage;
    print('\n  --- Token Usage ---');
    print('  Prompt tokens:   ${usage.promptTokenCount ?? 0}');
    print('  Output tokens:   ${usage.candidatesTokenCount ?? 0}');
    print('  Thinking tokens: ${usage.thoughtsTokenCount ?? 0}');
    print('  Total tokens:    ${usage.totalTokenCount ?? 0}');
  } finally {
    await agent.stop();
  }
}
