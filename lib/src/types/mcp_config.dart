import 'package:dart_mappable/dart_mappable.dart';

part 'mcp_config.mapper.dart';

/// Abstract base for all MCP server configurations.
@MappableClass(discriminatorKey: 'type')
abstract class McpServerConfig with McpServerConfigMappable {
  McpServerConfig();
  String get type;

  static const fromMap = McpServerConfigMapper.fromMap;
  static const fromJson = McpServerConfigMapper.fromJson;
}

@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  discriminatorValue: 'stdio',
  ignoreNull: true,
)
class McpStdioServer extends McpServerConfig with McpStdioServerMappable {
  final String command;
  final List<String> args;

  @override
  String get type => 'stdio';

  McpStdioServer({required this.command, List<String>? args})
    : args = args ?? [];

  static const fromMap = McpStdioServerMapper.fromMap;
  static const fromJson = McpStdioServerMapper.fromJson;
}

@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  discriminatorValue: 'sse',
  ignoreNull: true,
)
class McpSseServer extends McpServerConfig with McpSseServerMappable {
  final String url;
  final Map<String, String>? headers;

  @override
  String get type => 'sse';

  McpSseServer({required this.url, this.headers});

  static const fromMap = McpSseServerMapper.fromMap;
  static const fromJson = McpSseServerMapper.fromJson;
}

@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  discriminatorValue: 'http',
  ignoreNull: true,
)
class McpStreamableHttpServer extends McpServerConfig
    with McpStreamableHttpServerMappable {
  final String url;
  final Map<String, String>? headers;
  final double timeout;
  final double sseReadTimeout;
  final bool terminateOnClose;

  @override
  String get type => 'http';

  McpStreamableHttpServer({
    required this.url,
    this.headers,
    this.timeout = 30.0,
    this.sseReadTimeout = 300.0,
    this.terminateOnClose = true,
  });

  static const fromMap = McpStreamableHttpServerMapper.fromMap;
  static const fromJson = McpStreamableHttpServerMapper.fromJson;
}
