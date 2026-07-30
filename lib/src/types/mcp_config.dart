import 'package:dart_mappable/dart_mappable.dart';
import 'exceptions.dart';

part 'mcp_config.mapper.dart';

/// Abstract base for all MCP server configurations.
@MappableClass(discriminatorKey: 'type')
abstract class McpServerConfig with McpServerConfigMappable {
  final String name;
  final int? timeoutSeconds;
  final List<String>? enabledTools;
  final List<String>? disabledTools;

  /// Returns the configured timeout as a strongly-typed Dart [Duration].
  Duration? get serverTimeout =>
      timeoutSeconds != null ? Duration(seconds: timeoutSeconds!) : null;

  McpServerConfig({
    required this.name,
    int? timeoutSeconds,
    Duration? serverTimeout,
    this.enabledTools,
    this.disabledTools,
  }) : timeoutSeconds = timeoutSeconds ?? serverTimeout?.inSeconds {
    if (enabledTools != null && disabledTools != null) {
      throw AntigravityValidationException(
        'enabledTools and disabledTools should be mutually exclusive.',
      );
    }
    final regex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!regex.hasMatch(name)) {
      throw AntigravityValidationException(
        'name must match pattern ^[a-zA-Z0-9_-]+\$',
      );
    }
  }

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
  final Map<String, String>? env;

  @override
  String get type => 'stdio';

  McpStdioServer({
    required super.name,
    required this.command,
    List<String>? args,
    this.env,
    super.timeoutSeconds,
    super.serverTimeout,
    super.enabledTools,
    super.disabledTools,
  }) : args = args ?? [];

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

  /// Returns the target URL as a strongly-typed Dart [Uri].
  Uri get uri => Uri.parse(url);

  @override
  String get type => 'http';

  McpStreamableHttpServer({
    required super.name,
    required this.url,
    this.headers,
    this.timeout = 30.0,
    this.sseReadTimeout = 300.0,
    this.terminateOnClose = true,
    super.timeoutSeconds,
    super.serverTimeout,
    super.enabledTools,
    super.disabledTools,
  });

  /// Factory constructor creating an [McpStreamableHttpServer] from a strongly-typed Dart [Uri].
  factory McpStreamableHttpServer.fromUri({
    required String name,
    required Uri uri,
    Map<String, String>? headers,
    double timeout = 30.0,
    double sseReadTimeout = 300.0,
    bool terminateOnClose = true,
    int? timeoutSeconds,
    Duration? serverTimeout,
    List<String>? enabledTools,
    List<String>? disabledTools,
  }) =>
      McpStreamableHttpServer(
        name: name,
        url: uri.toString(),
        headers: headers,
        timeout: timeout,
        sseReadTimeout: sseReadTimeout,
        terminateOnClose: terminateOnClose,
        timeoutSeconds: timeoutSeconds,
        serverTimeout: serverTimeout,
        enabledTools: enabledTools,
        disabledTools: disabledTools,
      );

  static const fromMap = McpStreamableHttpServerMapper.fromMap;
  static const fromJson = McpStreamableHttpServerMapper.fromJson;
}
