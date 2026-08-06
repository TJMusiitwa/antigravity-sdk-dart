/// Base connection exception for Google Antigravity SDK.
class AntigravityConnectionException implements Exception {
  final String message;
  AntigravityConnectionException(this.message);

  @override
  String toString() => 'AntigravityConnectionException: $message';
}

/// Validation exception at the SDK boundary.
class AntigravityValidationException implements Exception, ArgumentError {
  @override
  final String message;
  @override
  final dynamic invalidValue;
  @override
  final String? name;

  AntigravityValidationException(this.message, {this.invalidValue, this.name});

  @override
  StackTrace? get stackTrace => null;

  @override
  String toString() => 'AntigravityValidationException: $message';
}

/// Exception thrown when an active turn is cancelled programmatically.
class AntigravityCancelledException implements Exception {
  final String message;
  AntigravityCancelledException([
    this.message = 'The request was cancelled by the client.',
  ]);

  @override
  String toString() => 'AntigravityCancelledException: $message';
}

/// Exception thrown when the agent execution encounters a terminal error.
class AntigravityExecutionException implements Exception {
  final String message;
  AntigravityExecutionException(this.message);

  @override
  String toString() => 'AntigravityExecutionException: $message';
}

/// Exception thrown when a tool execution fails, carrying tool metadata.
class ToolExecutionException implements Exception {
  /// The error message returned by the failed tool execution.
  final String message;

  /// The name of the tool that encountered the error.
  final String toolName;

  /// The optional name of the Model Context Protocol (MCP) server if the tool belonged to an MCP server.
  final String? serverName;

  /// The optional tool call correlation ID.
  final String? callId;

  ToolExecutionException(
    this.message, {
    this.toolName = '',
    this.serverName,
    this.callId,
  });

  @override
  String toString() =>
      'ToolExecutionException: $message (tool: $toolName${serverName != null ? ', server: $serverName' : ''}${callId != null ? ', callId: $callId' : ''})';
}
