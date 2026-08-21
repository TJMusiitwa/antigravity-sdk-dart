import 'dart:io';

import 'package:path/path.dart' as p;

import 'harness_downloader.dart';

/// Exception thrown when the pre-existing system binary is not found at any search path in the Google Antigravity SDK.
class AntigravityBinaryNotFoundException implements Exception {
  /// The descriptive error message.
  final String message;

  /// Creates a new [AntigravityBinaryNotFoundException] with the given [message].
  AntigravityBinaryNotFoundException(this.message);

  @override
  String toString() => 'AntigravityBinaryNotFoundException: $message';
}

/// A utility to search for the pre-existing system binary dynamically within the Google Antigravity SDK.
class BinaryDiscovery {
  /// Environment variable to check for the harness binary path.
  static const String harnessEnvVar = 'ANTIGRAVITY_HARNESS_PATH';

  /// Internal environment override for unit tests to ensure isolation.
  static Map<String, String>? environmentOverride;

  /// Binary names to search for.
  static const List<String> binaryNames = ['localharness'];

  /// Dynamically searches for the pre-existing system binary based on priorities.
  /// If not found and [autoDownload] is true, attempts to auto-download and install it from PyPI.
  ///
  /// Throws [AntigravityBinaryNotFoundException] if the binary cannot be found or downloaded.
  static Future<String> discover({
    String? configPath,
    bool autoDownload = true,
  }) async {
    final env = environmentOverride ?? Platform.environment;

    final fromConfig = _findFromConfigPath(configPath);
    if (fromConfig != null) return fromConfig;

    final fromEnv = _findFromEnvVar(env);
    if (fromEnv != null) return fromEnv;

    final fromPath = _findFromSystemPath(env);
    if (fromPath != null) return fromPath;

    final fromGlobal = _findFromGlobalInstall(env);
    if (fromGlobal != null) return fromGlobal;

    Object? downloadError;
    if (autoDownload) {
      try {
        return await HarnessDownloader.downloadAndInstall();
      } catch (e) {
        downloadError = e;
      }
    }

    _throwNotFoundException(autoDownload, downloadError);
  }

  static String? _findFromConfigPath(String? configPath) {
    if (configPath == null || configPath.isEmpty) return null;
    final file = File(configPath);
    return file.existsSync() ? file.absolute.path : null;
  }

  static String? _findFromEnvVar(Map<String, String> env) {
    final envPath = env[harnessEnvVar];
    if (envPath == null || envPath.isEmpty) return null;
    final file = File(envPath);
    return file.existsSync() ? file.absolute.path : null;
  }

  static String? _findFromSystemPath(Map<String, String> env) {
    final pathEnv = env['PATH'];
    if (pathEnv == null || pathEnv.isEmpty) return null;
    final separator = Platform.isWindows ? ';' : ':';
    final dirs = pathEnv.split(separator);
    for (final dir in dirs) {
      final trimmed = dir.trim();
      if (trimmed.isEmpty) continue;
      for (final binName in binaryNames) {
        final fullName = Platform.isWindows ? '$binName.exe' : binName;
        final file = File(p.join(trimmed, fullName));
        if (file.existsSync()) {
          return file.absolute.path;
        }
      }
    }
    return null;
  }

  static String? _findFromGlobalInstall(Map<String, String> env) {
    final homeDir = env['HOME'] ?? env['USERPROFILE'];
    if (homeDir == null || homeDir.isEmpty) return null;
    final globalBinDir = Directory(p.join(homeDir, '.antigravity', 'bin'));
    if (!globalBinDir.existsSync()) return null;

    for (final binName in binaryNames) {
      final fullName = Platform.isWindows ? '$binName.exe' : binName;
      final file = File(p.join(globalBinDir.path, fullName));
      if (file.existsSync() && _isCachedBinaryValid(globalBinDir)) {
        return file.absolute.path;
      }
    }
    return null;
  }

  static bool _isCachedBinaryValid(Directory globalBinDir) {
    final versionFile = File(p.join(globalBinDir.path, '.version'));
    if (!versionFile.existsSync()) return false;
    try {
      final cachedVersion = versionFile.readAsStringSync().trim();
      return !_isVersionOlder(cachedVersion, HarnessDownloader.defaultVersion);
    } catch (_) {
      return false;
    }
  }

  static Never _throwNotFoundException(bool autoDownload, Object? downloadError) {
    final sep = p.separator;
    throw AntigravityBinaryNotFoundException(
      'Could not find or automatically download the Google Antigravity binary.\n\n'
      'Priority paths checked:\n'
      '1. Explicit config path override (not provided or invalid)\n'
      '2. Environment variable: $harnessEnvVar (not set or invalid)\n'
      '3. Globally installed execution paths in system PATH\n'
      '4. Default global folder: ~$sep.antigravity${sep}bin$sep\n'
      '5. Auto-download from PyPI (status: ${autoDownload ? 'failed with: $downloadError' : 'disabled'})\n\n'
      'Please install the official Google Antigravity desktop/CLI environment before running this Dart package.\n'
      'For setup instructions, visit https://github.com/google-antigravity/antigravity-sdk-python or check your local distribution documentation.',
    );
  }

  static bool _isVersionOlder(String current, String target) {
    try {
      final curParts = current.split('.').map(int.parse).toList();
      final tarParts = target.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final curVal = i < curParts.length ? curParts[i] : 0;
        final tarVal = i < tarParts.length ? tarParts[i] : 0;
        if (curVal < tarVal) return true;
        if (curVal > tarVal) return false;
      }
    } catch (_) {
      return true;
    }
    return false;
  }
}
