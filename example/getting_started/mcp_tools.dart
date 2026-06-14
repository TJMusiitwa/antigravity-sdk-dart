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

/// MCP Integration example for the Google Antigravity Dart SDK.
///
/// Dart port of `examples/getting_started/mcp_tools.py` from the official
/// Python SDK. Demonstrates how to connect an agent to an external MCP server
/// using the stdio transport.
///
/// The pirate math MCP server (`example/resources/mcp_server.dart`) is spawned
/// automatically as a child process via [McpStdioServer]. The agent discovers
/// its tools at startup and can call them during the conversation.
///
/// Prerequisites:
///   1. Export your Gemini API key:
///        export GEMINI_API_KEY="your_actual_key"
///   2. Add dart_mcp to pubspec.yaml dev_dependencies (required by mcp_server.dart):
///        dart_mcp: ^0.5.1
///
/// To run:
///   dart run example/getting_started/mcp_tools.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent successfully calls pirate_multiply via the MCP server.
///   3. The result matches the pirate math formula: (a + b) * 7 - 13.
// ignore_for_file: avoid_print
library;

import 'dart:io';

import 'package:antigravity/antigravity.dart';

Future<void> mcpStdio() async {
  print('\n  --- Showcasing Stdio Transport ---');

  // Resolve the path to the Dart MCP server relative to this script.
  // mcp_server.dart is in example/resources/ alongside this script's parent.
  final scriptDir = File(Platform.script.toFilePath()).parent.parent;
  final mcpServerPath =
      '${scriptDir.path}${Platform.pathSeparator}resources${Platform.pathSeparator}mcp_server.dart';

  final stdioServer = McpStdioServer(
    name: 'pirate-math',
    command: 'dart',
    args: ['run', mcpServerPath],
  );

  final config = LocalAgentConfig(
    mcpServers: [stdioServer],
    // MCP servers count as write-capable tools; a policy is required.
    policies: [allowAll()],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'Use the pirate_multiply tool to multiply 5 and 7.';
    print('  User: $prompt');
    final response = await agent.chat(prompt);
    print('  Agent: ${await response.text()}');
  } finally {
    await agent.stop();
  }
}

Future<void> main() async {
  await mcpStdio();
}
