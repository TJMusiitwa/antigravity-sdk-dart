import 'package:test/test.dart';
import 'package:antigravity/antigravity.dart';

void main() {
  group('State Equality & Copying (dart_mappable)', () {
    test('GeminiConfig deep equality', () {
      final c1 = GeminiConfig(apiKey: 'key1', models: ModelConfig());
      final c2 = GeminiConfig(apiKey: 'key1', models: ModelConfig());
      final c3 = GeminiConfig(apiKey: 'key2', models: ModelConfig());

      expect(c1, equals(c2)); // Deep equality
      expect(c1, isNot(equals(c3)));
      expect(c1.hashCode, equals(c2.hashCode));
    });

    test('GeminiConfig copyWith branches correctly', () {
      final original = GeminiConfig(apiKey: 'old-key');
      final branched = original.copyWith(apiKey: 'new-key');

      expect(branched.apiKey, equals('new-key'));
      expect(original.apiKey, equals('old-key'));
      expect(branched.models, equals(original.models)); // Unchanged sub-object
    });

    test('CapabilitiesConfig deep equality with lists', () {
      final cfg1 = CapabilitiesConfig(
        enabledTools: [BuiltinTools.viewFile, BuiltinTools.editFile],
      );
      final cfg2 = CapabilitiesConfig(
        enabledTools: [BuiltinTools.viewFile, BuiltinTools.editFile],
      );
      final cfg3 = CapabilitiesConfig(
        enabledTools: [
          BuiltinTools.editFile,
          BuiltinTools.viewFile,
        ], // Different order
      );

      expect(cfg1, equals(cfg2));
      // dart_mappable handles list equality by default
      expect(cfg1, isNot(equals(cfg3)));
    });

    test('Step data class features', () {
      final step = Step(
        id: '1',
        stepIndex: 1,
        type: StepType.textResponse,
        source: StepSource.model,
        target: StepTarget.user,
        status: StepStatus.done,
      );

      final nextStep = step.copyWith(id: '2', stepIndex: 2);

      expect(nextStep.id, equals('2'));
      expect(nextStep.type, equals(StepType.textResponse)); // Preserved
      expect(nextStep, isNot(equals(step)));
    });
  });

  group('Polymorphic Parsing (dart_mappable)', () {
    test('McpServerConfig parses Stdio correctly', () {
      final map = {
        'type': 'stdio',
        'name': 'stdio_test',
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-everything'],
      };
      final config = McpServerConfig.fromMap(map);

      expect(config, isA<McpStdioServer>());
      expect((config as McpStdioServer).command, equals('npx'));
    });

    test('SystemInstructions polymorphic branching', () {
      final si = CustomSystemInstructions(text: 'Hello');
      final siMap = si.toMap();
      // Verify that toMap includes the discriminator or is correctly nested
      // Based on our implementation, it returns a map with a 'custom' key
      expect(siMap.containsKey('custom'), isTrue);
    });
  });
}
