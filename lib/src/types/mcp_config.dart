import 'package:dart_mappable/dart_mappable.dart';

import 'exceptions.dart';

part 'mcp_config.mapper.dart';

/// Abstract base for all MCP server configurations.
@MappableClass(discriminatorKey: 'type')
abstract class McpServerConfig with McpServerConfigMappable {
  /// Unique identifier for the MCP server.
  ///
  /// Must match `^[a-zA-Z0-9_-]+$` (letters, digits, hyphens, and
  /// underscores), in line with Gemini API tool naming rules.
  final String name;

  /// Timeout in seconds for connecting to the server and listing tools.
  ///
  /// Null when no timeout is configured.
  final int? timeoutSeconds;

  /// Explicit allowlist of server tools to enable.
  ///
  /// Mutually exclusive with [disabledTools]. When both are null, all tools
  /// from the server are enabled. Tools not enabled are hidden from the
  /// model's context.
  final List<String>? enabledTools;

  /// Explicit denylist of server tools to disable.
  ///
  /// Mutually exclusive with [enabledTools]. When both are null, all tools
  /// from the server are enabled. Disabled tools are removed from the model's
  /// context.
  final List<String>? disabledTools;

  /// Loads all server tools into the prompt instead of discovering them lazily.
  final bool forceAllToolsEager;

  /// Returns the configured timeout as a strongly-typed Dart [Duration].
  Duration? get serverTimeout =>
      timeoutSeconds != null ? Duration(seconds: timeoutSeconds!) : null;

  /// Creates an [McpServerConfig].
  ///
  /// Pass the timeout as either [timeoutSeconds] or [serverTimeout];
  /// [timeoutSeconds] takes precedence when both are set.
  ///
  /// Throws an [AntigravityValidationException] if both [enabledTools] and
  /// [disabledTools] are set, or if [name] does not match the allowed pattern.
  McpServerConfig({
    required this.name,
    int? timeoutSeconds,
    Duration? serverTimeout,
    this.enabledTools,
    this.disabledTools,
    this.forceAllToolsEager = false,
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

  /// Connection type discriminator: `stdio` or `http`.
  String get type;

  /// Decodes an [McpServerConfig] from a map.
  static const fromMap = McpServerConfigMapper.fromMap;

  /// Decodes an [McpServerConfig] from a JSON string.
  static const fromJson = McpServerConfigMapper.fromJson;
}

/// Configuration for an MCP server connected via stdio.
@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  discriminatorValue: 'stdio',
  ignoreNull: true,
)
class McpStdioServer extends McpServerConfig with McpStdioServerMappable {
  /// Command to run to start the server.
  final String command;

  /// Arguments to pass to [command]. Defaults to an empty list.
  final List<String> args;

  /// Environment variables to merge into the spawned subprocess's
  /// environment.
  final Map<String, String>? env;

  @override
  String get type => 'stdio';

  /// Creates an [McpStdioServer] that runs [command] with [args].
  McpStdioServer({
    required super.name,
    required this.command,
    List<String>? args,
    this.env,
    super.timeoutSeconds,
    super.serverTimeout,
    super.enabledTools,
    super.disabledTools,
    super.forceAllToolsEager,
  }) : args = args ?? [];

  /// Decodes an [McpStdioServer] from a map.
  static const fromMap = McpStdioServerMapper.fromMap;

  /// Decodes an [McpStdioServer] from a JSON string.
  static const fromJson = McpStdioServerMapper.fromJson;
}

/// Configuration for an MCP server connected via Streamable HTTP.
@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  discriminatorValue: 'http',
  ignoreNull: true,
)
class McpStreamableHttpServer extends McpServerConfig
    with McpStreamableHttpServerMappable {
  /// URL of the HTTP endpoint.
  final String url;

  /// Optional headers to send with the connection request.
  final Map<String, String>? headers;

  /// Connection timeout in seconds. Defaults to 30.
  final double timeout;

  /// Server-sent events (SSE) read timeout in seconds. Defaults to 300.
  final double sseReadTimeout;

  /// Whether to terminate the connection on close. Defaults to true.
  final bool terminateOnClose;

  /// Returns the target URL as a strongly-typed Dart [Uri].
  Uri get uri => Uri.parse(url);

  @override
  String get type => 'http';

  /// Creates an [McpStreamableHttpServer] for the endpoint at [url].
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
    super.forceAllToolsEager,
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
    bool forceAllToolsEager = false,
  }) => McpStreamableHttpServer(
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
    forceAllToolsEager: forceAllToolsEager,
  );

  /// Decodes an [McpStreamableHttpServer] from a map.
  static const fromMap = McpStreamableHttpServerMapper.fromMap;

  /// Decodes an [McpStreamableHttpServer] from a JSON string.
  static const fromJson = McpStreamableHttpServerMapper.fromJson;
}
