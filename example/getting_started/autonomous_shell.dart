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

/// Example demonstrating how to enable autonomous shell access.
///
/// By default [LocalAgentConfig] uses [confirmRunCommand] which denies
/// [BuiltinTools.runCommand]. For agents that need shell access — such as
/// coding assistants or system automation tools — opt in by passing
/// [allowAll] as the single policy.
///
/// > **Warning**
/// > [allowAll] grants the agent unrestricted tool access, including
/// > arbitrary shell command execution. Only use this in trusted environments.
///
/// To run:
///   dart run example/getting_started/autonomous_shell.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent produces a non-empty text response.
///   3. The response contains the output of the shell command.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // [allowAll] grants the agent full access to all tools, including
  // run_command (shell execution). This overrides the default
  // [confirmRunCommand] policy.
  final config = LocalAgentConfig(policies: [allowAll()]);

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = "Run 'echo Hello from the shell!' and show me the output.";
    print('  User: $prompt');

    final response = await agent.chat(prompt);
    final responseText = await response.text();
    print('  Agent: $responseText');
  } finally {
    await agent.stop();
  }
}
