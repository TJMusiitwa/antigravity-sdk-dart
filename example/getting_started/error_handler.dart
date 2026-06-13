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

/// Example of handling errors in Google Antigravity SDK.
///
/// This example demonstrates:
/// 1. Using [OnToolErrorHook] to intercept tool errors and provide guidance to the model.
/// 2. Catching specific SDK exceptions in application code using try-catch blocks.
///
/// To run:
///   dart run example/getting_started/error_handler.dart
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

// Define a tool that always fails.
final explodingTool = Tool(
  name: 'exploding_tool',
  description: 'A tool that always fails, regardless of input.',
  schema: {
    'type': 'object',
    'properties': {
      'input_data': {'type': 'string', 'description': 'Any string input.'},
    },
    'required': ['input_data'],
  },
  handler: (args, _) async {
    final inputData = args['input_data'] as String;
    print('\n  🔧 [Tool] Exploding tool called with: $inputData, exploding...');
    throw Exception('This tool is intentionally broken and always fails.');
  },
);

// Define the error handler hook.
class CustomToolErrorHandler extends OnToolErrorHook {
  @override
  Future<dynamic> run(HookContext context, Exception error) async {
    print('\n  🔧 [ErrorHandler] Caught exception: $error');

    // Return a message that the model will see instead of the raw error.
    // This guides the model on how to respond or recover.
    return '[Tool Error: $error Please inform the user that the operation failed.]';
  }
}

Future<void> main() async {
  print('  🔌 Error Handling Example\n');

  // Create the agent configuration with the tool and hook.
  final config = LocalAgentConfig(
    tools: [explodingTool],
    hooks: [CustomToolErrorHandler()],
    // We must permit the exploding_tool
    policies: [allow('exploding_tool')],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = "Use the exploding_tool with input 'test data'.";
    print('  User: $prompt');

    final response = await agent.chat(prompt);
    final responseText = await response.text();
    print('  Agent: $responseText');
  } on AntigravityValidationException catch (e) {
    // Triggered when input validation fails.
    print('\n  [App Error] Validation failed: $e');
  } on AntigravityConnectionException catch (e) {
    // Triggered when connection issues occur.
    print('\n  [App Error] Connection failed: $e');
  } catch (e) {
    // Catch-all for other unexpected errors.
    print('\n  [App Error] Unexpected error: $e');
  } finally {
    await agent.stop();
  }
}
