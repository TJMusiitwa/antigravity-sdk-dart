import 'package:dart_mappable/dart_mappable.dart';

part 'mcp_config.mapper.dart';

/// Abstract base for all MCP server configurations.
@MappableClass(discriminatorKey: 'type')
abstract class McpServerConfig with McpServerConfigMappable {
  McpServerConfig();
  String get type;

  String get name;
  int? get timeoutSeconds;
  List<String>? get enabledTools;
  List<String>? get disabledTools;

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
  final String name;
  @override
  final int? timeoutSeconds;
  @override
  final List<String>? enabledTools;
  @override
  final List<String>? disabledTools;

  @override
  String get type => 'stdio';

  McpStdioServer({
    required this.name,
    required this.command,
    List<String>? args,
    this.timeoutSeconds,
    this.enabledTools,
    this.disabledTools,
  }) : args = args ?? [] {
    final nameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!nameRegex.hasMatch(name)) {
      throw FormatException('Invalid MCP server name: $name');
    }
    if (enabledTools != null && disabledTools != null) {
      throw ArgumentError(
          "enabledTools and disabledTools should be mutually exclusive.");
    }
  }

  static const fromMap = McpStdioServerMapper.fromMap;
  static const fromJson = McpStdioServerMapper.fromJson;
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
  final String name;
  @override
  final int? timeoutSeconds;
  @override
  final List<String>? enabledTools;
  @override
  final List<String>? disabledTools;

  @override
  String get type => 'http';

  McpStreamableHttpServer({
    required this.name,
    required this.url,
    this.headers,
    this.timeout = 30.0,
    this.sseReadTimeout = 300.0,
    this.terminateOnClose = true,
    this.timeoutSeconds,
    this.enabledTools,
    this.disabledTools,
  }) {
    final nameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!nameRegex.hasMatch(name)) {
      throw FormatException('Invalid MCP server name: $name');
    }
    if (enabledTools != null && disabledTools != null) {
      throw ArgumentError(
          "enabledTools and disabledTools should be mutually exclusive.");
    }
  }

  static const fromMap = McpStreamableHttpServerMapper.fromMap;
  static const fromJson = McpStreamableHttpServerMapper.fromJson;
}
