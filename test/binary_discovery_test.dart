import 'dart:io';
import 'package:test/test.dart';
import 'package:antigravity/src/utils/binary_discovery.dart';

void main() {
  setUp(() {
    BinaryDiscovery.environmentOverride = {
      'HOME': '/nonexistent-home',
      'USERPROFILE': '/nonexistent-userprofile',
      'PATH': '',
    };
  });

  tearDown(() {
    BinaryDiscovery.environmentOverride = null;
  });

  group('BinaryDiscovery – configPath override', () {
    late File tempFile;

    setUp(() {
      tempFile = File('${Directory.systemTemp.path}/test_agy_binary');
    });

    tearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('returns absolute path for existing configPath file', () async {
      tempFile.writeAsStringSync('binary_content');
      final result = await BinaryDiscovery.discover(
        configPath: tempFile.path,
        autoDownload: false,
      );
      expect(result, equals(tempFile.absolute.path));
    });

    test('throws when configPath file does not exist', () async {
      expect(
        BinaryDiscovery.discover(
          configPath: '/definitely/does/not/exist/binary',
          autoDownload: false,
        ),
        throwsA(isA<AntigravityBinaryNotFoundException>()),
      );
    });

    test('throws when configPath is an empty string', () async {
      expect(
        BinaryDiscovery.discover(configPath: '', autoDownload: false),
        throwsA(isA<AntigravityBinaryNotFoundException>()),
      );
    });

    test('exception message contains helpful instructions', () async {
      try {
        await BinaryDiscovery.discover(
          configPath: '/no/such/binary',
          autoDownload: false,
        );
        fail('Should have thrown');
      } on AntigravityBinaryNotFoundException catch (e) {
        expect(e.message, contains('Could not find'));
        expect(e.message, contains(BinaryDiscovery.harnessEnvVar));
      }
    });

    test('exception toString starts with class name prefix', () async {
      try {
        await BinaryDiscovery.discover(
          configPath: '/no/such/binary',
          autoDownload: false,
        );
        fail('Should have thrown');
      } on AntigravityBinaryNotFoundException catch (e) {
        expect(e.toString(), startsWith('AntigravityBinaryNotFoundException:'));
      }
    });

    test('returns path when a different named temp file is used', () async {
      final uniqueFile = File(
        '${Directory.systemTemp.path}/unique_agy_${DateTime.now().millisecondsSinceEpoch}',
      );
      uniqueFile.writeAsStringSync('binary');
      try {
        final result = await BinaryDiscovery.discover(
          configPath: uniqueFile.path,
          autoDownload: false,
        );
        expect(result, equals(uniqueFile.absolute.path));
      } finally {
        if (uniqueFile.existsSync()) uniqueFile.deleteSync();
      }
    });
  });

  group('BinaryDiscovery – constants', () {
    test('harnessEnvVar is ANTIGRAVITY_HARNESS_PATH', () {
      expect(BinaryDiscovery.harnessEnvVar, equals('ANTIGRAVITY_HARNESS_PATH'));
    });

    test('binaryNames contains expected values', () {
      expect(BinaryDiscovery.binaryNames, contains('antigravity-cli'));
      expect(BinaryDiscovery.binaryNames, contains('agy'));
      expect(BinaryDiscovery.binaryNames, contains('localharness'));
    });

    test('binaryNames is a non-empty list', () {
      expect(BinaryDiscovery.binaryNames, isNotEmpty);
    });
  });

  group('BinaryDiscovery – no binary found', () {
    test(
      'throws AntigravityBinaryNotFoundException when nothing is found',
      () async {
        expect(
          BinaryDiscovery.discover(
            configPath: '/nonexistent/path/to/harness_xyz',
            autoDownload: false,
          ),
          throwsA(isA<AntigravityBinaryNotFoundException>()),
        );
      },
    );

    test('exception is catchable as Exception', () async {
      expect(
        BinaryDiscovery.discover(configPath: '/not/there', autoDownload: false),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('AntigravityBinaryNotFoundException', () {
    test('stores and exposes message correctly', () {
      const msg = 'test error message';
      final ex = AntigravityBinaryNotFoundException(msg);
      expect(ex.message, equals(msg));
    });

    test('toString includes the class name and message', () {
      final ex = AntigravityBinaryNotFoundException('oops');
      expect(ex.toString(), contains('AntigravityBinaryNotFoundException'));
      expect(ex.toString(), contains('oops'));
    });

    test('implements Exception', () {
      final ex = AntigravityBinaryNotFoundException('err');
      expect(ex, isA<Exception>());
    });
  });
}
