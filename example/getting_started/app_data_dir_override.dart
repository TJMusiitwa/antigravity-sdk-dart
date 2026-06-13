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

/// Example demonstrating app_data_dir override in Google Antigravity SDK.
///
/// This example shows how to configure an agent with a custom application data
/// directory (`appDataDir`) to control where the agent stores artifacts, scratch
/// files, and uploaded media.
///
/// To run:
///   dart run example/getting_started/app_data_dir_override.dart
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // Create a temporary directory for the custom application data storage
  final tempDir = Directory.systemTemp.createTempSync('agent_appdata_');
  final customAppData = tempDir.absolute.path;
  print('  Custom App Data Dir: $customAppData\n');

  // Initialize the agent config with our custom appDataDir override
  final config = LocalAgentConfig(appDataDir: customAppData);

  final agent = Agent(config);
  await agent.start();

  try {
    print(
      '  Agent Session Started. Conversation ID: ${agent.conversationId}\n',
    );

    const prompt =
        "Please create an artifact file named 'dart_best_practices.md' "
        "summarizing Dart best practices.";
    print('  User:  $prompt');
    final response = await agent.chat(prompt);
    print('  Agent: ${await response.text()}\n');

    // Verify that the artifact was successfully stored in our custom appDataDir
    final cid = agent.conversationId;
    if (cid != null) {
      final expectedArtifactPath = p.join(
        customAppData,
        'brain',
        cid,
        'dart_best_practices.md',
      );

      print('  Checking artifact location: $expectedArtifactPath');
      if (File(expectedArtifactPath).existsSync()) {
        print(
          '\n  SUCCESS: Verified artifact successfully stored in custom appDataDir!',
        );
      } else {
        print('\n  WARNING: Artifact was not found in custom appDataDir.');
      }
    }
  } finally {
    await agent.stop();
    // Clean up custom directory
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}
