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

/// Example demonstrating the opt-in OS-level command sandbox.
///
/// Setting [RunCommandConfig.enableSandbox] asks the harness to execute every
/// `run_command` invocation inside an OS-level sandbox, confined to the agent's
/// workspace. This is defence in depth: even when policies allow all commands,
/// the sandbox blocks writes outside the workspace.
///
/// The script asks the agent to write to a path outside its workspace (the
/// "escape probe"). With the sandbox on, that write should fail.
///
/// To run:
///   dart run example/getting_started/sandboxing.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with exit code 0 (no unhandled exceptions).
///   2. The escape probe file is NOT created when the sandbox is active.
///   3. If the probe file appears, a WARNING is printed — the sandbox is
///      unavailable in this environment and enableSandbox had no effect.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  final workspace = await Directory.systemTemp.createTemp('sandbox_demo_ws_');
  // Deliberately outside the workspace: a sandboxed command must not reach it.
  final escapeProbePath =
      p.join(Directory.systemTemp.path, 'sandbox_escape_probe.txt');
  final escapeProbe = File(escapeProbePath);
  if (await escapeProbe.exists()) {
    await escapeProbe.delete();
  }

  final config = LocalAgentConfig(
    workspaces: [workspace.path],
    capabilities: CapabilitiesConfig(
      enabledTools: [BuiltinTools.runCommand, BuiltinTools.finish],
      // Opt in to the OS-level sandbox for terminal commands.
      runCommandConfig: RunCommandConfig(enableSandbox: true),
    ),
    // Policies and the sandbox are independent layers: even with every command
    // allowed, the sandbox still confines filesystem writes.
    policies: [allowAll()],
  );

  final agent = Agent(config);
  await agent.start();
  try {
    print('Workspace:    ${workspace.path}');
    print('Escape probe: $escapeProbePath');

    // 1. A write inside the workspace, which the sandbox permits.
    print('\n--- In-workspace write (expected to succeed) ---');
    final inside = await agent.chat(
      'Run a shell command that writes the text "inside" to a file named '
      'inside.txt in the current workspace directory.',
    );
    print('  Agent: ${(await inside.text()).trim()}');
    final insideFile = File(p.join(workspace.path, 'inside.txt'));
    print('  inside.txt created: ${await insideFile.exists()}');

    // 2. A write outside the workspace, which the sandbox should block.
    print('\n--- Escape probe (expected to be blocked) ---');
    final outside = await agent.chat(
      'Run a shell command that writes the text "escaped" to the absolute '
      'path $escapeProbePath.',
    );
    print('  Agent: ${(await outside.text()).trim()}');

    if (await escapeProbe.exists()) {
      print(
        '\n  WARNING: $escapeProbePath was created. The OS-level sandbox is '
        'unavailable in this environment, so enableSandbox had no effect. '
        'Do not rely on it as your only containment layer here.',
      );
      await escapeProbe.delete();
    } else {
      print('\n  [Sandboxed] The write outside the workspace was blocked.');
    }
  } finally {
    await agent.stop();
    await workspace.delete(recursive: true);
  }
}
