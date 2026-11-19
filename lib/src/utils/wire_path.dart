import 'dart:io';

import 'package:path/path.dart' as p;

/// Converts wire URIs and collapses lexical dot segments in filesystem paths.
String normalizeWirePath(String path) {
  if (path.isEmpty) return path;
  if (Platform.isWindows && RegExp(r'^[a-zA-Z]:').hasMatch(path)) {
    return p.normalize(path);
  }

  final uri = Uri.tryParse(path);
  if (uri == null || !uri.hasScheme) return p.normalize(path);
  if (uri.scheme == 'file') {
    // Like Python's url2pathname, use the URI path for POSIX file URIs.
    final filePath = Platform.isWindows
        ? p.fromUri(path.split(RegExp(r'[?#]')).first)
        : Uri.decodeComponent(uri.path);
    return filePath.isEmpty ? '.' : p.normalize(filePath);
  }
  if (uri.scheme == 'cns') {
    // Treat the cell and path as one rooted POSIX path, including encoded dots.
    // Uri removes dot segments from `path` before the cell can participate,
    // so take the wire path and authority together from the original string.
    final subpath = path
        .substring(path.indexOf(':') + 1)
        .split(RegExp(r'[?#]'))
        .first;
    final rooted = p.posix.normalize('/${Uri.decodeComponent(subpath)}');
    return rooted == '/' ? '/cns' : '/cns$rooted';
  }
  return path;
}
