import 'dart:io';

import 'package:antigravity/src/connections/local/local_connection.dart';
import 'package:antigravity/src/connections/local/local_connection_config.dart';
import 'package:antigravity/src/hooks/hooks.dart';
import 'package:antigravity/src/tools/tool_runner.dart';
import 'package:antigravity/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('LocalOpenAIConnectionStrategy', () {
    test('validateConnection throws on empty baseUrl', () {
      final strategy = LocalOpenAIConnectionStrategy(
        baseUrl: '',
        modelName: 'gemma',
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
      );

      expect(
        () => strategy.start(), // calls _validateConnection()
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('_buildHarnessConfig includes gemma_endpoint', () {
      final strategy = LocalOpenAIConnectionStrategy(
        baseUrl: 'http://localhost:11434/v1',
        modelName: 'gemma-2',
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
      );

      final config = strategy.buildHarnessConfigForTest();
      expect(config['models'], isNotEmpty);
      final modelCfg = config['models'].last as Map<String, dynamic>;
      expect(modelCfg['name'], equals('gemma-2'));
      expect(modelCfg['types'], contains('MODEL_TYPE_TEXT'));
      expect(modelCfg['gemma_endpoint']['base_url'],
          equals('http://localhost:11434/v1'));
    });
  });

  group('LiteRTConnectionStrategy', () {
    test('validateConnection throws if modelPath does not exist', () {
      final strategy = LiteRTConnectionStrategy(
        modelPath: '/definitely/nonexistent/model.litertlm',
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
      );

      expect(
        () => strategy.start(), // calls _validateConnection()
        throwsA(isA<AntigravityValidationException>()),
      );
    });
  });

  group('extractMediaFromResult', () {
    test('extracts media from single MediaContent', () {
      final img =
          Image(mimeType: 'image/png', description: 'test', data: [1, 2, 3]);
      final extracted = extractMediaFromResult(img);
      expect(extracted.cleanedValue, isNull);
      expect(extracted.media, hasLength(1));
      expect(extracted.media.first, equals(img));
    });

    test('extracts media recursively from List', () {
      final img =
          Image(mimeType: 'image/png', description: 'test', data: [1, 2, 3]);
      final list = ['hello', img, 'world'];
      final extracted = extractMediaFromResult(list);
      expect(extracted.cleanedValue, equals(['hello', 'world']));
      expect(extracted.media, hasLength(1));
      expect(extracted.media.first, equals(img));
    });

    test('extracts media recursively from Map', () {
      final img =
          Image(mimeType: 'image/png', description: 'test', data: [1, 2, 3]);
      final map = {'msg': 'hello', 'attachment': img};
      final extracted = extractMediaFromResult(map);
      expect(extracted.cleanedValue, equals({'msg': 'hello'}));
      expect(extracted.media, hasLength(1));
      expect(extracted.media.first, equals(img));
    });
  });

  group('BaseLocalAgentConfig Defaults', () {
    test('default workspaces contains current directory path', () {
      final config = LocalAgentConfig();
      expect(config.workspaces, isNotEmpty);
      expect(config.workspaces.first, equals(Directory.current.absolute.path));
    });

    test('default capabilities is enabled and has standard config', () {
      final config = LocalAgentConfig();
      expect(config.capabilities.enabledTools, isNull);
    });
  });
}
