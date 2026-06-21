import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  group('State Equality & Copying (dart_mappable)', () {
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
        'name': 'std-srv',
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-everything'],
      };
      final config = McpServerConfig.fromMap(map);

      expect(config, isA<McpStdioServer>());
      expect((config as McpStdioServer).command, equals('npx'));
    });

    test('McpServerConfig parses HTTP correctly', () {
      final map = {
        'type': 'http',
        'name': 'http-srv',
        'url': 'http://localhost:8080/mcp',
        'headers': {'X-Auth': 'Token'},
      };
      final config = McpServerConfig.fromMap(map);

      expect(config, isA<McpStreamableHttpServer>());
      expect(
        (config as McpStreamableHttpServer).headers?['X-Auth'],
        equals('Token'),
      );
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
