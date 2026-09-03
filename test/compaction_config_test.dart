import 'package:antigravity/src/connections/local/local_connection_config.dart';
import 'package:antigravity/src/types.dart';
import 'package:test/test.dart';

void main() {
  group('CompactionConfig validation', () {
    test('accepts positive values', () {
      final cfg = CompactionConfig(
        checkpointIntervalTokens: 1000,
        maxContextTokens: 2000,
      );

      expect(cfg.checkpointIntervalTokens, equals(1000));
      expect(cfg.maxContextTokens, equals(2000));
    });

    test('rejects a non-positive checkpointIntervalTokens', () {
      expect(
        () => CompactionConfig(checkpointIntervalTokens: 0),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('rejects a non-positive maxContextTokens', () {
      expect(
        () => CompactionConfig(maxContextTokens: -1),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('requires checkpointIntervalTokens <= maxContextTokens', () {
      expect(
        () => CompactionConfig(
          checkpointIntervalTokens: 5000,
          maxContextTokens: 1000,
        ),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('compactionThreshold is an alias for checkpointIntervalTokens', () {
      // ignore: deprecated_member_use_from_same_package
      final cfg = CompactionConfig(compactionThreshold: 4096);

      expect(cfg.checkpointIntervalTokens, equals(4096));
      // ignore: deprecated_member_use_from_same_package
      expect(cfg.compactionThreshold, equals(4096));
    });

    test('conflicting alias and canonical values raise', () {
      expect(
        // ignore: deprecated_member_use_from_same_package
        () => CompactionConfig(
          checkpointIntervalTokens: 4096,
          compactionThreshold: 8192,
        ),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('serializes to snake_case wire keys', () {
      final map = CompactionConfig(
        checkpointIntervalTokens: 1000,
        maxContextTokens: 2000,
      ).toMap();

      expect(map['checkpoint_interval_tokens'], equals(1000));
      expect(map['max_context_tokens'], equals(2000));
    });
  });

  group('CapabilitiesConfig.compactionThreshold validation', () {
    test('accepts a positive threshold', () {
      expect(
        CapabilitiesConfig(compactionThreshold: 1).compactionThreshold,
        equals(1),
      );
    });

    test('rejects a zero threshold', () {
      expect(
        () => CapabilitiesConfig(compactionThreshold: 0),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('rejects a negative threshold', () {
      expect(
        () => CapabilitiesConfig(compactionThreshold: -1),
        throwsA(isA<AntigravityValidationException>()),
      );
    });
  });

  group('AgentConfig.effectiveCompactionConfig', () {
    test('returns compactionConfig when set', () {
      final config = LocalAgentConfig(
        compactionConfig: CompactionConfig(checkpointIntervalTokens: 1000),
      );

      expect(
        config.effectiveCompactionConfig?.checkpointIntervalTokens,
        equals(1000),
      );
    });

    test('compactionConfig takes precedence over capabilities threshold', () {
      final config = LocalAgentConfig(
        compactionConfig: CompactionConfig(checkpointIntervalTokens: 1000),
        capabilities: CapabilitiesConfig(compactionThreshold: 9999),
      );

      expect(
        config.effectiveCompactionConfig?.checkpointIntervalTokens,
        equals(1000),
      );
    });

    test('falls back to capabilities.compactionThreshold', () {
      final config = LocalAgentConfig(
        capabilities: CapabilitiesConfig(compactionThreshold: 9999),
      );

      expect(
        config.effectiveCompactionConfig?.checkpointIntervalTokens,
        equals(9999),
      );
    });

    test('returns null when neither is set', () {
      expect(LocalAgentConfig().effectiveCompactionConfig, isNull);
    });
  });

  group('LiteRTAgentConfig context ceiling consolidation', () {
    test('resolves the ceiling from compactionConfig', () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        compactionConfig: CompactionConfig(maxContextTokens: 8192),
      );

      expect(config.effectiveMaxContextTokens, equals(8192));
      expect(config.effectiveCompactionConfig?.maxContextTokens, equals(8192));
    });

    test('falls back to the deprecated maxContextTokens field', () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        // ignore: deprecated_member_use_from_same_package
        maxContextTokens: 4096,
      );

      expect(config.effectiveMaxContextTokens, equals(4096));
      // The legacy value also reaches the harness compaction policy, so the
      // runner and the harness agree on one ceiling.
      expect(config.effectiveCompactionConfig?.maxContextTokens, equals(4096));
    });

    test('compactionConfig wins over the deprecated field', () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        // ignore: deprecated_member_use_from_same_package
        maxContextTokens: 4096,
        compactionConfig: CompactionConfig(maxContextTokens: 8192),
      );

      expect(config.effectiveMaxContextTokens, equals(8192));
    });

    test('preserves the checkpoint interval when folding in the legacy field',
        () {
      final config = LiteRTAgentConfig(
        modelPath: '/tmp/model.litertlm',
        // ignore: deprecated_member_use_from_same_package
        maxContextTokens: 8192,
        compactionConfig: CompactionConfig(checkpointIntervalTokens: 2048),
      );

      final resolved = config.effectiveCompactionConfig;
      expect(resolved?.checkpointIntervalTokens, equals(2048));
      expect(resolved?.maxContextTokens, equals(8192));
    });

    test('is null when no ceiling is configured', () {
      final config = LiteRTAgentConfig(modelPath: '/tmp/model.litertlm');

      expect(config.effectiveMaxContextTokens, isNull);
    });
  });
}
