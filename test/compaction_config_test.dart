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
}
