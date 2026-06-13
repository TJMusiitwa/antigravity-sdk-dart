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

/// Unofficial Dart SDK for Google Antigravity — example entry point.
///
/// This file shows the minimum viable agent interaction. For more complete
/// examples, see the `example/getting_started/` directory which mirrors the
/// getting-started examples from the official Python SDK:
///
/// | File                                                      | Concept                           |
/// |-----------------------------------------------------------|-----------------------------------|
/// | getting_started/hello_world.dart                         | Simple prompt + full text reply   |
/// | getting_started/streaming.dart                           | Streamed thoughts and text tokens |
/// | getting_started/custom_tools.dart                        | Stateless and stateful tools      |
/// | getting_started/hooks.dart                               | All nine lifecycle hook types     |
/// | getting_started/policies.dart                            | Declarative safety policies       |
/// | getting_started/persistence.dart                         | Session resumption via save_dir   |
/// | getting_started/triggers.dart                            | Periodic and custom triggers      |
/// | getting_started/structured_output.dart                   | Schema-guided JSON responses      |
/// | getting_started/observability.dart                       | Audit hooks and token usage       |
/// | getting_started/autonomous_shell.dart                    | allow_all() shell access          |
/// | getting_started/multimodal.dart                          | Image and document inputs         |
/// | getting_started/human_in_the_loop.dart                   | Stdin interaction hook            |
///
/// Prerequisites:
///   • Install the Google Antigravity CLI so it is on your PATH, or set
///     the ANTIGRAVITY_HARNESS_PATH environment variable to its location.
///   • Export your Gemini API key:
///       export GEMINI_API_KEY="your-key-here"
///
/// Run this entry point with:
///   dart run example/main.dart
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  final config = LocalAgentConfig();
  final agent = Agent(config);

  print('Starting agent…');
  try {
    await agent.start();
  } on AntigravityBinaryNotFoundException catch (e) {
    print('\n$e');
    exit(1);
  }

  print('Agent ready (conversation: ${agent.conversationId ?? 'pending'})');

  const prompt = "Say 'Hello from the Dart SDK!'";
  print('\n  User: $prompt');

  final response = await agent.chat(prompt);

  stdout.write('  Agent: ');
  await for (final token in response.textStream) {
    stdout.write(token);
  }
  print('');

  await agent.stop();
  print('\nDone. Explore getting_started/ for more examples.');
}
