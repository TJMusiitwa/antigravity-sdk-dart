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

/// Example demonstrating tool call policies.
///
/// This example shows how to secure an agent using declarative tool call
/// policies. By default [LocalAgentConfig] uses [confirmRunCommand] which
/// denies [BuiltinTools.runCommand] and allows all other tools. To lock down
/// further for production or untrusted environments, override this default
/// with explicit safety policies. To open up full access pass
/// [allowAll] as the single policy.
///
/// Policies operate at the runtime decision layer: tools remain visible in
/// the agent's context, but calls that violate policies are denied with an
/// explanation, letting the agent understand why and adapt.
///
/// Demonstrates:
/// 1. "Deny by Default" posture — block all tools, explicitly allow only what
///    is necessary.
/// 2. Specific deny rules (blocking dangerous commands that contain "rm").
/// 3. Specific allow rules (allowing only specific safe tools).
/// 4. Interactive confirmation rules using [askUser].
///
/// To run:
///   dart run example/getting_started/policies.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The listing-files prompt succeeds because list_directory is allowed.
///   3. The rm -rf prompt is denied by the dangerous-command policy.
///   4. The production.key prompt triggers ask_user and is denied.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// Predicates
// ---------------------------------------------------------------------------

/// Returns true if the run_command call contains 'rm'.
bool _blockRmPredicate(ToolCall toolCall) {
  final commandLine = toolCall.args['command_line']?.toString() ?? '';
  return commandLine.contains('rm');
}

/// Returns true if the file path targets a critical / production file.
bool _criticalFilePredicate(ToolCall toolCall) {
  final path = (toolCall.args['path'] ??
              toolCall.args['file_path'] ??
              toolCall.args['TargetFile'])
          ?.toString() ??
      '';
  return path.endsWith('.key') || path.contains('production');
}

// ---------------------------------------------------------------------------
// Ask-User handler
// ---------------------------------------------------------------------------

/// Simulates programmatic user confirmation for [askUser] policies.
///
/// In an interactive CLI you might prompt stdin. For automated workflows
/// return `true` (approve) or `false` (deny) based on your own logic.
Future<bool> programmaticApprovalHandler(ToolCall toolCall) async {
  print(
    '\n  [ASK_USER Handler] Intercepted request for tool: ${toolCall.name}',
  );
  print('  [ASK_USER Handler] Target arguments: ${toolCall.args}');
  print('  [ASK_USER Handler] Simulating user review… Decision: DENY.');
  return false;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  print('  === Tool Call Policies Demo ===');

  // Configure policies using the recommended "Deny by Default" posture.
  // Priority order:  Specific Deny > Specific Ask > Specific Allow > Wildcard Deny
  final policies = [
    // 1. Deny everything by default.
    denyAll(),

    // 2. Allow reading directory contents.
    allow(BuiltinTools.listDirectory.value),

    // 3. Allow running commands — but block dangerous 'rm' commands.
    allow(BuiltinTools.runCommand.value),
    deny(
      BuiltinTools.runCommand.value,
      when: _blockRmPredicate,
      name: 'block-rm',
    ),

    // 4. Allow editing/creating files — but ask the user first for critical files.
    allow(BuiltinTools.editFile.value),
    allow(BuiltinTools.createFile.value),
    askUser(
      BuiltinTools.editFile.value,
      handler: programmaticApprovalHandler,
      when: _criticalFilePredicate,
      name: 'ask-for-critical-edits',
    ),
    askUser(
      BuiltinTools.createFile.value,
      handler: programmaticApprovalHandler,
      when: _criticalFilePredicate,
      name: 'ask-for-critical-creates',
    ),
  ];

  final config = LocalAgentConfig(policies: policies);
  final agent = Agent(config);
  await agent.start();

  try {
    print('\n  Chatting with agent…');

    // Try a safe command — should be allowed.
    const prompt1 = 'List the files in the current directory.';
    print('\n  User: $prompt1');
    final response1 = await agent.chat(prompt1);
    print('  Agent: ${await response1.text()}');

    // Try a dangerous command — should be denied by policy.
    const prompt2 = 'Delete all files using rm -rf.';
    print('\n  User: $prompt2');
    final response2 = await agent.chat(prompt2);
    print('  Agent: ${await response2.text()}');

    // Try creating a critical file — triggers programmatic ask_user handler.
    const prompt3 =
        "Create a new configuration file named production.key with content 'debug=true'.";
    print('\n  User: $prompt3');
    final response3 = await agent.chat(prompt3);
    print('  Agent: ${await response3.text()}');
  } finally {
    await agent.stop();
  }
}
