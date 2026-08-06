import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';

import 'capabilities.dart';
import 'exceptions.dart';

part 'config.mapper.dart';

final _subagentLogger = Logger('antigravity.subagent');

/// Capabilities configuration for subagents.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class SubagentCapabilities with SubagentCapabilitiesMappable {
  final AgentMode agentMode;
  final List<BuiltinTools>? enabledTools;
  final List<BuiltinTools>? disabledTools;

  SubagentCapabilities({
    this.agentMode = AgentMode.autonomous,
    this.enabledTools,
    this.disabledTools,
  }) {
    if (enabledTools != null && disabledTools != null) {
      throw ArgumentError(
        'enabledTools and disabledTools should be mutually exclusive.',
      );
    }
    if (enabledTools != null &&
        enabledTools!.contains(BuiltinTools.askQuestion) &&
        agentMode != AgentMode.interactive) {
      _subagentLogger.warning(
        'BuiltinTools.askQuestion is enabled on subagent, but agentMode is not '
        'INTERACTIVE. Set SubagentCapabilities(agentMode: AgentMode.interactive) '
        'if interactive question-and-answer behavior is desired.',
      );
    }
  }

  static const fromMap = SubagentCapabilitiesMapper.fromMap;
  static const fromJson = SubagentCapabilitiesMapper.fromJson;
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
