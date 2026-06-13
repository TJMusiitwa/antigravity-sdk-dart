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
