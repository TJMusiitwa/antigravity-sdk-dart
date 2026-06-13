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

/// Simple hello world example for the unofficial Dart Antigravity SDK.
///
/// This example demonstrates the simplest way to interact with an agent:
/// - Creating a [LocalAgentConfig] (and how to explicitly select a model).
/// - Starting and stopping an [Agent] session.
/// - Sending a simple prompt and awaiting the full text response.
///
/// To run:
///   dart run example/getting_started/hello_world.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent produces a non-empty text response.
///   3. The response contains "Hello World" or a close greeting variant.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // To explicitly set the model, pass it to LocalAgentConfig:
  // final config = LocalAgentConfig(model: 'gemini-3.5-flash');
  final config = LocalAgentConfig();

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = "Say 'Hello World!'";
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    // Await the full aggregated text response.
    final responseText = await response.text();
    print('  Agent: $responseText');
  } finally {
    await agent.stop();
  }
}
