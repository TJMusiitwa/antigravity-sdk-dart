import 'package:test/test.dart';
import 'package:antigravity/src/connections/local/local_connection.dart';
import 'package:antigravity/src/types.dart';
import 'package:antigravity/src/tools/tool_runner.dart';
import 'package:antigravity/src/hooks/hooks.dart';

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

      // Accessing package-private _buildHarnessConfig
      // Since it's in the same library, normally we'd import/library
      // but wait, in tests we can instantiate the class and use it.
      // Wait! We can call Strategy's config building or test it by calling strategy._buildHarnessConfig()
      // Let's verify that we can build config.
      final config = strategy.connectHarnessConfigForTest();
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
}

// Add an extension for testing purposes to access internal methods of LocalOpenAIConnectionStrategy
extension LocalConnectionStrategyTest on LocalConnectionStrategy {
  Map<String, dynamic> connectHarnessConfigForTest() {
    // Harness config is private method _buildHarnessConfig in LocalConnectionStrategy
    // But since extension is in this file, we can't access it unless we expose it or use a public method.
    // Wait, is there a public method that calls it?
    // No, but we can expose _buildHarnessConfig for testing by adding a public helper in LocalConnectionStrategy, or we can use a redirect.
    // Wait! Let's check how we can expose it.
    // In local_connection.dart, we can add:
    // `Map<String, dynamic> buildHarnessConfigForTest() => _buildHarnessConfig();`
    // Let's check if we did this or we need to add it!
    // Yes! Let's add `Map<String, dynamic> buildHarnessConfigForTest() => _buildHarnessConfig();` to LocalConnectionStrategy in local_connection.dart.
    return buildHarnessConfigForTest();
  }
}
