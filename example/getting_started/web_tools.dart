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

/// Example demonstrating web search (SEARCH_WEB) using the Antigravity Dart SDK.
///
/// To run:
/// ```sh
/// dart run example/getting_started/web_tools.dart
/// ```
///
/// The agent is configured with the built-in [BuiltinTools.searchWeb] capability,
/// enabling it to perform grounded, real-time Google Search queries.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // Configure the agent to use the web search tool.
  final config = LocalAgentConfig(
    capabilities: CapabilitiesConfig(
      enabledTools: [BuiltinTools.searchWeb],
    ),
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt =
        'What is the current weather and temperature in New York City right '
        'now? Please provide the source.';

    print('User: $prompt\n');
    print('Agent is thinking and searching...');

    final response = await agent.chat(prompt);

    // Await the full aggregated text response.
    final responseText = await response.text();
    print('\nAgent Response:\n$responseText');
  } finally {
    await agent.stop();
  }
}
