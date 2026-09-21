import 'package:antigravity/src/connections/local/local_connection_config.dart';
import 'package:antigravity/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('CompactionConfig', () {
    test('accepts a positive token threshold', () {
      final config = CompactionConfig(tokenThreshold: 50000);

      expect(config.tokenThreshold, equals(50000));
      // ignore: deprecated_member_use_from_same_package
      expect(config.checkpointIntervalTokens, equals(50000));
    });

    test('rejects a non-positive token threshold', () {
      expect(
        () => CompactionConfig(tokenThreshold: 0),
        throwsA(isA<AntigravityValidationException>()),
      );
      expect(
        () => CompactionConfig(tokenThreshold: -1),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('serializes to the token_threshold wire key', () {
      final map = CompactionConfig(tokenThreshold: 50000).toMap();

      expect(map, equals({'token_threshold': 50000}));
    });

    test('parses the token_threshold wire key', () {
      final config = CompactionConfig.fromMap({'token_threshold': 50000});

      expect(config.tokenThreshold, equals(50000));
    });
  });

  group('CapabilitiesConfig.compactionThreshold validation', () {
    test('accepts a positive threshold', () {
      expect(
        CapabilitiesConfig(compactionThreshold: 1).compactionThreshold,
        equals(1),
      );
    });

    test('rejects a non-positive threshold', () {
      expect(
        () => CapabilitiesConfig(compactionThreshold: 0),
        throwsA(isA<AntigravityValidationException>()),
      );
      expect(
        () => CapabilitiesConfig(compactionThreshold: -1),
        throwsA(isA<AntigravityValidationException>()),
      );
    });
  });

  group('AgentConfig.effectiveCompactionConfig', () {
    test('returns compactionConfig when set', () {
      final config = LocalAgentConfig(
        compactionConfig: CompactionConfig(tokenThreshold: 1000),
      );

      expect(config.effectiveCompactionConfig?.tokenThreshold, equals(1000));
    });

    test('compactionConfig takes precedence over capabilities threshold', () {
      final config = LocalAgentConfig(
        compactionConfig: CompactionConfig(tokenThreshold: 1000),
        capabilities: CapabilitiesConfig(compactionThreshold: 9999),
      );

      expect(config.effectiveCompactionConfig?.tokenThreshold, equals(1000));
    });

    test('falls back to capabilities.compactionThreshold', () {
      final config = LocalAgentConfig(
        capabilities: CapabilitiesConfig(compactionThreshold: 9999),
      );

      expect(config.effectiveCompactionConfig?.tokenThreshold, equals(9999));
    });

    test('returns null when neither is set', () {
      expect(LocalAgentConfig().effectiveCompactionConfig, isNull);
    });
  });

  group('LiteRTAgentConfig context ceiling', () {
    test('keeps the deprecated LiteRT context ceiling independent', () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        // ignore: deprecated_member_use_from_same_package
        maxContextTokens: 4096,
      );

      expect(config.effectiveMaxContextTokens, equals(4096));
      expect(config.effectiveCompactionConfig, isNull);
    });

    test('preserves token threshold in the shared compaction policy', () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        compactionConfig: CompactionConfig(tokenThreshold: 2048),
      );

      expect(config.effectiveCompactionConfig?.tokenThreshold, equals(2048));
    });
  });
}
