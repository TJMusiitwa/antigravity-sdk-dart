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

    // 1. Check an explicit user-provided config path override first
    if (configPath != null && configPath.isNotEmpty) {
      final file = File(configPath);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }

    // 2. Check the system environment variable override
    final envPath = env[harnessEnvVar];
    if (envPath != null && envPath.isNotEmpty) {
      final file = File(envPath);
      if (file.existsSync()) {
        return file.absolute.path;
      }
    }

    // 3. Scan the user's system environment variable PATH for globally installed paths
    final pathEnv = env['PATH'];
    if (pathEnv != null && pathEnv.isNotEmpty) {
      final separator = Platform.isWindows ? ';' : ':';
      final dirs = pathEnv.split(separator);
      for (final dir in dirs) {
        if (dir.trim().isEmpty) continue;
        for (final binName in binaryNames) {
          final fullName = Platform.isWindows ? '$binName.exe' : binName;
          final file = File(p.join(dir.trim(), fullName));
          if (file.existsSync()) {
            return file.absolute.path;
          }
        }
      }
    }

    // 4. Check default global install folders (e.g. ~/.antigravity/bin/ across macOS, Linux, and Windows)
    final homeDir = env['HOME'] ?? env['USERPROFILE'];
    if (homeDir != null && homeDir.isNotEmpty) {
      final globalBinDir = Directory(p.join(homeDir, '.antigravity', 'bin'));
      if (globalBinDir.existsSync()) {
        for (final binName in binaryNames) {
          final fullName = Platform.isWindows ? '$binName.exe' : binName;
          final file = File(p.join(globalBinDir.path, fullName));
          if (file.existsSync()) {
            return file.absolute.path;
          }
        }
      }
    }

    // 5. Fallback: Try to automatically download the official precompiled binary
    Object? downloadError;
    if (autoDownload) {
      try {
        final downloadedPath = await HarnessDownloader.downloadAndInstall();
        return downloadedPath;
      } catch (e) {
        downloadError = e;
      }
    }

    // 6. Graceful Failure: Throw a descriptive exception with setup instructions
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
}
