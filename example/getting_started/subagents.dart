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

/// Example demonstrating subagents in Google Antigravity SDK.
///
/// This example shows how an agent can spawn a subagent to delegate a specific
/// task, in this case, researching the examples directory to generate a lesson
/// plan.
///
/// Subagents are valuable for scoping context usage. By delegating a heavy research
/// task to a subagent, the main agent avoids filling its own context window with
/// all the raw documents, receiving only the synthesized result.
///
/// To run:
///   dart run example/getting_started/subagents.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with return code 0 (no unhandled exceptions).
///   2. The agent spawns a subagent to research the examples directory.
///   3. The subagent hook logs fire when the subagent is created and completes.
///   4. The agent produces a non-empty lesson plan based on the subagent's
///      research.
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'package:antigravity/antigravity.dart';

bool _subagentActive = false;

class LogPreToolHook extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    if (data.name == BuiltinTools.startSubagent.value) {
      _subagentActive = true;
      print('\n  --- 🤖 [Hook] Spawning Subagent ---');
      print('  Arguments: ${data.args}\n');
    } else {
      final indent = _subagentActive ? '    ' : '  ';
      print('$indent- [Start]: ${data.name} (ID: ${data.id})');
    }
    return HookResult(allow: true);
  }
}

class LogPostToolHook extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    if (data.name == BuiltinTools.startSubagent.value) {
      _subagentActive = false;
      print('\n  --- 🤖 [Hook] Subagent Finished ---');
      print('  Result: ${data.result}\n');
    } else {
      final indent = _subagentActive ? '    ' : '  ';
      print('$indent- [Done]: ${data.name} (ID: ${data.id}) ✅');
    }
  }
}

Future<void> main() async {
  // Enable subagents in the config and add hooks for visibility.
  final config = LocalAgentConfig(
    capabilities: CapabilitiesConfig(enableSubagents: true),
    hooks: [LogPreToolHook(), LogPostToolHook()],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    // Prompt the agent to use a subagent to research and generate a lesson plan.
    const prompt =
        'Use a subagent to research the Google Antigravity SDK examples in the parent'
        ' directory. Delegate the task of listing and reading the files to the'
        ' subagent, and then generate a lesson plan for me to learn more based'
        ' on its findings.';
    print('  User: $prompt');

    final response = await agent.chat(prompt);

    // Await the full aggregated text response. This includes both the
    // subagent's output and the main agent's regular response text.
    final responseText = await response.text();
    print('\n  Agent:\n$responseText');
  } finally {
    await agent.stop();
  }
}
