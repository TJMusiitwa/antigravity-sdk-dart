import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';
import 'exceptions.dart';

part 'capabilities.mapper.dart';

final _logger = Logger('antigravity.capabilities');

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
  interactive('interactive');

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

  RunCommandConfig({
    this.enableDaemons = false,
    this.timeoutSeconds,
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

/// General agent capability configuration.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class CapabilitiesConfig with CapabilitiesConfigMappable {
  /// Whether subagent spawning is enabled for this agent.
  final bool enableSubagents;

  /// The execution behavior of the agent (e.g. autonomous or interactive).
  final AgentBehavior agentBehavior;

  /// Optional explicit list of builtin tools to enable.
  final List<BuiltinTools>? enabledTools;

  /// Optional explicit list of builtin tools to disable.
  final List<BuiltinTools>? disabledTools;

  /// Maximum message compaction threshold before historical turns are summarized.
  final int? compactionThreshold;

  /// Custom finish tool JSON schema definition.
  String? finishToolSchemaJson;

  /// Maximum allowed nesting depth for subagent invocations (must be >= 1).
  final int? maxSubagentDepth;

  /// Whitelist of allowed static subagent names that this agent is permitted to invoke.
  final List<String>? allowedSubagents;

  /// Optional configuration for the builtin run_command tool.
  final RunCommandConfig? runCommandConfig;

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
