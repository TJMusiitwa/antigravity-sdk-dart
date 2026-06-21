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

/// Example demonstrating streaming responses and thoughts.
///
/// This example shows how to consume streamed content from the agent's response,
/// including thoughts (reasoning), final text answers, and tool calls.
///
/// Available streaming APIs:
/// - [ChatResponse.thoughts] — stream of reasoning/planning text
/// - [ChatResponse.textStream] — stream of final response tokens
/// - [ChatResponse.toolCalls] — stream of tool calls as they are invoked
/// - [ChatResponse.chunks] — unified stream of all content types
///
/// To run:
///   dart run example/getting_started/streaming.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent produces non-empty streamed thought/reasoning content.
///   3. The agent produces a non-empty streamed final answer.
///   4. The response correctly identifies the answer to the riddle (an echo).
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  final config = LocalAgentConfig();

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'Solve this riddle: I speak without a mouth and hear '
        'without ears. I have no body, but I come alive with wind. What am I? '
        'Explain your reasoning.';
    print('  User: $prompt\n');

    final response = await agent.chat(prompt);

    print('  Agent (Streaming thoughts):');
    print('  -------------------------------------------------------');
    await for (final thought in response.thoughts) {
      stdout.write(thought);
    }
    print('\n  -------------------------------------------------------\n');

    print('  Agent (Streaming final answer):');
    print('  -------------------------------------------------------');
    await for (final token in response.textStream) {
      stdout.write(token);
    }
    print('\n  -------------------------------------------------------\n');
  } finally {
    await agent.stop();
  }
}
