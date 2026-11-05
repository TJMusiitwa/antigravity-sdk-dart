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
  /// List directory contents. Deprecated and disabled by default.
  @MappableValue('list_directory')
  listDirectory('list_directory'),

  /// Search within directories (grep). Deprecated and disabled by default.
  @MappableValue('search_directory')
  searchDirectory('search_directory'),

  /// Find files by name within a directory. Deprecated and disabled by
  /// default.
  @MappableValue('find_file')
  findFile('find_file'),

  /// View file contents.
  @MappableValue('view_file')
  viewFile('view_file'),

  /// Create a new file.
  @MappableValue('create_file')
  createFile('create_file'),

  /// Edit an existing file.
  @MappableValue('edit_file')
  editFile('edit_file'),

  /// Execute a shell command.
  @MappableValue('run_command')
  runCommand('run_command'),

  /// Ask the user a clarifying question.
  @MappableValue('ask_question')
  askQuestion('ask_question'),

  /// Invoke a subagent.
  @MappableValue('invoke_subagent')
  invokeSubagent('invoke_subagent'),

  /// Execute a multi-agent workflow script.
  @MappableValue('run_workflow')
  runWorkflow('run_workflow'),

  /// Generate or edit images.
  @MappableValue('generate_image')
  generateImage('generate_image'),

  /// Search the web.
  @MappableValue('search_web')
  searchWeb('search_web'),

  /// Read content from a URL.
  @MappableValue('read_url_content')
  readUrlContent('read_url_content'),

  /// Schedule a one-shot timer or recurring cron job.
  @MappableValue('schedule')
  schedule('schedule'),

  /// Finish the conversation and return structured output.
  @MappableValue('finish')
  finish('finish');

  /// Wire name of the tool, such as `view_file`.
  final String value;
  const BuiltinTools(this.value);

  /// Deprecated alias for [invokeSubagent].
  @Deprecated('Use BuiltinTools.invokeSubagent instead.')
  static const BuiltinTools startSubagent = invokeSubagent;

  /// Resolves a builtin tool from its wire [value].
  ///
  /// The deprecated `start_subagent` spelling is coerced to [invokeSubagent]
  /// with a warning. Throws [ArgumentError] for unknown values.
  static BuiltinTools fromValue(String value) {
    if (value == deprecatedStartSubagentToolName) {
      _logger.warning(
        "'$deprecatedStartSubagentToolName' is deprecated; use "
        "'${invokeSubagent.value}' instead.",
      );
      return invokeSubagent;
    }
    for (final tool in values) {
      if (tool.value == value) return tool;
    }
    throw ArgumentError.value(value, 'value', 'Unknown builtin tool');
  }

  @override
  String toString() => value;

  /// Returns the default set of builtin tools for autonomous agents.
  ///
  /// Excludes [askQuestion] (autonomous agents cannot prompt the user) and the
  /// deprecated tools in [deprecated] (`list_directory`, `search_directory`,
  /// and `find_file`, which are off by default). To enable any of those, pass
  /// them explicitly in [CapabilitiesConfig.enabledTools].
  static List<BuiltinTools> defaultTools() {
    final excluded = {askQuestion, ...deprecated()};
    return BuiltinTools.values.where((t) => !excluded.contains(t)).toList();
  }

  /// Returns the default read-only tools.
  ///
  /// Excludes [listDirectory], [searchDirectory], and [findFile], which are
  /// disabled by default. See [deprecated].
  static List<BuiltinTools> readOnly() {
    return [viewFile, readUrlContent, schedule, finish];
  }

  /// Returns the default non-destructive tools.
  ///
  /// Excludes [listDirectory], [searchDirectory], and [findFile], which are
  /// disabled by default. See [deprecated].
  static List<BuiltinTools> nondestructive() {
    return [
      viewFile,
      createFile,
      editFile,
      askQuestion,
      invokeSubagent,
      runWorkflow,
      generateImage,
      searchWeb,
      readUrlContent,
      schedule,
      finish,
    ];
  }

  /// A minimal set of tools sufficient for basic file and command work.
  ///
  /// Includes `run_command`, `view_file`, `create_file`, and `edit_file`.
  static List<BuiltinTools> minimal() {
    return [runCommand, viewFile, createFile, editFile];
  }

  /// Returns deprecated builtin tools that are disabled by default.
  ///
  /// Includes [listDirectory], [searchDirectory], and [findFile]. These are
  /// excluded from [defaultTools], [readOnly], [nondestructive], and [minimal],
  /// and are only enabled when explicitly requested via
  /// [CapabilitiesConfig.enabledTools].
  static List<BuiltinTools> deprecated() {
    return [listDirectory, searchDirectory, findFile];
  }

  /// Returns the file tools: [viewFile], [createFile], and [editFile].
  static List<BuiltinTools> fileTools() {
    return [viewFile, createFile, editFile];
  }

  /// Returns every builtin tool, including the [deprecated] ones.
  static List<BuiltinTools> allTools() {
    return BuiltinTools.values;
  }
}

/// Deprecated wire spelling of [BuiltinTools.invokeSubagent].
const String deprecatedStartSubagentToolName = 'start_subagent';

/// Normalizes deprecated builtin tool name aliases.
///
/// Returns `invoke_subagent` for `start_subagent` unless [serverName] is set,
/// in which case the name belongs to an MCP server and is returned unchanged.
String normalizeBuiltinToolName(String name, {String? serverName}) {
  if (name == deprecatedStartSubagentToolName &&
      (serverName == null || serverName.isEmpty)) {
    return BuiltinTools.invokeSubagent.value;
  }
  return name;
}

/// Coerces deprecated tool spellings in a serialized builtin tool list.
///
/// Lets `fromMap`/`fromJson` accept `start_subagent` for
/// [BuiltinTools.invokeSubagent].
class BuiltinToolListHook extends MappingHook {
  /// Creates a [BuiltinToolListHook].
  const BuiltinToolListHook();

  @override
  Object? beforeDecode(Object? value) {
    if (value is! List) return value;
    return [
      for (final item in value)
        item is String ? BuiltinTools.fromValue(item).value : item,
    ];
  }
}

/// Operational execution behavior for an agent or subagent.
@MappableEnum(defaultValue: AgentBehavior.autonomous)
enum AgentBehavior {
  /// Non-interactive, automated execution: the agent must accomplish the task
  /// on its own.
  autonomous('autonomous'),

  /// Collaborative execution with a human: the agent asks for clarifications
  /// and keeps the user in the loop when needed.
  interactive('interactive'),

  /// Minimal behavior: reduced tool surface and low-overhead execution.
  @MappableValue('minimal')
  minimal('minimal');

  /// Wire value of the behavior, such as `autonomous`.
  final String value;
  const AgentBehavior(this.value);

  /// Returns the corresponding Protobuf enum string value.
  String get protoValue => 'AGENT_BEHAVIOR_${value.toUpperCase()}';

  /// Parses an [AgentBehavior] from its wire value [val].
  ///
  /// Returns [autonomous] when [val] is not recognized.
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

  /// Creates a [RunCommandConfig].
  ///
  /// Throws an [AntigravityValidationException] if [timeoutSeconds] is not
  /// greater than 0.
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

  /// Decodes a [RunCommandConfig] from a map.
  factory RunCommandConfig.fromMap(Map<String, dynamic> map) =>
      RunCommandConfigMapper.fromMap(map);

  /// Decodes a [RunCommandConfig] from a JSON string.
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

  /// Creates a [ToolOutputTruncationConfig] with the given [maxTokens].
  ///
  /// Throws an [AntigravityValidationException] if [maxTokens] is negative or
  /// greater than 2147483647.
  ToolOutputTruncationConfig({required this.maxTokens}) {
    if (maxTokens < 0 || maxTokens > _maxInt32) {
      throw AntigravityValidationException(
        'maxTokens must be between 0 and $_maxInt32 inclusive, got $maxTokens',
      );
    }
  }

  /// Decodes a [ToolOutputTruncationConfig] from a map.
  factory ToolOutputTruncationConfig.fromMap(Map<String, dynamic> map) =>
      ToolOutputTruncationConfigMapper.fromMap(map);

  /// Decodes a [ToolOutputTruncationConfig] from a JSON string.
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
  /// [disabledTools]. When null, the harness defaults are used (all tools
  /// except [BuiltinTools.askQuestion] and the [BuiltinTools.deprecated] tools
  /// [BuiltinTools.listDirectory], [BuiltinTools.searchDirectory], and
  /// [BuiltinTools.findFile]; see [BuiltinTools.defaultTools]). Disabled tools
  /// are removed from the model's context, saving tokens and preventing the
  /// model from even considering them.
  @MappableField(hook: BuiltinToolListHook())
  final List<BuiltinTools>? enabledTools;

  /// Explicit denylist of builtin tools to disable. Mutually exclusive with
  /// [enabledTools]. When specified, the given tools are subtracted from
  /// [BuiltinTools.defaultTools] (which already excludes
  /// [BuiltinTools.askQuestion], [BuiltinTools.listDirectory],
  /// [BuiltinTools.searchDirectory], and [BuiltinTools.findFile]). When null,
  /// all default tools are enabled. To enable any of those, include them
  /// explicitly in [enabledTools].
  @MappableField(hook: BuiltinToolListHook())
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

  /// Maximum size in bytes of an MCP tool output or resource read before the
  /// runtime spills the output to a file on disk instead of inlining it in the
  /// model context.
  ///
  /// Must be in `(0, 2147483647]` when specified. When null, the runtime's
  /// default limit (4096 bytes) is used.
  final int? mcpMaxOutputBytes;

  /// Backward compatibility alias for [agentBehavior].
  AgentBehavior get agentMode => agentBehavior;

  /// Creates a [CapabilitiesConfig].
  ///
  /// [agentMode] is a backward compatibility alias for [agentBehavior], which
  /// takes precedence when both are set. [agentBehavior] defaults to
  /// [AgentBehavior.autonomous].
  ///
  /// Throws an [AntigravityValidationException] if both [enabledTools] and
  /// [disabledTools] are set, if a numeric limit is out of range, or if
  /// [maxSubagentDepth] or [allowedSubagents] is set while subagents are
  /// disabled.
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
    this.mcpMaxOutputBytes,
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
    final mcpBytes = mcpMaxOutputBytes;
    if (mcpBytes != null && (mcpBytes <= 0 || mcpBytes > _maxInt32)) {
      throw AntigravityValidationException(
        'mcpMaxOutputBytes must be greater than 0 and at most $_maxInt32, '
        'got $mcpBytes',
      );
    }
    if (maxSubagentDepth != null && maxSubagentDepth! < 1) {
      throw AntigravityValidationException(
        'maxSubagentDepth must be greater than or equal to 1, got $maxSubagentDepth',
      );
    }
    final subagentDisabled =
        !enableSubagents ||
        (disabledTools != null &&
            disabledTools!.contains(BuiltinTools.invokeSubagent) &&
            disabledTools!.contains(BuiltinTools.runWorkflow)) ||
        (enabledTools != null &&
            !enabledTools!.contains(BuiltinTools.invokeSubagent) &&
            !enabledTools!.contains(BuiltinTools.runWorkflow));
    if (subagentDisabled) {
      if (maxSubagentDepth != null) {
        throw AntigravityValidationException(
          'maxSubagentDepth cannot be configured when subagents are disabled '
          '(enableSubagents=false or both invokeSubagent and runWorkflow disabled).',
        );
      }
      if (allowedSubagents != null) {
        throw AntigravityValidationException(
          'allowedSubagents cannot be specified when subagents are disabled.',
        );
      }
    }
  }

  /// Decodes a [CapabilitiesConfig] from a map.
  factory CapabilitiesConfig.fromMap(Map<String, dynamic> map) =>
      CapabilitiesConfigMapper.fromMap(map);

  /// Decodes a [CapabilitiesConfig] from a JSON string.
  factory CapabilitiesConfig.fromJson(String json) =>
      CapabilitiesConfigMapper.fromJson(json);
}
