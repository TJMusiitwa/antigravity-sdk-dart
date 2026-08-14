import 'package:antigravity/src/connections/local/local_connection.dart';
import 'package:antigravity/src/hooks/hooks.dart';
import 'package:antigravity/src/tools/tool_runner.dart';
import 'package:antigravity/src/types.dart';
import 'package:test/test.dart';

/// These cover the shape of the config payload sent to `localharness`, where a
/// wrong key is not a Dart error but an `unknown field` rejection (or a silently
/// ignored setting) at runtime.
void main() {
  LocalConnectionStrategy buildStrategy({
    RetryConfig? retryConfig,
    List<SubagentConfig>? subagents,
    CapabilitiesConfig? capabilitiesConfig,
  }) {
    return LocalConnectionStrategy(
      toolRunner: ToolRunner(),
      hookRunner: HookRunner(),
      systemInstructions: null,
      capabilitiesConfig: capabilitiesConfig ?? CapabilitiesConfig(),
      workspaces: const [],
      skillsPaths: const [],
      subagents: subagents,
      retryConfig: retryConfig,
    );
  }

  group('harness_side_tools proto naming', () {
    test('main agent uses localharness file tool names', () {
      final config = buildStrategy().buildHarnessConfigForTest();
      final tools = config['harness_side_tools'] as Map<String, dynamic>;

      expect(tools, contains('file_edit'));
      expect(tools, contains('write_to_file'));
      // The SDK-facing names must not leak onto the wire.
      expect(tools, isNot(contains('edit_file')));
      expect(tools, isNot(contains('create_file')));
    });

    test('subagent tool keys match the main agent tool keys', () {
      final config = buildStrategy(
        subagents: [
          SubagentConfig(name: 'researcher', description: 'Reads things.'),
        ],
      ).buildHarnessConfigForTest();

      final mainTools = config['harness_side_tools'] as Map<String, dynamic>;
      final subagents = config['custom_subagents'] as List;
      expect(subagents, hasLength(1));
      final subTools = (subagents.first as Map)['harness_side_tools']
          as Map<String, dynamic>;

      // The subagent block is a near-copy of the main-agent block; any key it
      // defines must be a key localharness already accepts for the main agent.
      expect(mainTools.keys, containsAll(subTools.keys));
    });

    test('subagent honors disabled tools under the renamed keys', () {
      final config = buildStrategy(
        subagents: [
          SubagentConfig(
            name: 'reader',
            description: 'Read-only.',
            capabilities: SubagentCapabilities(
              disabledTools: [BuiltinTools.editFile, BuiltinTools.createFile],
            ),
          ),
        ],
      ).buildHarnessConfigForTest();

      final subTools = ((config['custom_subagents'] as List).first
          as Map)['harness_side_tools'] as Map<String, dynamic>;

      expect((subTools['file_edit'] as Map)['enabled'], isFalse);
      expect((subTools['write_to_file'] as Map)['enabled'], isFalse);
      expect((subTools['view_file'] as Map)['enabled'], isTrue);
    });
  });

  group('retry_config proto', () {
    test('is omitted when no retry config is set', () {
      final config = buildStrategy().buildHarnessConfigForTest();
      expect(config, isNot(contains('retry_config')));
    });

    test('serializes to snake_case proto fields only', () {
      final config = buildStrategy(
        retryConfig: RetryConfig(
          apiRetry: ModelAPIRetryConfig(
            maxRetries: 3,
            initialSleepDurationMs: 500,
            exponentialMultiplier: 2.0,
            jitterRange: 0.2,
          ),
          modelOutputRetry: ModelOutputRetryConfig(maxRetries: 2),
        ),
      ).buildHarnessConfigForTest();

      expect(
        config['retry_config'],
        equals({
          'api_retry': {
            'max_retries': 3,
            'initial_sleep_duration_ms': 500,
            'exponential_multiplier': 2.0,
            'jitter_range': 0.2,
          },
          'model_output_retry': {'max_retries': 2},
        }),
      );
    });

    test('Duration convenience arg lands as initial_sleep_duration_ms', () {
      final config = buildStrategy(
        retryConfig: RetryConfig(
          apiRetry: ModelAPIRetryConfig(
            initialSleepDuration: const Duration(seconds: 1),
          ),
        ),
      ).buildHarnessConfigForTest();

      final apiRetry =
          (config['retry_config'] as Map)['api_retry'] as Map<String, dynamic>;

      expect(apiRetry['initial_sleep_duration_ms'], equals(1000));
      // `initialSleepDuration` is a convenience getter, not a wire field; the
      // harness rejects the extra key and Duration is not encodable.
      expect(apiRetry, isNot(contains('initial_sleep_duration')));
      expect(apiRetry.keys, equals(['initial_sleep_duration_ms']));
    });

    test('unset fields are omitted rather than sent as null', () {
      final config = buildStrategy(
        retryConfig: RetryConfig(apiRetry: ModelAPIRetryConfig(maxRetries: 1)),
      ).buildHarnessConfigForTest();

      expect(
        config['retry_config'],
        equals({
          'api_retry': {'max_retries': 1},
        }),
      );
    });
  });

  group('ModelAPIRetryConfig serialization', () {
    test('toMap does not throw on the Duration convenience getter', () {
      final config = ModelAPIRetryConfig(
        maxRetries: 3,
        initialSleepDuration: const Duration(seconds: 1),
      );

      expect(
        config.toMap(),
        equals({'max_retries': 3, 'initial_sleep_duration_ms': 1000}),
      );
    });

    test('round-trips through toMap/fromMap', () {
      final original = ModelAPIRetryConfig(
        maxRetries: 5,
        initialSleepDuration: const Duration(milliseconds: 750),
        exponentialMultiplier: 1.5,
        jitterRange: 0.3,
      );

      final restored = ModelAPIRetryConfig.fromMap(original.toMap());

      expect(restored.maxRetries, equals(5));
      expect(restored.initialSleepDurationMs, equals(750));
      expect(
        restored.initialSleepDuration,
        equals(const Duration(milliseconds: 750)),
      );
      expect(restored.exponentialMultiplier, equals(1.5));
      expect(restored.jitterRange, equals(0.3));
    });

    test('raw constructor still validates its arguments', () {
      expect(
        () => ModelAPIRetryConfig.raw(maxRetries: -1),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('RetryConfig.benchmark serializes cleanly', () {
      expect(
        RetryConfig.benchmark().toMap(),
        equals({
          'api_retry': {
            'max_retries': 4294967295,
            'initial_sleep_duration_ms': 1000,
          },
        }),
      );
    });
  });
}
