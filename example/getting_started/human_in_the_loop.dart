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

/// Example demonstrating Human-in-the-Loop interaction.
///
/// This example shows how an agent can pause execution to ask the user for
/// input or clarification. The [OnInteractionHook] intercepts any
/// [AskQuestionInteractionSpec] emitted by the harness and allows your
/// application to route it to the actual user (stdin, UI widget, etc.).
///
/// To run:
///   dart run example/getting_started/human_in_the_loop.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// Interactive question handler — reads answers from stdin.
// ---------------------------------------------------------------------------
class StdinInteractionHook extends OnInteractionHook {
  @override
  Future<QuestionHookResult> run(
    HookContext context,
    AskQuestionInteractionSpec data,
  ) async {
    final responses = <QuestionResponse>[];
    for (final question in data.questions) {
      // AskQuestionEntry.question holds the prompt text.
      print('\n  [Agent asks] ${question.question}');

      if (question.options.isNotEmpty) {
        // Multiple-choice: print options and read a number.
        for (var i = 0; i < question.options.length; i++) {
          print('    ${i + 1}. ${question.options[i].text}');
        }
        stdout.write('  Your choice (number): ');
        final line = stdin.readLineSync() ?? '1';
        final choice = (int.tryParse(line.trim()) ?? 1) - 1;
        final safeChoice = choice.clamp(0, question.options.length - 1);
        responses.add(
          QuestionResponse(
            selectedOptionIds: [question.options[safeChoice].id],
          ),
        );
      } else {
        // Free-form: read any text.
        stdout.write('  Your answer: ');
        final answer = stdin.readLineSync() ?? '';
        responses.add(QuestionResponse(freeformResponse: answer));
      }
    }
    return QuestionHookResult(responses: responses);
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  // Default config enables all tools, including ask_question.
  final config = LocalAgentConfig(
    systemInstructions:
        'When you need clarification or more information from the user to '
        'fulfill a request, you should use the `ask_question` tool to prompt them.',
    hooks: [StdinInteractionHook()],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    // Give the agent an ambiguous prompt to encourage clarification.
    const prompt = 'I want to search for a file.';
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    // Stream the final response.  The StdinInteractionHook handles any
    // ask_question call the agent makes during the turn.
    await for (final chunk in response.textStream) {
      stdout.write(chunk);
    }
    print('');
  } finally {
    await agent.stop();
  }
}
