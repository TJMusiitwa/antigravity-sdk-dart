import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

/// A no-op [Process] double: [LocalConnection] only needs a [Process] to
/// hold a reference for [Connection.disconnect]; it is never started or
/// inspected by [LocalConnection.sendToolResults].
class FakeProcess implements Process {
  @override
  Future<int> get exitCode => Completer<int>().future;

  @override
  Stream<List<int>> get stdout => const Stream.empty();

  @override
  Stream<List<int>> get stderr => const Stream.empty();

  @override
  IOSink get stdin => IOSink(StreamController<List<int>>().sink);

  @override
  int get pid => -1;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;
}

void main() {
  group('LocalConnection.sendToolResults', () {
    late HttpServer server;
    late WebSocket clientWs;
    late StreamController<Map<String, dynamic>> received;
    late LocalConnection connection;

    setUp(() async {
      received = StreamController<Map<String, dynamic>>.broadcast();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final serverWs = await WebSocketTransformer.upgrade(request);
        serverWs.listen((msg) {
          received.add(jsonDecode(msg as String) as Map<String, dynamic>);
        });
      });

      clientWs = await WebSocket.connect('ws://127.0.0.1:${server.port}');
      connection = LocalConnection(
        process: FakeProcess(),
        ws: clientWs,
        messageStream: clientWs,
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
      );
    });

    tearDown(() async {
      await clientWs.close();
      await server.close(force: true);
      await received.close();
    });

    test('plain result has no supplemental_media key', () async {
      await connection.sendToolResults([
        ToolResult(id: 'call-1', name: 'echo', result: 'hello'),
      ]);

      final event = await received.stream.first;
      final toolResponse = event['tool_response'] as Map<String, dynamic>;
      expect(toolResponse['id'], equals('call-1'));
      expect(toolResponse.containsKey('supplemental_media'), isFalse);

      final responseJson = jsonDecode(toolResponse['response_json'] as String)
          as Map<String, dynamic>;
      expect(responseJson['result'], equals('hello'));
    });

    test('error result short-circuits media extraction', () async {
      await connection.sendToolResults([
        ToolResult(id: 'call-err', name: 'broken', error: 'boom'),
      ]);

      final event = await received.stream.first;
      final toolResponse = event['tool_response'] as Map<String, dynamic>;
      expect(toolResponse.containsKey('supplemental_media'), isFalse);

      final responseJson = jsonDecode(toolResponse['response_json'] as String)
          as Map<String, dynamic>;
      expect(responseJson['error'], equals('boom'));
    });

    test('a MediaContent result is extracted into supplemental_media',
        () async {
      final img = Image(
        mimeType: 'image/png',
        description: 'a test image',
        data: [1, 2, 3, 4],
      );
      await connection.sendToolResults([
        ToolResult(id: 'call-2', name: 'load_image', result: img),
      ]);

      final event = await received.stream.first;
      final toolResponse = event['tool_response'] as Map<String, dynamic>;
      final media = toolResponse['supplemental_media'] as List<dynamic>;
      expect(media, hasLength(1));
      expect(media[0]['mime_type'], equals('image/png'));
      expect(media[0]['description'], equals('a test image'));
      expect(media[0]['data'], equals(base64Encode([1, 2, 3, 4])));

      // No text left over, so response_json gets an auto-generated placeholder.
      final responseJson = jsonDecode(toolResponse['response_json'] as String)
          as Map<String, dynamic>;
      expect(responseJson['result'], equals('Returned 1 media attachment(s).'));
    });

    test('mixed list result keeps text and extracts media separately',
        () async {
      final img = Image(
        mimeType: 'image/jpeg',
        description: 'photo',
        data: [9, 9, 9],
      );
      await connection.sendToolResults([
        ToolResult(
          id: 'call-3',
          name: 'load_with_caption',
          result: ['Here is the photo.', img],
        ),
      ]);

      final event = await received.stream.first;
      final toolResponse = event['tool_response'] as Map<String, dynamic>;
      final media = toolResponse['supplemental_media'] as List<dynamic>;
      expect(media, hasLength(1));
      expect(media[0]['mime_type'], equals('image/jpeg'));

      final responseJson = jsonDecode(toolResponse['response_json'] as String)
          as Map<String, dynamic>;
      expect(responseJson['result'], equals(['Here is the photo.']));
    });
  });

  group('LocalConnection trajectory state tracking', () {
    late StreamController<dynamic> messageStream;
    late LocalConnection connection;
    late HttpServer server;
    late WebSocket clientWs;

    setUp(() async {
      messageStream = StreamController<dynamic>.broadcast();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        await WebSocketTransformer.upgrade(request);
      });
      clientWs = await WebSocket.connect('ws://127.0.0.1:${server.port}');
      connection = LocalConnection(
        process: FakeProcess(),
        ws: clientWs,
        messageStream: messageStream.stream,
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        conversationId: 'cascade-123',
      );
      connection.startReaderLoop();
    });

    tearDown(() async {
      await connection.disconnect();
      await clientWs.close();
      await server.close(force: true);
      await messageStream.close();
    });

    test('step_update sets mainTrajectoryId and preserves conversationId', () async {
      final steps = connection.receiveSteps();
      messageStream.add(jsonEncode({
        'step_update': {
          'trajectory_id': 'traj-main',
          'cascade_id': 'cascade-123',
          'step_index': 0,
          'type': 'MODEL',
          'source': 'SOURCE_MODEL',
          'target': 'TARGET_USER',
          'status': 'ACTIVE',
          'content_delta': 'hello',
        }
      }));

      final step = await steps.first;
      expect(step.contentDelta, equals('hello'));
      expect(connection.mainTrajectoryId, equals('traj-main'));
      expect(connection.conversationId, equals('cascade-123'));
    });

    test('trajectory_state_update for main trajectory emits idle_sentinel', () async {
      connection.mainTrajectoryId = 'traj-main';

      final steps = connection.receiveSteps();
      final stepFuture = steps.first;

      messageStream.add(jsonEncode({
        'trajectory_state_update': {
          'trajectory_id': 'traj-main',
          'state': 'STATE_FULLY_IDLE',
        }
      }));

      final step = await stepFuture;
      expect(step.id, equals('idle_sentinel'));
      expect(connection.isIdle, isTrue);
    });

    test('subagent trajectory_state_update does not emit idle_sentinel', () async {
      connection.mainTrajectoryId = 'traj-main';

      final receivedSteps = <Step>[];
      final sub = connection.receiveSteps().listen(receivedSteps.add);

      messageStream.add(jsonEncode({
        'trajectory_state_update': {
          'trajectory_id': 'subagent-traj-999',
          'state': 'STATE_FULLY_IDLE',
        }
      }));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(receivedSteps, isEmpty);
      await sub.cancel();
    });
  });
}
