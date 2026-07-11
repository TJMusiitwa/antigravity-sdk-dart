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

/// Example demonstrating programmatic task cancellation.
///
/// This example shows:
/// - Programmatic cancellation (aborted via response.cancel()).
/// - Catching the custom AntigravityCancelledException to handle SDK-specific cancellation events.
///
/// To run:
///   dart run example/getting_started/cancellation.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';
import 'package:antigravity/antigravity.dart';

Future<void> renderChat(ChatResponse response) async {
  stdout.write('  Agent Thoughts: ');
  await for (final thought in response.thoughts) {
    stdout.write(thought);
  }

  stdout.write('\n  Agent Response: ');
  await for (final text in response.textStream) {
    stdout.write(text);
  }
  print('');
}

Future<void> main() async {
  final config = LocalAgentConfig();
  final agent = Agent(config);
  await agent.start();

  try {
    // -------------------------------------------------------------------------
    // Scenario 1: Programmatic Cancellation (response.cancel())
    // -------------------------------------------------------------------------
    print('\n=== Scenario 1: Programmatic Cancellation ===');
    const prompt =
        'Write a very long story about a character named cancellation.';
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    final chatFuture = renderChat(response);

    // Wait for a short duration to let generation start.
    print('\n  [Waiting for 3 seconds before programmatically aborting...]');
    await Future.delayed(const Duration(seconds: 3));

    // Cancel the turn programmatically using the response's cancel() method.
    print('\n  [Aborting the turn via response.cancel()]');
    await response.cancel();

    try {
      await chatFuture;
    } on AntigravityCancelledException catch (e) {
      // Programmatic cancellation raises the SDK's custom exception
      print(
          '\n  [Programmatic Cancel Caught] Turn was aborted by the client: $e');
    } catch (e) {
      print('\n  [Error Caught]: $e');
    }

    print('\n  Finished cancellation example.');
  } finally {
    await agent.stop();
  }
}
