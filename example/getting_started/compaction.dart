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

/// Example demonstrating context compaction policy in the Google Antigravity SDK.
///
/// Long-running sessions eventually outgrow the model's context window. The
/// harness handles this by periodically summarising older history into a
/// checkpoint. [CompactionConfig] exposes two dials for that behavior:
///   1. [CompactionConfig.checkpointIntervalTokens] — how many tokens of
///      history accumulate before a background checkpoint (summary) is prepared.
///   2. [CompactionConfig.maxContextTokens] — the hard ceiling on the context
///      window, past which older turns are evicted.
///
/// To run:
///   dart run example/getting_started/compaction.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with exit code 0 (no unhandled exceptions).
///   2. The agent answers each turn without exceeding the configured context.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  final config = LocalAgentConfig(
    compactionConfig: CompactionConfig(
      // Interval at which background checkpoints (summaries) are prepared.
      checkpointIntervalTokens: 40000,
      // Maximum context window ceiling before older turns are evicted.
      maxContextTokens: 100000,
    ),
  );

  print('Compaction policy:');
  print(
    '  checkpointIntervalTokens: '
    '${config.compactionConfig?.checkpointIntervalTokens}',
  );
  print('  maxContextTokens: ${config.compactionConfig?.maxContextTokens}');

  final agent = Agent(config);
  await agent.start();
  try {
    const prompts = [
      'Name three programming languages designed in the 1970s.',
      'Which of those is still most widely used today, and why?',
    ];

    for (final prompt in prompts) {
      print('\n  User: $prompt');
      final response = await agent.chat(prompt);
      print('  Agent: ${(await response.text()).trim()}');
    }

    // The conversation keeps its own history; compaction is applied by the
    // harness transparently as the token budget above is consumed.
    print('\nHistory steps retained: ${agent.conversation.history.length}');
  } finally {
    await agent.stop();
  }
}
