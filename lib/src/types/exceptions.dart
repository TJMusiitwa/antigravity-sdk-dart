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
