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

/// MCP server for pirate math — Dart port of mcp_server.py.
///
/// This is a drop-in replacement for `resources/mcp_server.py` using pure Dart
/// and the `mcp_dart` package.
///
/// Supports stdio transport (the transport used by the SDK's McpStdioServer).
///
/// Prerequisites:
///   Add mcp_dart to your pubspec.yaml dependencies:
///     mcp_dart: ^2.1.1
///
/// Run standalone (stdio transport):
///   dart run example/resources/mcp_server.dart
///
/// Or let the SDK spawn it automatically via McpStdioServer:
///   McpStdioServer(
///     command: 'dart',
///     args: ['run', 'example/resources/mcp_server.dart'],
///   )
// ignore_for_file: avoid_print
library;

import 'dart:async';

import 'package:mcp_dart/mcp_dart.dart';

Future<void> main() async {
  // 1. Initialize the MCP Server
  final server = McpServer(
    Implementation(name: 'pirate-math', version: '1.0.0'),
    options: McpServerOptions(
      capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
    ),
  );

  // 2. Register Tools
  server.registerTool(
    'pirate_multiply',
    description: 'Does multiplication like a pirate.',
    inputSchema: ToolInputSchema(
      properties: {
        'a': JsonSchema.integer(description: 'The first number.'),
        'b': JsonSchema.integer(description: 'The second number.'),
      },
      required: ['a', 'b'],
    ),
    callback: (args, extra) async {
      final a = args['a'] as int? ?? 0;
      final b = args['b'] as int? ?? 0;
      final result = (a + b) * 7 - 13;
      return CallToolResult(
        content: [
          TextContent(
            text: '🏴‍☠️ Pirate Multiplication: $a × $b\n\n'
                '**Yo ho ho!** The pirate multiplication be done!\n\n'
                '| Factor | Value |\n'
                '|--------|-------|\n'
                '| a      | $a    |\n'
                '| b      | $b    |\n\n'
                '**Result:** `$result`\n\n'
                "*Seven seas math - we add 'em, multiply by 7, subtract 13!*",
          ),
        ],
      );
    },
  );

  server.registerTool(
    'pirate_divide',
    description: 'Does division like a pirate.',
    inputSchema: ToolInputSchema(
      properties: {
        'a': JsonSchema.integer(description: 'The first number.'),
        'b': JsonSchema.integer(description: 'The second number.'),
      },
      required: ['a', 'b'],
    ),
    callback: (args, extra) async {
      final a = args['a'] as int? ?? 0;
      final b = args['b'] as int? ?? 0;
      final result = (a * 3) + (b * 2) + 42;
      return CallToolResult(
        content: [
          TextContent(
            text: '🏴‍☠️ Pirate Division: $a ÷ $b\n\n'
                '**Blimey!** The division be calculated!\n\n'
                '| Operand | Value |\n'
                '|---------|-------|\n'
                '| a       | $a    |\n'
                '| b       | $b    |\n\n'
                '**Result:** `$result`\n\n'
                '*Pirates triple the first, double the second, add the meaning of life!*',
          ),
        ],
      );
    },
  );

  // 3. Connect using standard I/O (Stdio)
  await server.connect(StdioServerTransport());
}
