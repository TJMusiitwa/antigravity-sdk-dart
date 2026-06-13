import 'package:test/test.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:antigravity/antigravity.dart';

class UnsupportedMockConfig extends McpServerConfig {
  @override
  String get type => 'unsupported_mock_type';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('McpBridge Error Handling', () {
    test('Bridge tools list is empty initially', () {
      final bridge = McpBridge();
      expect(bridge.tools, isEmpty);
    });

    test(
      'Bridge logs warning and returns on genuinely unsupported config type',
      () async {
        final bridge = McpBridge();
        // An unrecognized custom server config is logged as warning but doesn't throw,
        // ensuring the SDK doesn't crash on future config types.
        await bridge.connect(UnsupportedMockConfig());
        expect(bridge.tools, isEmpty);
      },
    );

    test('Bridge attempts to connect and throws on invalid SSE endpoint', () {
      final bridge = McpBridge();
      // McpSseServer is now supported and will attempt connection,
      // throwing a network or host lookup exception for invalid hosts.
      expect(
        () => bridge.connect(McpSseServer(url: 'http://unsupported')),
        throwsException,
      );
    });
  });

  group('ToolCall & ToolResult JSON logic', () {
    test('ToolCall handles both arguments and arguments_json', () {
      final map1 = {'name': 't1', 'arguments_json': '{"a":1}'};
      final map2 = {
        'name': 't1',
        'arguments': {'a': 1},
      };

      final tc1 = ToolCall.fromMap(map1);
      final tc2 = ToolCall.fromMap(map2);

      expect(tc1.args, equals({'a': 1}));
      expect(tc2.args, equals({'a': 1}));
      expect(tc1, equals(tc2)); // Value equality from dart_mappable!
    });

    test('ToolResult serialization consistency', () {
      final tr = ToolResult(name: 'fin', result: 'ok');
      final map = tr.toMap();
      expect(map['name'], equals('fin'));
      expect(map['result'], equals('ok'));
    });
  });

  group('McpBridge with FakeMcpClient', () {
    test(
      'Successful connection, tool listing, calling, and stopping',
      () async {
        final fakeTool = FakeTool(
          name: 'hello_world',
          description: 'Friendly greeting',
        );

        FakeMcpClient? activeClient;
        final bridge = McpBridge(
          clientFactory: (impl) {
            activeClient = FakeMcpClient(
              mockTools: [fakeTool],
              mockCallHandler: (req) {
                return mcp.CallToolResult(
                  content: [mcp.TextContent(text: 'Hello, world!')],
                );
              },
            );
            return activeClient!;
          },
        );

        await bridge.connect(McpSseServer(url: 'http://localhost:1234'));

        expect(bridge.tools, hasLength(1));
        final mcpTool = bridge.tools.first;
        expect(mcpTool.name, equals('hello_world'));
        expect(mcpTool.description, equals('Friendly greeting'));

        final callResult = await mcpTool.handler({}, null);
        expect(callResult, equals('Hello, world!'));

        expect(activeClient?.connectedTransport, isNotNull);

        await bridge.stop();
        expect(activeClient?.isClosed, isTrue);
        expect(bridge.tools, isEmpty);
      },
    );

    test('Tool call handles failure scenarios by throwing', () async {
      final fakeTool = FakeTool(name: 'fail_tool');
      final bridge = McpBridge(
        clientFactory: (impl) {
          return FakeMcpClient(
            mockTools: [fakeTool],
            mockCallHandler: (req) {
              return mcp.CallToolResult(isError: true, content: []);
            },
          );
        },
      );

      await bridge.connect(McpSseServer(url: 'http://localhost:1234'));
      expect(bridge.tools, hasLength(1));

      expect(() => bridge.tools.first.handler({}, null), throwsException);
    });

    test('Successful connection via stdio', () async {
      final bridge = McpBridge(
        clientFactory: (impl) => FakeMcpClient(mockTools: []),
      );

      await bridge.connect(McpStdioServer(command: 'echo', args: ['hello']));

      expect(bridge.tools, isEmpty);
    });

    test('Successful connection via HTTP', () async {
      final bridge = McpBridge(
        clientFactory: (impl) => FakeMcpClient(mockTools: []),
      );

      await bridge.connect(
        McpStreamableHttpServer(url: 'http://localhost:8080'),
      );

      expect(bridge.tools, isEmpty);
    });

    test('Stop catches and logs exception if close throws', () async {
      final bridge = McpBridge(
        clientFactory: (impl) =>
            FakeMcpClient(mockTools: [], shouldThrowOnClose: true),
      );

      await bridge.connect(McpSseServer(url: 'http://localhost:1234'));
      // Should handle the error internally and not throw
      await bridge.stop();
    });
  });
}

class FakeTool implements mcp.Tool {
  @override
  final String name;
  @override
  final String? description;
  @override
  final mcp.ToolInputSchema inputSchema;

  FakeTool({
    required this.name,
    this.description,
    mcp.ToolInputSchema? inputSchema,
  }) : inputSchema = inputSchema ?? mcp.ToolInputSchema();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMcpClient implements mcp.McpClient {
  final List<mcp.Tool> mockTools;
  final mcp.CallToolResult Function(mcp.CallToolRequest)? mockCallHandler;
  final bool shouldThrowOnClose;
  bool isClosed = false;
  dynamic connectedTransport;

  FakeMcpClient({
    this.mockTools = const [],
    this.mockCallHandler,
    this.shouldThrowOnClose = false,
  });

  @override
  Future<void> connect(dynamic transport) async {
    connectedTransport = transport;
  }

  @override
  Future<mcp.ListToolsResult> listTools({
    mcp.RequestOptions? options,
    mcp.ListToolsRequest? params,
  }) async {
    return mcp.ListToolsResult(tools: mockTools);
  }

  @override
  Future<mcp.CallToolResult> callTool(
    mcp.CallToolRequest request, {
    dynamic options,
  }) async {
    if (mockCallHandler != null) {
      return mockCallHandler!(request);
    }
    return mcp.CallToolResult(
      content: [mcp.TextContent(text: 'Fake success for ${request.name}')],
    );
  }

  @override
  Future<void> close() async {
    isClosed = true;
    if (shouldThrowOnClose) {
      throw Exception('Close failed');
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
