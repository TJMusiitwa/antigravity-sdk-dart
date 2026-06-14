import 'dart:convert';
import 'dart:typed_data';

/// Encodes and decodes the custom Protocol Buffer messages used in the standard input/output handshake.
class LocalHarnessProto {
  /// The TCP port used by the localharness WebSocket server.
  final int port;

  /// The dynamic API key associated with the localharness backend session.
  final String apiKey;

  /// Creates a new [LocalHarnessProto] instance.
  LocalHarnessProto({required this.port, required this.apiKey});

  /// Encodes a 32-bit unsigned integer as a Protobuf Varint.
  static List<int> encodeVarint(int value) {
    final List<int> result = [];
    while (value >= 0x80) {
      result.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    result.add(value & 0x7F);
    return result;
  }

  /// Decodes a Protobuf Varint from [bytes] at [indexRef].
  /// Increments the index inside [indexRef].
  static int decodeVarint(List<int> bytes, List<int> indexRef) {
    int result = 0;
    int shift = 0;
    int index = indexRef[0];
    while (index < bytes.length) {
      final byte = bytes[index++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        break;
      }
      shift += 7;
    }
    indexRef[0] = index;
    return result;
  }

  /// Encodes the `InputConfig` message as a Protobuf binary payload.
  ///
  /// `InputConfig` fields:
  /// - `storage_directory` (string, tag 1)
  /// - `port` (uint32, tag 2)
  /// - `bind_address` (string, tag 3, default "localhost")
  static Uint8List encodeInputConfig({
    required String storageDirectory,
    int port = 0,
    String bindAddress = 'localhost',
    String? clientLanguage,
    String? clientVersion,
    String? clientLanguageVersion,
  }) {
    final List<int> bytes = [];

    // Tag 1: storage_directory (string, wire type 2)
    if (storageDirectory.isNotEmpty) {
      bytes.addAll(encodeVarint((1 << 3) | 2));
      final strBytes = utf8.encode(storageDirectory);
      bytes.addAll(encodeVarint(strBytes.length));
      bytes.addAll(strBytes);
    }

    // Tag 2: port (uint32, wire type 0)
    if (port != 0) {
      bytes.addAll(encodeVarint((2 << 3) | 0));
      bytes.addAll(encodeVarint(port));
    }

    // Tag 3: bind_address (string, wire type 2)
    if (bindAddress.isNotEmpty && bindAddress != 'localhost') {
      bytes.addAll(encodeVarint((3 << 3) | 2));
      final strBytes = utf8.encode(bindAddress);
      bytes.addAll(encodeVarint(strBytes.length));
      bytes.addAll(strBytes);
    }

    // Tag 4: client_info (ClientInfo message, wire type 2)
    if (clientLanguage != null ||
        clientVersion != null ||
        clientLanguageVersion != null) {
      final List<int> clientInfoBytes = [];
      if (clientLanguage != null && clientLanguage.isNotEmpty) {
        clientInfoBytes.addAll(encodeVarint((1 << 3) | 2));
        final strBytes = utf8.encode(clientLanguage);
        clientInfoBytes.addAll(encodeVarint(strBytes.length));
        clientInfoBytes.addAll(strBytes);
      }
      if (clientVersion != null && clientVersion.isNotEmpty) {
        clientInfoBytes.addAll(encodeVarint((2 << 3) | 2));
        final strBytes = utf8.encode(clientVersion);
        clientInfoBytes.addAll(encodeVarint(strBytes.length));
        clientInfoBytes.addAll(strBytes);
      }
      if (clientLanguageVersion != null && clientLanguageVersion.isNotEmpty) {
        clientInfoBytes.addAll(encodeVarint((3 << 3) | 2));
        final strBytes = utf8.encode(clientLanguageVersion);
        clientInfoBytes.addAll(encodeVarint(strBytes.length));
        clientInfoBytes.addAll(strBytes);
      }
      if (clientInfoBytes.isNotEmpty) {
        bytes.addAll(encodeVarint((4 << 3) | 2));
        bytes.addAll(encodeVarint(clientInfoBytes.length));
        bytes.addAll(clientInfoBytes);
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Decodes the `OutputConfig` message from a Protobuf binary payload.
  ///
  /// `OutputConfig` fields:
  /// - `port` (int32, tag 1, wire type 0)
  /// - `api_key` (string, tag 2, wire type 2)
  static LocalHarnessProto decodeOutputConfig(List<int> bytes) {
    int port = 0;
    String apiKey = '';

    final indexRef = [0];
    while (indexRef[0] < bytes.length) {
      final key = decodeVarint(bytes, indexRef);
      final tag = key >> 3;
      final wireType = key & 0x07;

      if (tag == 1 && wireType == 0) {
        port = decodeVarint(bytes, indexRef);
      } else if (tag == 2 && wireType == 2) {
        final len = decodeVarint(bytes, indexRef);
        final idx = indexRef[0];
        if (idx + len > bytes.length) {
          throw FormatException('Truncated string field in OutputConfig');
        }
        final strBytes = bytes.sublist(idx, idx + len);
        apiKey = utf8.decode(strBytes);
        indexRef[0] = idx + len;
      } else {
        // Skip unknown fields
        if (wireType == 0) {
          decodeVarint(bytes, indexRef);
        } else if (wireType == 2) {
          final len = decodeVarint(bytes, indexRef);
          indexRef[0] = indexRef[0] + len;
        } else if (wireType == 1) {
          indexRef[0] = indexRef[0] + 8; // 64-bit
        } else if (wireType == 5) {
          indexRef[0] = indexRef[0] + 4; // 32-bit
        } else {
          throw FormatException('Unsupported wire type: $wireType');
        }
      }
    }

    return LocalHarnessProto(port: port, apiKey: apiKey);
  }

  /// Packs a message payload with a 4-byte little-endian length prefix.
  static Uint8List packMessage(List<int> payload) {
    final length = payload.length;
    final header = ByteData(4)..setUint32(0, length, Endian.little);
    final packed = Uint8List(4 + length);
    packed.setRange(0, 4, header.buffer.asUint8List());
    packed.setRange(4, 4 + length, payload);
    return packed;
  }
}
