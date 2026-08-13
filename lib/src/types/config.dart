import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';

import 'capabilities.dart';
import 'exceptions.dart';

part 'config.mapper.dart';

final _subagentLogger = Logger('antigravity.subagent');

/// Capabilities configuration for subagents.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class SubagentCapabilities with SubagentCapabilitiesMappable {
  /// The execution behavior of the subagent (e.g. autonomous or interactive).
  final AgentBehavior agentBehavior;

  /// Optional explicit list of builtin tools enabled for this subagent.
  final List<BuiltinTools>? enabledTools;

  /// Optional explicit list of builtin tools disabled for this subagent.
  final List<BuiltinTools>? disabledTools;

  /// Whitelist of allowed subagent names that this subagent is permitted to invoke.
  final List<String>? allowedSubagents;

  /// Backward compatibility alias for [agentBehavior].
  AgentBehavior get agentMode => agentBehavior;

  SubagentCapabilities({
    AgentBehavior? agentBehavior,
    AgentBehavior? agentMode,
    this.enabledTools,
    this.disabledTools,
    this.allowedSubagents,
  }) : agentBehavior = resolveAgentBehaviorAndWarn(
          agentBehavior: agentBehavior,
          agentMode: agentMode,
          enabledTools: enabledTools,
          targetName: 'SubagentCapabilities',
          logger: _subagentLogger,
        ) {
    if (enabledTools != null && disabledTools != null) {
      throw AntigravityValidationException(
        'enabledTools and disabledTools are mutually exclusive.',
      );
    }
    if (allowedSubagents != null && allowedSubagents!.isNotEmpty) {
      final hasStartSubagent = (enabledTools == null ||
              enabledTools!.contains(BuiltinTools.startSubagent)) &&
          (disabledTools == null ||
              !disabledTools!.contains(BuiltinTools.startSubagent));
      if (!hasStartSubagent) {
        throw AntigravityValidationException(
          'Cannot configure allowedSubagents when BuiltinTools.startSubagent is disabled for this subagent.',
        );
      }
    }
  }

  static const fromMap = SubagentCapabilitiesMapper.fromMap;
  static const fromJson = SubagentCapabilitiesMapper.fromJson;
}

const int _maxInt32 = 2147483647;
const int _maxInt64 = 9223372036854775807; // 0x7FFFFFFFFFFFFFFF

/// Configuration for session-level budget limits and caps.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class BudgetConfig with BudgetConfigMappable {
  /// Maximum number of model invocations (reasoning steps / generator calls) permitted across the session.
  final int? maxModelCalls;

  /// Maximum number of tool invocations permitted across the session, regardless of tool source.
  final int? maxToolCalls;

  /// Maximum net uncached input tokens permitted across the session (prompt tokens minus cached content tokens).
  final int? maxInputTokens;

  /// Maximum output tokens permitted across the session (candidates + thoughts).
  final int? maxOutputTokens;

  /// Maximum total net tokens permitted across the session (net uncached input tokens + output tokens).
  final int? maxTotalTokens;

  BudgetConfig({
    this.maxModelCalls,
    this.maxToolCalls,
    this.maxInputTokens,
    this.maxOutputTokens,
    this.maxTotalTokens,
  }) {
    _validateRange('maxModelCalls', maxModelCalls, 1, _maxInt32);
    _validateRange('maxToolCalls', maxToolCalls, 1, _maxInt32);
    _validateRange('maxInputTokens', maxInputTokens, 1, _maxInt64);
    _validateRange('maxOutputTokens', maxOutputTokens, 1, _maxInt64);
    _validateRange('maxTotalTokens', maxTotalTokens, 1, _maxInt64);
  }

  static void _validateRange(String name, int? value, int min, int max) {
    if (value != null && (value < min || value > max)) {
      throw AntigravityValidationException(
        '$name must be between $min and $max inclusive, got $value',
      );
    }
  }

  static const fromMap = BudgetConfigMapper.fromMap;
  static const fromJson = BudgetConfigMapper.fromJson;
}

/// Reason why the execution turn stopped.
@MappableEnum(defaultValue: StopReason.unspecified)
enum StopReason {
  @MappableValue('UNSPECIFIED')
  unspecified('UNSPECIFIED'),

  @MappableValue('MAX_MODEL_CALLS_EXCEEDED')
  maxModelCallsExceeded('MAX_MODEL_CALLS_EXCEEDED'),

  @MappableValue('MAX_TOOL_CALLS_EXCEEDED')
  maxToolCallsExceeded('MAX_TOOL_CALLS_EXCEEDED'),

  @MappableValue('MAX_INPUT_TOKENS_EXCEEDED')
  maxInputTokensExceeded('MAX_INPUT_TOKENS_EXCEEDED'),

  @MappableValue('MAX_OUTPUT_TOKENS_EXCEEDED')
  maxOutputTokensExceeded('MAX_OUTPUT_TOKENS_EXCEEDED'),

  @MappableValue('MAX_TOTAL_TOKENS_EXCEEDED')
  maxTotalTokensExceeded('MAX_TOTAL_TOKENS_EXCEEDED'),

  @MappableValue('QUOTA_EXHAUSTED')
  quotaExhausted('QUOTA_EXHAUSTED');

  final String value;
  const StopReason(this.value);

  /// Parses a [StopReason] from a string, supporting proto-prefixed wire strings
  /// (e.g. `STOP_REASON_MAX_MODEL_CALLS_EXCEEDED` or `MAX_MODEL_CALLS_EXCEEDED`).
  static StopReason fromString(String val) {
    final normalized =
        val.toUpperCase().trim().replaceFirst('STOP_REASON_', '');
    return switch (normalized) {
      'MAX_MODEL_CALLS_EXCEEDED' ||
      'MAXMODELCALLSEXCEEDED' =>
        StopReason.maxModelCallsExceeded,
      'MAX_TOOL_CALLS_EXCEEDED' ||
      'MAXTOOLCALLSEXCEEDED' =>
        StopReason.maxToolCallsExceeded,
      'MAX_INPUT_TOKENS_EXCEEDED' ||
      'MAXINPUTTOKENSEXCEEDED' =>
        StopReason.maxInputTokensExceeded,
      'MAX_OUTPUT_TOKENS_EXCEEDED' ||
      'MAXOUTPUTTOKENSEXCEEDED' =>
        StopReason.maxOutputTokensExceeded,
      'MAX_TOTAL_TOKENS_EXCEEDED' ||
      'MAXTOTALTOKENSEXCEEDED' =>
        StopReason.maxTotalTokensExceeded,
      'QUOTA_EXHAUSTED' || 'QUOTAEXHAUSTED' => StopReason.quotaExhausted,
      _ => StopReason.unspecified,
    };
  }
}

/// Configuration for a static subagent.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class SubagentConfig with SubagentConfigMappable {
  /// Unique identifier name of the subagent.
  final String name;

  /// Description of the subagent's role and purpose.
  final String description;

  /// Optional system instructions for the subagent.
  /// Accepts a [String], [SystemInstructions] ([CustomSystemInstructions] or [TemplatedSystemInstructions]),
  /// or `List<SystemInstructionSection>`.
  final dynamic systemInstructions;

  /// Optional capability configuration controlling enabled/disabled tools for this subagent.
  final SubagentCapabilities? capabilities;

  /// Optional list of additional custom tools (string names of tools registered
  /// on the main agent) to enable.
  final List<String> tools;

  SubagentConfig({
    required this.name,
    required this.description,
    this.systemInstructions,
    this.capabilities,
    List<String>? tools,
  }) : tools = tools ?? [];

  static const fromMap = SubagentConfigMapper.fromMap;
  static const fromJson = SubagentConfigMapper.fromJson;
}

/// Mode for establishing a connection to an agent session.
@MappableEnum(caseStyle: CaseStyle.upperCase)
enum SessionContinuationMode {
  /// Resume a previous conversation using its conversation identifier.
  ///
  /// Fails if the conversation cannot be found.
  @MappableValue('RESUME')
  resume('RESUME'),

  /// Resume a previous conversation if it exists, or create a new one.
  @MappableValue('CREATE_OR_RESUME')
  createOrResume('CREATE_OR_RESUME'),

  /// Always create a new conversation session.
  @MappableValue('CREATE_ONLY')
  createOnly('CREATE_ONLY'),

  /// Default unspecified fallback mode.
  @MappableValue('SESSION_CONTINUATION_MODE_UNSPECIFIED')
  unspecified('SESSION_CONTINUATION_MODE_UNSPECIFIED');

  final String value;
  const SessionContinuationMode(this.value);
}

/// Maximum value allowed for protobuf uint32 fields (2^32 - 1).
const int _maxUint32 = 4294967295;

/// Configuration for API retry behavior with exponential backoff.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ModelAPIRetryConfig with ModelAPIRetryConfigMappable {
  /// The maximum number of retries for transient API errors.
  final int? maxRetries;

  /// The initial sleep duration in milliseconds.
  final int? initialSleepDurationMs;

  /// The multiplier for exponential backoff.
  final double? exponentialMultiplier;

  /// The range for jitter when calculating backoff (as a ratio between 0.0 and 1.0, e.g. 0.2 = ±20%).
  final double? jitterRange;

  /// Returns the initial sleep duration as a strongly-typed Dart [Duration].
  Duration? get initialSleepDuration => initialSleepDurationMs != null
      ? Duration(milliseconds: initialSleepDurationMs!)
      : null;

  /// Creates a new [ModelAPIRetryConfig] instance.
  ///
  /// Can take either an integer [initialSleepDurationMs] or a Dart [Duration] [initialSleepDuration].
  ModelAPIRetryConfig({
    this.maxRetries,
    int? initialSleepDurationMs,
    Duration? initialSleepDuration,
    this.exponentialMultiplier,
    this.jitterRange,
  }) : initialSleepDurationMs =
            initialSleepDurationMs ?? initialSleepDuration?.inMilliseconds {
    if (maxRetries != null && (maxRetries! < 0 || maxRetries! > _maxUint32)) {
      throw AntigravityValidationException(
        'maxRetries must be between 0 and $_maxUint32 inclusive.',
      );
    }
    if (this.initialSleepDurationMs != null &&
        (this.initialSleepDurationMs! < 0 ||
            this.initialSleepDurationMs! > _maxUint32)) {
      throw AntigravityValidationException(
        'initialSleepDurationMs must be between 0 and $_maxUint32 inclusive.',
      );
    }
    if (exponentialMultiplier != null && exponentialMultiplier! < 0.0) {
      throw AntigravityValidationException(
        'exponentialMultiplier must be non-negative.',
      );
    }
    if (jitterRange != null && (jitterRange! < 0.0 || jitterRange! > 1.0)) {
      throw AntigravityValidationException(
        'jitterRange must be a ratio between 0.0 and 1.0 inclusive (e.g. 0.2 = 20% jitter).',
      );
    }
  }

  static const fromMap = ModelAPIRetryConfigMapper.fromMap;
  static const fromJson = ModelAPIRetryConfigMapper.fromJson;
}

/// Configuration for model output retry behavior.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ModelOutputRetryConfig with ModelOutputRetryConfigMappable {
  /// The maximum number of retries for malformed model outputs.
  final int? maxRetries;

  /// Creates a new [ModelOutputRetryConfig] instance.
  ModelOutputRetryConfig({this.maxRetries}) {
    if (maxRetries != null && (maxRetries! < 0 || maxRetries! > _maxUint32)) {
      throw AntigravityValidationException(
        'maxRetries must be between 0 and $_maxUint32 inclusive.',
      );
    }
  }

  static const fromMap = ModelOutputRetryConfigMapper.fromMap;
  static const fromJson = ModelOutputRetryConfigMapper.fromJson;
}

/// Combined retry configuration for model API calls and output validation.
///
/// When [retryConfig] is omitted (or fields are left as null), the backend
/// automatically applies built-in interactive defaults.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class RetryConfig with RetryConfigMappable {
  /// Optional configuration for API retry behavior with exponential backoff.
  final ModelAPIRetryConfig? apiRetry;

  /// Optional configuration for model output retry behavior.
  final ModelOutputRetryConfig? modelOutputRetry;

  /// Creates a new [RetryConfig] instance.
  RetryConfig({this.apiRetry, this.modelOutputRetry});

  /// Optimized for evaluation suites, automated benchmarks, and load testing.
  ///
  /// Uses unbounded retry tolerance (max uint32: 4,294,967,295 attempts) for
  /// transient API errors (429 rate limits, 503 service throttling).
  factory RetryConfig.benchmark() {
    return RetryConfig(
      apiRetry: ModelAPIRetryConfig(
        maxRetries: _maxUint32,
        initialSleepDurationMs: 1000,
      ),
    );
  }

  static const fromMap = RetryConfigMapper.fromMap;
  static const fromJson = RetryConfigMapper.fromJson;
}
