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

/// Example demonstrating stateful session resumption.
///
/// This example shows how to persist conversation state across process
/// restarts using a conversation ID and a storage directory.
///
/// Demonstrates:
/// 1. Running two independent agent sessions sharing the same [saveDir].
/// 2. Session 1 establishing context ("my favorite color is blue"),
///    retrieving its assigned [conversationId], and stopping.
/// 3. Session 2 resuming with the saved [conversationId] and verifying
///    recall — confirming that the prior trajectory was restored.
///
/// To run:
///   dart run example/getting_started/persistence.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. Session 1 establishes context and retrieves a conversation_id.
///   3. Session 2 resumes using the saved conversation_id and save_dir.
///   4. The agent in session 2 recalls information from session 1.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  final saveDir = Directory.systemTemp.createTempSync('agent_session_').path;
  print('  Save directory: $saveDir');

  // ---------------------------------------------------------------------------
  // Session 1: Establish context
  // ---------------------------------------------------------------------------
  print('\n  === Session 1: establishing context ===');

  // Specify [saveDir] to ensure conversation history and artifacts are
  // persisted to disk.
  final config1 = LocalAgentConfig(saveDir: saveDir);
  final agent1 = Agent(config1);
  await agent1.start();

  String? conversationId;
  try {
    const prompt1 = 'Remember this: my favorite color is blue.';
    print('  User: $prompt1');
    final response1 = await agent1.chat(prompt1);
    print('  Agent: ${await response1.text()}');

    // Read back the conversation_id assigned by the runtime.
    conversationId = agent1.conversationId;
    print('  Assigned conversation ID: $conversationId');
  } finally {
    await agent1.stop();
  }
  print('  Session 1 ended.\n');

  // ---------------------------------------------------------------------------
  // Session 2: Resume and verify recall
  // ---------------------------------------------------------------------------
  print('  === Session 2: resuming and verifying recall ===');

  // By providing the exact same [saveDir] and the prior [conversationId] the
  // new agent instance automatically restores the previous conversation
  // history and context.
  final config2 = LocalAgentConfig(
    conversationId: conversationId,
    saveDir: saveDir,
  );
  final agent2 = Agent(config2);
  await agent2.start();

  try {
    const prompt2 = 'What is my favorite color?';
    print('  User: $prompt2');
    final response2 = await agent2.chat(prompt2);
    print('  Agent: ${await response2.text()}');
  } finally {
    await agent2.stop();
  }
  print('  Session 2 ended.');
}
