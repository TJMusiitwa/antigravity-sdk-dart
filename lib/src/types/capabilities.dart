import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';
import 'exceptions.dart';

part 'capabilities.mapper.dart';

final _logger = Logger('antigravity.capabilities');

/// Maximum value for protobuf int32 wire fields.
const int _maxInt32 = 2147483647; // 2^31 - 1

/// Identifiers for common connection-provided builtin tools.
@MappableEnum()
enum BuiltinTools {
  @MappableValue('list_directory')
  listDirectory('list_directory'),
  @MappableValue('search_directory')
  searchDirectory('search_directory'),
  @MappableValue('find_file')
  findFile('find_file'),
  @MappableValue('view_file')
  viewFile('view_file'),
  @MappableValue('create_file')
  createFile('create_file'),
  @MappableValue('edit_file')
  editFile('edit_file'),
  @MappableValue('run_command')
  runCommand('run_command'),
  @MappableValue('ask_question')
  askQuestion('ask_question'),
  @MappableValue('start_subagent')
  startSubagent('start_subagent'),
  @MappableValue('generate_image')
  generateImage('generate_image'),
  @MappableValue('search_web')
  searchWeb('search_web'),
  @MappableValue('read_url_content')
  readUrlContent('read_url_content'),
  @MappableValue('finish')
  finish('finish');

  final String value;
  const BuiltinTools(this.value);

  /// Returns the default set of builtin tools for autonomous agents.
  ///
  /// Excludes [askQuestion] because autonomous agents cannot prompt the user.
  /// To enable [askQuestion], it must be explicitly included in
  /// [CapabilitiesConfig.enabledTools].
  static List<BuiltinTools> defaultTools() {
    return BuiltinTools.values
        .where((t) => t != BuiltinTools.askQuestion)
        .toList();
  }

  static List<BuiltinTools> readOnly() {
    return [
      listDirectory,
      searchDirectory,
      findFile,
      viewFile,
      readUrlContent,
      finish
    ];
  }

  static List<BuiltinTools> nondestructive() {
    return [
      listDirectory,
      searchDirectory,
      findFile,
      viewFile,
      createFile,
      editFile,
      askQuestion,
      startSubagent,
      generateImage,
      searchWeb,
      readUrlContent,
      finish,
    ];
  }

  /// A minimal set of tools sufficient for basic file and command work.
  static List<BuiltinTools> minimal() {
    return [
      runCommand,
      viewFile,
      createFile,
      editFile,
      listDirectory,
      searchDirectory,
    ];
  }

  static List<BuiltinTools> fileTools() {
    return [viewFile, createFile, editFile];
  }

  static List<BuiltinTools> allTools() {
    return BuiltinTools.values;
  }
}

/// Operational execution behavior for an agent or subagent.
@MappableEnum(defaultValue: AgentBehavior.autonomous)
enum AgentBehavior {
  autonomous('autonomous'),
  interactive('interactive'),

  /// Minimal behavior: reduced tool surface and low-overhead execution.
  @MappableValue('minimal')
  minimal('minimal');

  final String value;
  const AgentBehavior(this.value);

  /// Returns the corresponding Protobuf enum string value.
  String get protoValue => 'AGENT_BEHAVIOR_${value.toUpperCase()}';

  static AgentBehavior fromString(String val) {
    try {
      return AgentBehaviorMapper.fromValue(val);
    } catch (_) {
      return AgentBehavior.autonomous;
    }
  }
}

/// Helper to resolve [AgentBehavior] from new/legacy parameters and log a warning if interactive tools are enabled without interactive mode.
AgentBehavior resolveAgentBehaviorAndWarn({
  AgentBehavior? agentBehavior,
  AgentBehavior? agentMode,
  List<BuiltinTools>? enabledTools,
  required String targetName,
  required Logger logger,
}) {
  final behavior = agentBehavior ?? agentMode ?? AgentBehavior.autonomous;
  if (enabledTools != null &&
      enabledTools.contains(BuiltinTools.askQuestion) &&
      behavior != AgentBehavior.interactive) {
    logger.warning(
      'BuiltinTools.askQuestion is enabled on $targetName, but agentBehavior is not '
      'INTERACTIVE. Set $targetName(agentBehavior: AgentBehavior.interactive) '
      'if interactive question-and-answer behavior is desired.',
    );
  }
  return behavior;
}

/// Backward compatibility alias for [AgentBehavior].
typedef AgentMode = AgentBehavior;

/// Configuration for the builtin run_command tool.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class RunCommandConfig with RunCommandConfigMappable {
  /// Whether the agent is authorized to start long-running daemon commands
  /// (e.g. background dev servers, watchers) using run_command(IsDaemon=true)
  /// without blocking session completion. When true, the IsDaemon argument is
  /// exposed on the run_command tool schema. Defaults to false.
  final bool enableDaemons;

  /// Maximum execution duration in seconds for commands.
  /// When null, the default timeout (10 minutes) is used. Defaults to null.
  final double? timeoutSeconds;

  /// When true, terminal commands (run_command) are executed inside the
  /// OS-level sandbox (exebox). Forwarded to the harness/cortex, which
  /// enforces the sandbox at command execution time. Has no effect on
  /// platforms/environments where the sandbox is unavailable. Defaults to false.
  final bool enableSandbox;

  RunCommandConfig({
    this.enableDaemons = false,
    this.timeoutSeconds,
    this.enableSandbox = false,
  }) {
    if (timeoutSeconds != null && timeoutSeconds! <= 0) {
      throw AntigravityValidationException(
        'timeoutSeconds must be greater than 0, got $timeoutSeconds',
      );
    }
  }

  factory RunCommandConfig.fromMap(Map<String, dynamic> map) =>
      RunCommandConfigMapper.fromMap(map);
  factory RunCommandConfig.fromJson(String json) =>
      RunCommandConfigMapper.fromJson(json);
}

/// Configuration for truncating large tool outputs.
///
/// When a tool's output exceeds [maxTokens], the harness preserves the
/// beginning (prefix) of the output up to the limit and truncates the
/// remainder (tail), appending a notice informing the model that the output
/// was truncated.
///
/// Example:
/// ```dart
/// final config = ToolOutputTruncationConfig(maxTokens: 2048);
/// ```
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ToolOutputTruncationConfig with ToolOutputTruncationConfigMappable {
  /// Maximum number of estimated tokens for a single tool response.
  ///
  /// Must be non-negative. Preserves the beginning (prefix) of the tool
  /// response and truncates the end (tail). Setting to 0 explicitly disables
  /// truncation.
  final int maxTokens;

  ToolOutputTruncationConfig({required this.maxTokens}) {
    if (maxTokens < 0 || maxTokens > _maxInt32) {
      throw AntigravityValidationException(
        'maxTokens must be between 0 and $_maxInt32 inclusive, got $maxTokens',
      );
    }
  }

  factory ToolOutputTruncationConfig.fromMap(Map<String, dynamic> map) =>
      ToolOutputTruncationConfigMapper.fromMap(map);
  factory ToolOutputTruncationConfig.fromJson(String json) =>
      ToolOutputTruncationConfigMapper.fromJson(json);
}

/// General agent capability configuration.
///
/// **Disabling vs. Denying Tools:**
///
/// [enabledTools] / [disabledTools] control which tools the harness *exposes*
/// to the model. A disabled tool is stripped from the model's context entirely —
/// the model never sees it, never wastes tokens considering it, and never
/// attempts to call it. Use these fields when a tool is irrelevant to the
/// agent's purpose.
///
/// By contrast, the policy system leaves a tool visible in the model's context
/// but rejects the call at runtime. The model may still attempt to invoke a
/// policy-denied tool, at which point the SDK returns a denial message. This
/// costs tokens and may cause retries, but allows the model to understand *why*
/// access was refused.
///
/// **Guideline**: Prefer [disabledTools] / [enabledTools] for tools the agent
/// should never use. Use `policy.deny()` for conditional restrictions.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class CapabilitiesConfig with CapabilitiesConfigMappable {
  /// Whether subagent spawning is enabled for this agent.
  final bool enableSubagents;

  /// The execution behavior of the agent (e.g. autonomous or interactive).
  final AgentBehavior agentBehavior;

  /// Explicit allowlist of builtin tools to enable. Mutually exclusive with
  /// [disabledTools]. When null, all tools enabled except [BuiltinTools.askQuestion]
  /// (see [BuiltinTools.defaultTools]). Disabled tools are removed from the
  /// model's context, saving tokens and preventing the model from even
  /// considering them.
  final List<BuiltinTools>? enabledTools;

  /// Explicit denylist of builtin tools to disable. Mutually exclusive with
  /// [enabledTools]. When specified, the given tools are subtracted from
  /// [BuiltinTools.defaultTools] (which already excludes [BuiltinTools.askQuestion]).
  /// When null, all default tools are enabled. Note that to enable
  /// [BuiltinTools.askQuestion], it must be explicitly included in [enabledTools].
  final List<BuiltinTools>? disabledTools;

  /// Maximum message compaction threshold before historical turns are summarized.
  ///
  /// **Deprecated:** Configure `CompactionConfig(tokenThreshold: ...)` directly
  /// on `AgentConfig` instead.
  @Deprecated(
    'Use CompactionConfig(tokenThreshold: ...) directly on AgentConfig instead',
  )
  final int? compactionThreshold;

  /// Custom finish tool JSON schema definition.
  String? finishToolSchemaJson;

  /// Maximum allowed nesting depth for subagent invocations (must be >= 1).
  final int? maxSubagentDepth;

  /// Whitelist of allowed static subagent names that this agent is permitted to invoke.
  final List<String>? allowedSubagents;

  /// Optional configuration for the builtin run_command tool.
  final RunCommandConfig? runCommandConfig;

  /// Optional configuration for truncating large tool outputs.
  ///
  /// Preserves the beginning (prefix) of the response and truncates the end.
  /// Can be specified as a [ToolOutputTruncationConfig] object.
  final ToolOutputTruncationConfig? toolOutputTruncationConfig;

  /// Backward compatibility alias for [agentBehavior].
  AgentBehavior get agentMode => agentBehavior;

  CapabilitiesConfig({
    this.enableSubagents = true,
    AgentBehavior? agentBehavior,
    AgentBehavior? agentMode,
    this.enabledTools,
    this.disabledTools,
    this.compactionThreshold,
    this.finishToolSchemaJson,
    this.maxSubagentDepth,
    this.allowedSubagents,
    this.runCommandConfig,
    this.toolOutputTruncationConfig,
  }) : agentBehavior = resolveAgentBehaviorAndWarn(
          agentBehavior: agentBehavior,
          agentMode: agentMode,
          enabledTools: enabledTools,
          targetName: 'CapabilitiesConfig',
          logger: _logger,
        ) {
    if (enabledTools != null && disabledTools != null) {
      throw AntigravityValidationException(
        'enabledTools and disabledTools are mutually exclusive.',
      );
    }
    // ignore: deprecated_member_use_from_same_package
    final threshold = compactionThreshold;
    if (threshold != null) {
      if (threshold <= 0) {
        throw AntigravityValidationException(
          'compactionThreshold must be greater than 0, got $threshold',
        );
      }
      _logger.warning(
        'CapabilitiesConfig.compactionThreshold is deprecated. Configure '
        'CompactionConfig(tokenThreshold: ...) directly on AgentConfig instead.',
      );
    }
    if (maxSubagentDepth != null && maxSubagentDepth! < 1) {
      throw AntigravityValidationException(
        'maxSubagentDepth must be greater than or equal to 1, got $maxSubagentDepth',
      );
    }
    final subagentDisabled = !enableSubagents ||
        (disabledTools != null &&
            disabledTools!.contains(BuiltinTools.startSubagent)) ||
        (enabledTools != null &&
            !enabledTools!.contains(BuiltinTools.startSubagent));
    if (subagentDisabled) {
      if (maxSubagentDepth != null) {
        throw AntigravityValidationException(
          'maxSubagentDepth cannot be configured when subagents are disabled '
          '(enableSubagents=false or startSubagent not enabled).',
        );
      }
      if (allowedSubagents != null) {
        throw AntigravityValidationException(
          'allowedSubagents cannot be specified when subagents are disabled.',
        );
      }
    }
  }

  factory CapabilitiesConfig.fromMap(Map<String, dynamic> map) =>
      CapabilitiesConfigMapper.fromMap(map);
  factory CapabilitiesConfig.fromJson(String json) =>
      CapabilitiesConfigMapper.fromJson(json);
}
