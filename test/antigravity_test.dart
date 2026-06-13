import 'dart:io';
import 'package:test/test.dart';
import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/localharness_proto.dart';

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

  group('Varint & Protobuf Handshake Tests', () {
    test('Varint Encoding and Decoding', () {
      final values = [0, 1, 127, 128, 300, 16384, 2097151];
      for (final value in values) {
        final encoded = LocalHarnessProto.encodeVarint(value);
        final decoded = LocalHarnessProto.decodeVarint(encoded, [0]);
        expect(decoded, value);
      }
    });

    test('InputConfig Encoding and OutputConfig Decoding', () {
      final inputBytes = LocalHarnessProto.encodeInputConfig(
        storageDirectory: '/tmp/antigravity',
        port: 8080,
        bindAddress: '127.0.0.1',
      );
      expect(inputBytes.isNotEmpty, true);

      // Construct a fake serialized OutputConfig message:
      // tag 1 (port, wire type 0) = 9090
      // tag 2 (api_key, wire type 2) = "test_api_key_123"
      final List<int> fakeOutputBytes = [];
      // Tag 1 (1 << 3 | 0 = 8)
      fakeOutputBytes.addAll(LocalHarnessProto.encodeVarint(8));
      fakeOutputBytes.addAll(LocalHarnessProto.encodeVarint(9090));
      // Tag 2 (2 << 3 | 2 = 18)
      fakeOutputBytes.addAll(LocalHarnessProto.encodeVarint(18));
      final keyBytes = 'test_api_key_123'.codeUnits;
      fakeOutputBytes.addAll(LocalHarnessProto.encodeVarint(keyBytes.length));
      fakeOutputBytes.addAll(keyBytes);

      final parsed = LocalHarnessProto.decodeOutputConfig(fakeOutputBytes);
      expect(parsed.port, 9090);
      expect(parsed.apiKey, 'test_api_key_123');
    });

    test('Length Prefixed Packing', () {
      final payload = [1, 2, 3, 4];
      final packed = LocalHarnessProto.packMessage(payload);
      expect(packed.length, 8);
      expect(packed[0], 4); // Little endian length prefix
      expect(packed[1], 0);
      expect(packed[2], 0);
      expect(packed[3], 0);
      expect(packed[4], 1);
      expect(packed[5], 2);
    });
  });

  group('Binary Discovery Tests', () {
    test('Config path override discovery', () async {
      final tempFile = File('${Directory.systemTemp.path}/fake_agy');
      tempFile.writeAsStringSync('binary');

      try {
        final path = await BinaryDiscovery.discover(
          configPath: tempFile.path,
          autoDownload: false,
        );
        expect(path, tempFile.absolute.path);
      } finally {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }
    });

    test('Throw Exception on non-existent binary', () async {
      expect(
        BinaryDiscovery.discover(
          configPath: '/nonexistent/path/to/harness',
          autoDownload: false,
        ),
        throwsA(isA<AntigravityBinaryNotFoundException>()),
      );
    });
  });

  group('Safety Policies & Workspace Verification Tests', () {
    test('Workspace path containment verification', () {
      expect(isPathInWorkspace('/workspace/src/foo.dart', '/workspace'), true);
      expect(
        isPathInWorkspace('/workspace/../outside.dart', '/workspace'),
        false,
      );
      expect(
        isPathInWorkspace('/workspace/src/../src/foo.dart', '/workspace'),
        true,
      );
    });

    test('allowAll policy approves everything', () async {
      final hook = enforce([allowAll()]);
      final toolCall = ToolCall(
        name: 'run_command',
        args: {'command': 'rm -rf /'},
      );
      final context = HookContext();
      final result = await hook.run(context, toolCall);
      expect(result.allow, true);
    });

    test('denyAll policy denies everything', () async {
      final hook = enforce([denyAll()]);
      final toolCall = ToolCall(name: 'run_command', args: {'command': 'ls'});
      final context = HookContext();
      final result = await hook.run(context, toolCall);
      expect(result.allow, false);
      expect(result.message, contains("Denied by policy 'deny_all'"));
    });

    test('workspaceOnly policy restrictions', () async {
      final hook = enforce(workspaceOnly(['/safe/workspace']));

      final insideCall = ToolCall(
        name: 'view_file',
        args: {},
        id: '1',
        canonicalPath: '/safe/workspace/file.txt',
      );
      final outsideCall = ToolCall(
        name: 'view_file',
        args: {},
        id: '2',
        canonicalPath: '/unsafe/path/file.txt',
      );

      final context = HookContext();

      final insideResult = await hook.run(context, insideCall);
      expect(insideResult.allow, true);

      final outsideResult = await hook.run(context, outsideCall);
      expect(outsideResult.allow, false);
      expect(
        outsideResult.message,
        contains("Denied by policy 'workspace_only'"),
      );
    });
  });
}
