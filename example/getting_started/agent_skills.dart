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

/// Example demonstrating skill loading for Google Antigravity SDK.
///
/// This example demonstrates how to use `skillsPaths` in `LocalAgentConfig`
/// to point to a directory containing skills and how the agent can recognize them.
///
/// To run:
///   dart run example/getting_started/agent_skills.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with return code 0 (no unhandled exceptions).
///   2. "Loading skills from:" appears in the output, confirming the skill path
///      was resolved.
///   3. The agent produces a non-empty response when asked about its skills.
///   4. The agent's response references at least one skill or capability by name.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // Let's resolve the skills path in the local project directory
  final skillsParentDir = Directory(p.absolute('skills'));
  final skillsPaths = <String>[];

  if (skillsParentDir.existsSync()) {
    final entities = skillsParentDir.listSync();
    for (final entity in entities) {
      if (entity is Directory) {
        final skillFile = File(p.join(entity.path, 'SKILL.md'));
        if (skillFile.existsSync()) {
          skillsPaths.add(entity.path);
        }
      }
    }
  }

  if (skillsPaths.isEmpty) {
    print("Warning: No skills found under: ${skillsParentDir.path}");
  } else {
    print('  Loading skills from:');
    for (final path in skillsPaths) {
      print('    - ${p.relative(path)}');
    }
  }

  // Configure the agent with the skills paths.
  final config = LocalAgentConfig(skillsPaths: skillsPaths);

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'What available skills do you have?';
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    // Await the full aggregated text response.
    final responseText = await response.text();
    print('  Agent: $responseText');
  } finally {
    await agent.stop();
  }
}
