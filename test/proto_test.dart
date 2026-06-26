import 'package:antigravity/src/connections/local/localharness_proto.dart';
import 'package:test/test.dart';

void main() {
  group('LocalHarnessProto – Varint Encoding', () {
    test('encodes 0 as a single zero byte', () {
      expect(LocalHarnessProto.encodeVarint(0), equals([0]));
    });

    test('encodes 1 correctly', () {
      expect(LocalHarnessProto.encodeVarint(1), equals([1]));
    });

    test('encodes 127 (max single-byte varint) correctly', () {
      expect(LocalHarnessProto.encodeVarint(127), equals([0x7F]));
    });

    test('encodes 128 (first two-byte varint) correctly', () {
      // 128 = 0b10000000 → [0x80, 0x01]
      expect(LocalHarnessProto.encodeVarint(128), equals([0x80, 0x01]));
    });

    test('encodes 300 correctly', () {
      // 300 = 0b100101100 → [0xAC, 0x02]
      expect(LocalHarnessProto.encodeVarint(300), equals([0xAC, 0x02]));
    });

    test('encodes 16383 (max two-byte varint) correctly', () {
      expect(LocalHarnessProto.encodeVarint(16383), equals([0xFF, 0x7F]));
    });

    test('encodes 16384 (first three-byte varint) correctly', () {
      expect(LocalHarnessProto.encodeVarint(16384), equals([0x80, 0x80, 0x01]));
    });

    test('encodes large value 2097151 correctly', () {
      expect(
        LocalHarnessProto.encodeVarint(2097151),
        equals([0xFF, 0xFF, 0x7F]),
      );
    });

    test('encodes 2097152 correctly', () {
      expect(
        LocalHarnessProto.encodeVarint(2097152),
        equals([0x80, 0x80, 0x80, 0x01]),
      );
    });

    test('encodes large port number 65535 correctly', () {
      final encoded = LocalHarnessProto.encodeVarint(65535);
      expect(encoded, isNotEmpty);
      // Verify round-trip
      final decoded = LocalHarnessProto.decodeVarint(encoded, [0]);
      expect(decoded, equals(65535));
    });
  });

  group('LocalHarnessProto – Varint Decoding', () {
    test('decodes single-byte value 0', () {
      expect(LocalHarnessProto.decodeVarint([0], [0]), equals(0));
    });

    test('decodes single-byte value 127', () {
      expect(LocalHarnessProto.decodeVarint([0x7F], [0]), equals(127));
    });

    test('decodes two-byte value 128', () {
      expect(LocalHarnessProto.decodeVarint([0x80, 0x01], [0]), equals(128));
    });

    test('decodes three-byte value 2097151', () {
      expect(
        LocalHarnessProto.decodeVarint([0xFF, 0xFF, 0x7F], [0]),
        equals(2097151),
      );
    });

    test('advances indexRef past the decoded bytes', () {
      final indexRef = [0];
      LocalHarnessProto.decodeVarint([0x80, 0x01, 0x05], indexRef);
      expect(indexRef[0], equals(2)); // consumed first 2 bytes
    });

    test('decodes starting from non-zero index', () {
      // [junk, 0x80, 0x01] → start at index 1 → 128
      final indexRef = [1];
      final result = LocalHarnessProto.decodeVarint([
        0xFF,
        0x80,
        0x01,
      ], indexRef);
      expect(result, equals(128));
      expect(indexRef[0], equals(3));
    });
  });

  group('LocalHarnessProto – Varint Round-trip', () {
    final testValues = [
      0,
      1,
      63,
      64,
      127,
      128,
      255,
      256,
      300,
      1000,
      16383,
      16384,
      65535,
      65536,
      2097151,
      2097152,
      134217727,
    ];

    for (final value in testValues) {
      test('round-trips $value', () {
        final encoded = LocalHarnessProto.encodeVarint(value);
        final decoded = LocalHarnessProto.decodeVarint(encoded, [0]);
        expect(decoded, equals(value));
      });
    }
  });

  group('LocalHarnessProto – encodeInputConfig', () {
    test('produces non-empty bytes for valid inputs', () {
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/tmp/storage',
        port: 8080,
        bindAddress: '127.0.0.1',
      );
      expect(bytes.isNotEmpty, isTrue);
    });

    test('encodes client_info as tag 4 (wire type 2)', () {
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/tmp/storage',
        port: 0,
        bindAddress: 'localhost',
        clientLanguage: 'dart',
        clientVersion: '0.2.2',
        clientLanguageVersion: '3.11.5',
      );
      // Tag 4 wire type 2 key: (4 << 3) | 2 = 34 = 0x22
      expect(bytes.contains(0x22), isTrue);
    });

    test('encodes storage_directory as tag 1 (wire type 2)', () {
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/data',
        port: 0,
        bindAddress: 'localhost',
      );
      // First byte should be tag 1, wire type 2 → (1 << 3) | 2 = 10 = 0x0A
      expect(bytes[0], equals(0x0A));
    });

    test('does not encode empty storage_directory', () {
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '',
        port: 0,
        bindAddress: 'localhost',
      );
      expect(bytes.isEmpty, isTrue);
    });

    test('does not encode port=0', () {
      final bytesWithPort = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/data',
        port: 9090,
      );
      final bytesWithoutPort = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/data',
        port: 0,
      );
      expect(bytesWithPort.length, greaterThan(bytesWithoutPort.length));
    });

    test('does not encode default localhost bind address', () {
      final bytesDefault = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/data',
        port: 0,
        bindAddress: 'localhost',
      );
      final bytesCustom = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/data',
        port: 0,
        bindAddress: '0.0.0.0',
      );
      expect(bytesCustom.length, greaterThan(bytesDefault.length));
    });

    test('encodes all three fields when all are provided and non-default', () {
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/tmp/agy',
        port: 4000,
        bindAddress: '0.0.0.0',
      );
      expect(bytes.isNotEmpty, isTrue);
    });

    test('storage_directory is UTF-8 encoded correctly', () {
      // Use an ASCII path and verify the encoded string bytes match
      const path = '/hello';
      final bytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: path,
        port: 0,
      );
      // bytes[0] = tag, bytes[1] = length, bytes[2..] = UTF-8 chars
      expect(bytes[0], equals(0x0A)); // tag 1, wire type 2
      expect(bytes[1], equals(path.length));
    });
  });

  group('LocalHarnessProto – decodeOutputConfig', () {
    List<int> buildOutputConfig({int port = 0, String apiKey = ''}) {
      final bytes = <int>[];
      if (port != 0) {
        // Tag 1, wire type 0
        bytes.addAll(LocalHarnessProto.encodeVarint(8));
        bytes.addAll(LocalHarnessProto.encodeVarint(port));
      }
      if (apiKey.isNotEmpty) {
        // Tag 2, wire type 2
        bytes.addAll(LocalHarnessProto.encodeVarint(18));
        final keyBytes = apiKey.codeUnits;
        bytes.addAll(LocalHarnessProto.encodeVarint(keyBytes.length));
        bytes.addAll(keyBytes);
      }
      return bytes;
    }

    test('decodes port field correctly', () {
      final bytes = buildOutputConfig(port: 9090);
      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.port, equals(9090));
    });

    test('decodes api_key field correctly', () {
      final bytes = buildOutputConfig(apiKey: 'sk-abc123');
      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.apiKey, equals('sk-abc123'));
    });

    test('decodes both port and api_key', () {
      final bytes = buildOutputConfig(port: 7777, apiKey: 'test_api_key_123');
      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.port, equals(7777));
      expect(result.apiKey, equals('test_api_key_123'));
    });

    test('returns defaults for empty input', () {
      final result = LocalHarnessProto.decodeOutputConfig([]);
      expect(result.port, equals(0));
      expect(result.apiKey, equals(''));
    });

    test('handles large port numbers', () {
      final bytes = buildOutputConfig(port: 65535);
      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.port, equals(65535));
    });

    test('handles long api_key string', () {
      final longKey = 'a' * 255;
      final bytes = buildOutputConfig(apiKey: longKey);
      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.apiKey, equals(longKey));
    });

    test('skips unknown wire type 0 fields gracefully', () {
      final bytes = <int>[];
      // Unknown tag 5, wire type 0
      bytes.addAll(LocalHarnessProto.encodeVarint((5 << 3) | 0));
      bytes.addAll(LocalHarnessProto.encodeVarint(42));
      // Then known api_key
      bytes.addAll(LocalHarnessProto.encodeVarint(18));
      final keyBytes = 'mykey'.codeUnits;
      bytes.addAll(LocalHarnessProto.encodeVarint(keyBytes.length));
      bytes.addAll(keyBytes);

      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.apiKey, equals('mykey'));
    });

    test('skips unknown wire type 2 fields gracefully', () {
      final bytes = <int>[];
      // Unknown tag 9, wire type 2
      bytes.addAll(LocalHarnessProto.encodeVarint((9 << 3) | 2));
      final junk = 'junk_data'.codeUnits;
      bytes.addAll(LocalHarnessProto.encodeVarint(junk.length));
      bytes.addAll(junk);
      // Known port field
      bytes.addAll(LocalHarnessProto.encodeVarint(8));
      bytes.addAll(LocalHarnessProto.encodeVarint(1234));

      final result = LocalHarnessProto.decodeOutputConfig(bytes);
      expect(result.port, equals(1234));
    });

    test('throws FormatException on truncated api_key string', () {
      final bytes = <int>[];
      // Tag 2, wire type 2
      bytes.addAll(LocalHarnessProto.encodeVarint(18));
      bytes.addAll(LocalHarnessProto.encodeVarint(100)); // claim 100 bytes
      bytes.addAll('short'.codeUnits); // only 5 bytes

      expect(
        () => LocalHarnessProto.decodeOutputConfig(bytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException on unsupported wire type', () {
      final bytes = <int>[];
      // Tag 3, wire type 3 (unsupported group)
      bytes.addAll(LocalHarnessProto.encodeVarint((3 << 3) | 3));

      expect(
        () => LocalHarnessProto.decodeOutputConfig(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('LocalHarnessProto – packMessage', () {
    test('packs empty payload with 4-byte zero header', () {
      final packed = LocalHarnessProto.packMessage([]);
      expect(packed.length, equals(4));
      expect(packed[0], equals(0));
      expect(packed[1], equals(0));
      expect(packed[2], equals(0));
      expect(packed[3], equals(0));
    });

    test('packs single-byte payload correctly', () {
      final packed = LocalHarnessProto.packMessage([0xAB]);
      expect(packed.length, equals(5));
      expect(packed[0], equals(1)); // length = 1 little-endian
      expect(packed[1], equals(0));
      expect(packed[4], equals(0xAB));
    });

    test('packs 4-byte payload with correct little-endian length', () {
      final payload = [1, 2, 3, 4];
      final packed = LocalHarnessProto.packMessage(payload);
      expect(packed.length, equals(8));
      expect(packed[0], equals(4)); // low byte of length
      expect(packed[1], equals(0));
      expect(packed[2], equals(0));
      expect(packed[3], equals(0));
      expect(packed.sublist(4), equals(payload));
    });

    test('packs 256-byte payload with correct little-endian length', () {
      final payload = List<int>.generate(256, (i) => i % 256);
      final packed = LocalHarnessProto.packMessage(payload);
      expect(packed.length, equals(260));
      expect(packed[0], equals(0x00)); // 256 = 0x100 → low byte 0x00
      expect(packed[1], equals(0x01)); // high byte
    });

    test('payload data is preserved exactly after packing', () {
      final payload = [10, 20, 30, 40, 50];
      final packed = LocalHarnessProto.packMessage(payload);
      expect(packed.sublist(4), equals(payload));
    });
  });
}
