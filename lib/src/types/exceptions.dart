/// Base connection exception for Google Antigravity SDK.
class AntigravityConnectionException implements Exception {
  final String message;
  AntigravityConnectionException(this.message);

  @override
  String toString() => 'AntigravityConnectionException: $message';
}

/// Validation exception at the SDK boundary.
class AntigravityValidationException implements Exception {
  final String message;
  AntigravityValidationException(this.message);

  @override
  String toString() => 'AntigravityValidationException: $message';
}

/// Raised when an active turn is cancelled programmatically.
class AntigravityCancelledError implements Exception {
  final String message;
  AntigravityCancelledError(
      [this.message = "The request was cancelled by the client."]);

  @override
  String toString() => 'AntigravityCancelledError: $message';
}

/// Raised when the agent execution encounters a terminal error.
class AntigravityExecutionError implements Exception {
  final String message;
  AntigravityExecutionError(this.message);

  @override
  String toString() => 'AntigravityExecutionError: $message';
}
