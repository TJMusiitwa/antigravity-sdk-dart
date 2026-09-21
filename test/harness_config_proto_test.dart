import 'package:antigravity/src/connections/connection.dart';
import 'package:antigravity/src/connections/local/local_connection.dart';
import 'package:antigravity/src/connections/local/local_connection_config.dart';
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
    CompactionConfig? compactionConfig,
    BudgetConfig? budgetConfig,
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
      compactionConfig: compactionConfig,
      budgetConfig: budgetConfig,
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

  group('run_command proto configuration', () {
    test('defaults enable_daemon_commands to false and max_timeout_ms to 0',
        () {
      final config = buildStrategy().buildHarnessConfigForTest();
      final runCmd = (config['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(runCmd['enabled'], isTrue);
      expect(runCmd['enable_daemon_commands'], isFalse);
      expect(runCmd['max_timeout_ms'], equals(0));
    });

    test(
        'custom RunCommandConfig sets enable_daemon_commands and max_timeout_ms',
        () {
      final config = buildStrategy(
        capabilitiesConfig: CapabilitiesConfig(
          runCommandConfig: RunCommandConfig(
            enableDaemons: true,
            timeoutSeconds: 60.0,
          ),
        ),
      ).buildHarnessConfigForTest();
      final runCmd = (config['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(runCmd['enabled'], isTrue);
      expect(runCmd['enable_daemon_commands'], isTrue);
      expect(runCmd['max_timeout_ms'], equals(60000));
    });

    test('subagent honors RunCommandConfig', () {
      final config = buildStrategy(
        subagents: [
          SubagentConfig(
            name: 'dev_server',
            description: 'Runs daemons',
            capabilities: SubagentCapabilities(
              runCommandConfig: RunCommandConfig(
                enableDaemons: true,
                timeoutSeconds: 30.0,
              ),
            ),
          ),
        ],
      ).buildHarnessConfigForTest();

      final subagent = (config['custom_subagents'] as List).first as Map;
      final subRunCmd = (subagent['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(subRunCmd['enable_daemon_commands'], isTrue);
      expect(subRunCmd['max_timeout_ms'], equals(30000));
    });

    test('includes enable_sandbox in run_command wire proto', () {
      final config = buildStrategy(
        capabilitiesConfig: CapabilitiesConfig(
          runCommandConfig: RunCommandConfig(
            enableSandbox: true,
          ),
        ),
      ).buildHarnessConfigForTest();
      final runCmd = (config['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(runCmd['enable_sandbox'], isTrue);
    });

    test('enable_sandbox defaults to false when RunCommandConfig is not set',
        () {
      final config = buildStrategy().buildHarnessConfigForTest();
      final runCmd = (config['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(runCmd['enable_sandbox'], isFalse);
    });

    test('enable_sandbox is false when RunCommandConfig.enableSandbox is false',
        () {
      final config = buildStrategy(
        capabilitiesConfig: CapabilitiesConfig(
          runCommandConfig: RunCommandConfig(enableSandbox: false),
        ),
      ).buildHarnessConfigForTest();
      final runCmd = (config['harness_side_tools'] as Map)['run_command']
          as Map<String, dynamic>;

      expect(runCmd['enable_sandbox'], isFalse);
    });
  });

  group('workspace serialization in harness config', () {
    test('normalizes relative workspace paths to absolute paths in proto', () {
      final strategy = LocalConnectionStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const ['.', './test'],
        skillsPaths: const [],
      );
      final config = strategy.buildHarnessConfigForTest();
      final workspaces = (config['workspaces'] as List)
          .map((ws) => ws['filesystem_workspace']['directory'])
          .toList();

      expect(workspaces[0], isNot(equals('.')));
      expect(workspaces[0], isNot(startsWith('./')));
      expect(workspaces[1], isNot(startsWith('./')));
    });
  });

  group('enabled_hooks proto configuration', () {
    test('includes LIFECYCLE_HOOK_ON_COMPACTION when compaction hook is set',
        () {
      final runner = HookRunner(
        onCompactionHooks: [_TestCompactionHook()],
      );
      final strategy = LocalConnectionStrategy(
        toolRunner: ToolRunner(),
        hookRunner: runner,
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
      );
      final config = strategy.buildHarnessConfigForTest();
      final enabledHooks = config['enabled_hooks'] as List<String>;

      expect(enabledHooks, contains('LIFECYCLE_HOOK_ON_COMPACTION'));
    });
  });

  group('subagent custom tools scoping in harness config', () {
    test('subagent custom tools are resolved and scoped properly', () {
      final rootTool = Tool(
        name: 'root_calc',
        description: 'Calculates root stuff',
        schema: const {},
        handler: (args, ctx) async => 'root_result',
      );
      final subTool = Tool(
        name: 'sub_fetch',
        description: 'Fetches sub stuff',
        schema: const {},
        handler: (args, ctx) async => 'sub_result',
      );

      final toolRunner = ToolRunner(tools: [rootTool, subTool]);
      final strategy = LocalConnectionStrategy(
        toolRunner: toolRunner,
        hookRunner: HookRunner(),
        tools: [rootTool],
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
        subagents: [
          SubagentConfig(
            name: 'fetcher',
            description: 'Fetcher agent',
            tools: [subTool],
          ),
        ],
      );

      final config = strategy.buildHarnessConfigForTest();
      final rootTools = config['tools'] as List<Map<String, dynamic>>;
      expect(rootTools.map((t) => t['name']), contains('root_calc'));
      expect(rootTools.map((t) => t['name']), isNot(contains('sub_fetch')));

      final subagents = config['custom_subagents'] as List;
      expect(subagents, hasLength(1));
      final subagentProto = subagents.first as Map<String, dynamic>;
      final subagentTools =
          subagentProto['tools'] as List<Map<String, dynamic>>;
      expect(subagentTools.map((t) => t['name']), contains('sub_fetch'));
    });
  });

  group('debug_config client-side scoping', () {
    // Regression guard: DebugConfig is client-side only (for logging levels
    // and tracing). The localharness HarnessConfig proto does not define
    // debug_config; emitting it causes localharness protojson unmarshaling to
    // fail with `unknown field "debug_config"`.
    test('omits debug_config from harness config even when configured', () {
      final strategy = LocalConnectionStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
        debugConfig: DebugConfig(loggingLevel: 'INFO'),
      );

      final config = strategy.buildHarnessConfigForTest();
      expect(config.containsKey('debug_config'), isFalse);
    });

    test('omits debug_config when none is configured', () {
      final strategy = LocalConnectionStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: const [],
      );

      final config = strategy.buildHarnessConfigForTest();
      expect(config.containsKey('debug_config'), isFalse);
    });
  });

  group('compaction wire proto', () {
    test('compaction_config is emitted when CompactionConfig is set', () {
      final config = buildStrategy(
        compactionConfig: CompactionConfig(tokenThreshold: 40000),
      ).buildHarnessConfigForTest();

      final compaction = config['compaction_config'] as Map<String, dynamic>;
      expect(compaction['token_threshold'], equals(40000));
      expect(config['compaction_threshold'], equals(40000));
    });

    test(
        'compaction_threshold uses the legacy value when CompactionConfig is absent',
        () {
      final config = buildStrategy(
        capabilitiesConfig: CapabilitiesConfig(compactionThreshold: 1234),
      ).buildHarnessConfigForTest();

      expect(config['compaction_threshold'], equals(1234));
      expect(
        (config['compaction_config'] as Map)['token_threshold'],
        equals(1234),
      );
    });

    test('compaction_config is omitted when nothing is configured', () {
      final config = buildStrategy().buildHarnessConfigForTest();

      expect(config.containsKey('compaction_config'), isFalse);
      expect(config['compaction_threshold'], equals(0));
    });
  });

  group('budget_config wire proto', () {
    test('budget_config is omitted when no limits are set', () {
      final config = buildStrategy(
        budgetConfig: BudgetConfig(),
      ).buildHarnessConfigForTest();

      expect(config.containsKey('budget_config'), isFalse);
    });

    test('budget_config scope defaults to LIFETIME', () {
      final config = buildStrategy(
        budgetConfig: BudgetConfig(maxModelCalls: 3),
      ).buildHarnessConfigForTest();

      final budget = config['budget_config'] as Map<String, dynamic>;
      expect(budget['max_model_calls'], equals(3));
      expect(budget['scope'], equals('BUDGET_SCOPE_LIFETIME'));
    });

    test('budget_config includes a forward-looking scope', () {
      final config = buildStrategy(
        budgetConfig: BudgetConfig(
          maxTotalTokens: 5000,
          scope: BudgetScope.forwardLooking,
        ),
      ).buildHarnessConfigForTest();

      final budget = config['budget_config'] as Map<String, dynamic>;
      expect(budget['max_total_tokens'], equals(5000));
      expect(budget['scope'], equals('BUDGET_SCOPE_FORWARD_LOOKING'));
    });
  });

  group('agent_behavior wire proto', () {
    test('AGENT_BEHAVIOR_MINIMAL is emitted for AgentBehavior.minimal', () {
      final config = buildStrategy(
        capabilitiesConfig:
            CapabilitiesConfig(agentBehavior: AgentBehavior.minimal),
      ).buildHarnessConfigForTest();

      expect(config['agent_behavior'], equals('AGENT_BEHAVIOR_MINIMAL'));
    });
  });

  group('LocalAgentConfig.lightweight()', () {
    test('restricts enabled tools to the minimal set', () {
      final config = LocalAgentConfig().lightweight();

      expect(config.capabilities.enabledTools, equals(BuiltinTools.minimal()));
    });

    test('disables subagents', () {
      final config = LocalAgentConfig().lightweight();

      expect(config.capabilities.enableSubagents, isFalse);
    });

    test('sets AgentBehavior.minimal', () {
      final config = LocalAgentConfig().lightweight();

      expect(config.capabilities.agentBehavior, equals(AgentBehavior.minimal));
    });

    test('sets tokenThreshold to 65536', () {
      final config = LocalAgentConfig().lightweight();

      expect(
        config.compactionConfig?.tokenThreshold,
        equals(65536),
      );
      expect(
        config.effectiveCompactionConfig?.tokenThreshold,
        equals(65536),
      );
    });

    test('preserves unrelated configuration', () {
      final config =
          LocalAgentConfig(systemInstructions: 'stay brief').lightweight();

      expect(config.systemInstructions, equals('stay brief'));
    });

    test('keeps a caller-provided enabledTools allowlist', () {
      final config = LocalAgentConfig(
        capabilities: CapabilitiesConfig(
          enabledTools: [BuiltinTools.viewFile, BuiltinTools.finish],
        ),
      ).lightweight();

      expect(
        config.capabilities.enabledTools,
        equals([BuiltinTools.viewFile, BuiltinTools.finish]),
      );
    });

    test('subtracts caller-provided disabledTools from the minimal set', () {
      final config = LocalAgentConfig(
        capabilities: CapabilitiesConfig(
          disabledTools: [BuiltinTools.runCommand],
        ),
      ).lightweight();

      expect(
        config.capabilities.enabledTools,
        equals(BuiltinTools.minimal()
            .where((t) => t != BuiltinTools.runCommand)
            .toList()),
      );
      // enabledTools and disabledTools are mutually exclusive, so only the
      // resolved allowlist survives.
      expect(config.capabilities.disabledTools, isNull);
    });

    test('carries over runCommandConfig and finishToolSchemaJson', () {
      final config = LocalAgentConfig(
        capabilities: CapabilitiesConfig(
          runCommandConfig: RunCommandConfig(enableSandbox: true),
          finishToolSchemaJson: '{"type":"object"}',
        ),
      ).lightweight();

      expect(config.capabilities.runCommandConfig?.enableSandbox, isTrue);
      expect(
        config.capabilities.finishToolSchemaJson,
        equals('{"type":"object"}'),
      );
    });

    test('keeps a caller-provided compactionConfig', () {
      final config = LocalAgentConfig(
        compactionConfig: CompactionConfig(tokenThreshold: 1024),
      ).lightweight();

      expect(
        config.compactionConfig?.tokenThreshold,
        equals(1024),
      );
    });

    test('the resolved capabilities reach the wire proto', () {
      final config = LocalAgentConfig().lightweight();
      final strategy = config.createStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
      ) as LocalConnectionStrategy;
      final harnessConfig = strategy.buildHarnessConfigForTest();

      expect(harnessConfig['agent_behavior'], equals('AGENT_BEHAVIOR_MINIMAL'));
      expect(
        (harnessConfig['compaction_config'] as Map)['token_threshold'],
        equals(65536),
      );
    });
  });
}

class _TestCompactionHook extends OnCompactionHook {
  @override
  Future<void> run(HookContext context, Step data) async {}
}
