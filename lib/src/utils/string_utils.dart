/// Converts a camelCase string to snake_case.
String toSnakeCase(String camel) {
  final exp = RegExp(r'(?<=[a-z0-9])[A-Z]');
  return camel.replaceAllMapped(exp, (m) => '_${m.group(0)}').toLowerCase();
}
