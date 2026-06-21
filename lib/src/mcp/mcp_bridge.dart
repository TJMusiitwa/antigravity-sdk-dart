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

/// Dart bridge between MCP servers and the SDK ToolRunner.
///
/// Uses `package:mcp_dart` for robust, standard-compliant MCP client and transport implementations.
library;

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:mcp_dart/mcp_dart.dart' hide Tool, Logger;

import '../tools/tool_runner.dart';
import '../types/mcp_config.dart';

final _logger = Logger('antigravity.mcp');

/// A tool discovered from an MCP server, wrapped in the SDK's [Tool] interface.
class McpTool extends Tool {
  McpTool._({
    required super.name,
    required super.description,
    required Map<String, dynamic> schema,
    required McpClient client,
  }) : super(
          schema: {
            'name': name,
            'description': description,
            'input_schema': schema,
          },
          handler: (args, context) async {
            final result = await client.callTool(
              CallToolRequest(name: name, arguments: args),
            );
            if (result.isError == true) {
              throw Exception('MCP tool call "$name" failed');
            }
            // Extract text content from MCP result
            return result.content
                .whereType<TextContent>()
                .map((c) => c.text)
                .join('\n');
          },
        );
}

/// Facilitates connecting to external Model Context Protocol (MCP) servers and exposes their tools to the Google Antigravity SDK.
class McpBridge {
  final List<McpClient> _clients = [];
  final List<McpTool> _tools = [];
  final McpClient Function(Implementation)? _clientFactory;

  /// Creates a new [McpBridge] instance with an optional [clientFactory].
  McpBridge({McpClient Function(Implementation)? clientFactory})
      : _clientFactory = clientFactory;

  /// All tools discovered from all connected MCP servers.
  List<McpTool> get tools => List.unmodifiable(_tools);

  /// Connects to an MCP server based on its configuration type.
  Future<void> connect(McpServerConfig serverCfg) async {
    final impl = Implementation(name: 'antigravity-dart-sdk', version: '0.2.0');
    final client =
        _clientFactory != null ? _clientFactory!(impl) : McpClient(impl);

    dynamic transport;

    if (serverCfg is McpStdioServer) {
      _logger.info(
        'Connecting to MCP server via stdio: ${serverCfg.command} ${serverCfg.args.join(' ')}',
      );
      transport = StdioClientTransport(
        StdioServerParameters(command: serverCfg.command, args: serverCfg.args),
      );
    } else if (serverCfg is McpStreamableHttpServer) {
      _logger.info('Connecting to MCP server via HTTP: ${serverCfg.url}');
      final opts = serverCfg.headers != null
          ? StreamableHttpClientTransportOptions(
              requestInit: {'headers': serverCfg.headers},
            )
          : null;
      transport = StreamableHttpClientTransport(
        Uri.parse(serverCfg.url),
        opts: opts,
      );
    } else {
      _logger.warning(
        'MCP server type "${serverCfg.type}" is not yet supported by the Dart SDK bridge.',
      );
      return;
    }

    try {
      await client.connect(transport);
      _clients.add(client);

      final toolResult = await client.listTools();
      for (final tool in toolResult.tools) {
        _tools.add(
          McpTool._(
            name: tool.name,
            description: tool.description ?? '',
            schema: Map<String, dynamic>.from(tool.inputSchema.toJson()),
            client: client,
          ),
        );
      }
    } catch (e) {
      _logger.severe('Failed to initialize MCP server: $e');
      // Ensure we disconnect if connection failed partially
      await client.close();
      rethrow;
    }
  }

  /// Stops all active MCP sessions and releases resources.
  Future<void> stop() async {
    for (final client in _clients) {
      try {
        await client.close();
      } catch (e) {
        _logger.warning('Error disconnecting MCP client: $e');
      }
    }
    _clients.clear();
    _tools.clear();
  }
}
