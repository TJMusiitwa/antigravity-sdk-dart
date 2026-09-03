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

/// Example demonstrating Vertex AI authentication modes.
///
/// Setting [LocalAgentConfig.vertex] routes model calls through Vertex AI
/// instead of the Gemini API. There are two mutually exclusive modes:
///   1. Express Mode — a Vertex AI API key (`VERTEX_API_KEY`), no GCP project
///      setup required.
///   2. Standard Mode — a GCP project and location
///      (`GOOGLE_CLOUD_PROJECT` / `GOOGLE_CLOUD_LOCATION`), authenticated via
///      Application Default Credentials (`gcloud auth application-default login`).
///
/// Configuration comes from the environment, so no argument parsing is needed:
///   VERTEX_API_KEY=...                       # Express Mode
///   GOOGLE_CLOUD_PROJECT=... GOOGLE_CLOUD_LOCATION=us-central1   # Standard Mode
///
/// To run:
///   VERTEX_API_KEY=your-key dart run example/getting_started/vertex.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with exit code 0 (no unhandled exceptions).
///   2. Exactly one authentication mode is selected; supplying both, or
///      neither, prints usage guidance and exits with a non-zero code.
///   3. The agent produces a non-empty text response.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:antigravity/antigravity.dart';

const _usage = '''
Set exactly one Vertex AI authentication mode:

  Express Mode:
    VERTEX_API_KEY=<api-key>

  Standard Mode:
    GOOGLE_CLOUD_PROJECT=<project-id> GOOGLE_CLOUD_LOCATION=<location>
''';

Future<void> main() async {
  final env = Platform.environment;
  final apiKey = env['VERTEX_API_KEY'];
  final project = env['GOOGLE_CLOUD_PROJECT'];
  final location = env['GOOGLE_CLOUD_LOCATION'];

  final hasExpress = apiKey != null && apiKey.isNotEmpty;
  final hasStandard = project != null && project.isNotEmpty;

  if (hasExpress && hasStandard) {
    print(
      'Express Mode (VERTEX_API_KEY) and Standard Mode '
      '(GOOGLE_CLOUD_PROJECT) are mutually exclusive.\n',
    );
    print(_usage);
    exitCode = 1;
    return;
  }
  if (!hasExpress && !hasStandard) {
    print('No Vertex AI credentials found in the environment.\n');
    print(_usage);
    exitCode = 1;
    return;
  }

  final LocalAgentConfig config;
  if (hasExpress) {
    print('Using Vertex AI Express Mode (API key).');
    config = LocalAgentConfig(vertex: true, apiKey: apiKey);
  } else {
    // Location defaults to a common Vertex AI region when unset.
    final resolvedLocation =
        (location == null || location.isEmpty) ? 'us-central1' : location;
    print(
      'Using Vertex AI Standard Mode '
      '(project: $project, location: $resolvedLocation).',
    );
    config = LocalAgentConfig(
      vertex: true,
      project: project,
      location: resolvedLocation,
    );
  }

  final agent = Agent(config);
  await agent.start();
  try {
    const prompt = 'In one sentence, what is Vertex AI?';
    print('\n  User: $prompt');

    final response = await agent.chat(prompt);
    print('  Agent: ${(await response.text()).trim()}');
  } finally {
    await agent.stop();
  }
}
