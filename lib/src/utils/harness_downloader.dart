import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

/// A utility to dynamically download the official precompiled `localharness`
/// binary from PyPI wheels matching the host CPU architecture and OS.
class HarnessDownloader {
  static final Logger _logger = Logger('HarnessDownloader');

  /// Fallback version of google-antigravity to query if PyPI's latest resolution fails.
  static const String defaultVersion = '0.1.13';

  /// Detects the current CPU architecture.
  static Future<String> getProcessorArchitecture() async {
    if (Platform.isWindows) {
      final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? 'AMD64';
      if (arch.toUpperCase().contains('ARM')) return 'arm64';
      return 'x64';
    } else {
      try {
        final result = await Process.run('uname', ['-m']);
        final output = result.stdout.toString().trim().toLowerCase();
        if (output.contains('arm') || output.contains('aarch64')) {
          return 'arm64';
        }
        return 'x64';
      } catch (_) {
        final version = Platform.version.toLowerCase();
        if (version.contains('arm64') || version.contains('aarch64')) {
          return 'arm64';
        }
        return 'x64';
      }
    }
  }

  /// Resolves the PyPI wheel platform name matching the host environment.
  static Future<String?> getWheelPlatformTag() async {
    final arch = await getProcessorArchitecture();
    if (Platform.isMacOS) {
      if (arch == 'arm64') return 'macosx_11_0_arm64';
      // Note: Google currently does not publish an Intel mac x64 wheel for google-antigravity.
      _logger.warning(
        'macOS Intel (x64) is currently not supported for auto-download.',
      );
      return null;
    } else if (Platform.isLinux) {
      if (arch == 'arm64') return 'manylinux_2_17_aarch64';
      return 'manylinux_2_17_x86_64';
    } else if (Platform.isWindows) {
      if (arch == 'arm64') return 'win_arm64';
      return 'win_amd64';
    }
    return null;
  }

  /// Downloads the correct `localharness` binary for the host system and installs it.
  ///
  /// Returns the absolute path of the installed binary if successful.
  static Future<String> downloadAndInstall() async {
    final tag = await getWheelPlatformTag();
    if (tag == null) {
      throw UnsupportedError(
        'Auto-download is not supported on the current platform (${Platform.operatingSystem}). '
        'Please install the official Google Antigravity CLI environment manually.',
      );
    }

    _logger.info('Resolving latest google-antigravity release metadata from PyPI...');
    final resolved = await _resolveWheelUrl(tag);

    _logger.info('Downloading localharness v${resolved.version} wheel from ${resolved.url}...');
    final tempDir = await Directory.systemTemp.createTemp('antigravity_download_');
    final tempWhlFile = File(p.join(tempDir.path, 'temp.whl'));

    try {
      await _downloadWheelFile(resolved.url, tempWhlFile);
      return await _extractAndInstallBinary(tempWhlFile, resolved.version);
    } finally {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  static Future<({String url, String version})> _resolveWheelUrl(String tag) async {
    String? whlUrl;
    String version = defaultVersion;

    try {
      final response = await http.get(Uri.parse('https://pypi.org/pypi/google-antigravity/json'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final info = json['info'] as Map<String, dynamic>;
        version = info['version'] as String;
        whlUrl = _findMatchingWheelUrl(json['urls'] as List<dynamic>, tag);
      }
    } catch (e) {
      _logger.warning('Failed to query latest PyPI metadata: $e. Falling back to default version $defaultVersion.');
    }

    if (whlUrl == null) {
      try {
        final response = await http.get(Uri.parse('https://pypi.org/pypi/google-antigravity/$version/json'));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          whlUrl = _findMatchingWheelUrl(json['urls'] as List<dynamic>, tag);
        }
      } catch (e) {
        _logger.warning('Failed to query PyPI version $version metadata: $e');
      }
    }

    if (whlUrl == null) {
      throw StateError(
        'Could not find a valid wheel download URL for platform tag "$tag" on PyPI for google-antigravity v$version.',
      );
    }

    return (url: whlUrl, version: version);
  }

  static String? _findMatchingWheelUrl(List<dynamic> urls, String tag) {
    for (final u in urls) {
      final filename = u['filename'] as String;
      if (filename.contains(tag) && filename.endsWith('.whl')) {
        return u['url'] as String;
      }
    }
    return null;
  }

  static Future<void> _downloadWheelFile(String url, File targetFile) async {
    final bytesResponse = await http.get(Uri.parse(url));
    if (bytesResponse.statusCode != 200) {
      throw HttpException(
        'Failed to download wheel: ${bytesResponse.reasonPhrase} (${bytesResponse.statusCode})',
      );
    }
    await targetFile.writeAsBytes(bytesResponse.bodyBytes);
  }

  static Future<String> _extractAndInstallBinary(File tempWhlFile, String version) async {
    final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final installDir = Directory(p.join(homeDir, '.antigravity', 'bin'));
    final binaryName = Platform.isWindows ? 'localharness.exe' : 'localharness';
    final targetBinaryFile = File(p.join(installDir.path, binaryName));

    _logger.info('Extracting localharness binary to ${targetBinaryFile.path}...');

    final extractTempDir = await Directory.systemTemp.createTemp('antigravity_extract_');
    try {
      final internalPath = Platform.isWindows
          ? 'google/antigravity/bin/localharness.exe'
          : 'google/antigravity/bin/localharness';

      await _runExtractCommand(tempWhlFile.path, extractTempDir.path, internalPath);

      final sourceFile = File(p.join(extractTempDir.path, p.fromUri(internalPath)));
      if (!sourceFile.existsSync()) {
        throw FileSystemException('Extracted localharness binary not found at expected location.');
      }

      if (!installDir.existsSync()) {
        installDir.createSync(recursive: true);
      }
      await sourceFile.copy(targetBinaryFile.path);

      _writeVersionFile(installDir, version);
      await _ensureExecutable(targetBinaryFile.path);

      _logger.info('Successfully installed localharness v$version to ${targetBinaryFile.path}');
      return targetBinaryFile.absolute.path;
    } finally {
      if (extractTempDir.existsSync()) {
        extractTempDir.deleteSync(recursive: true);
      }
    }
  }

  static Future<void> _runExtractCommand(
    String zipPath,
    String destDir,
    String internalPath,
  ) async {
    final result = Platform.isWindows
        ? await Process.run('tar', ['-xf', zipPath, '-C', destDir, internalPath])
        : await Process.run('unzip', ['-o', '-q', zipPath, internalPath, '-d', destDir]);

    if (result.exitCode != 0) {
      throw ProcessException(
        Platform.isWindows ? 'tar' : 'unzip',
        Platform.isWindows ? ['-xf', '...'] : ['-o', '-q', '...'],
        'Extraction failed: ${result.stderr}',
        result.exitCode,
      );
    }
  }

  static void _writeVersionFile(Directory installDir, String version) {
    try {
      final versionFile = File(p.join(installDir.path, '.version'));
      versionFile.writeAsStringSync(version);
    } catch (e) {
      _logger.warning('Failed to write .version metadata file: $e');
    }
  }

  static Future<void> _ensureExecutable(String binaryPath) async {
    if (Platform.isWindows) return;
    final chmodResult = await Process.run('chmod', ['+x', binaryPath]);
    if (chmodResult.exitCode != 0) {
      _logger.warning('Failed to set executable flag on binary: ${chmodResult.stderr}');
    }
  }
}
