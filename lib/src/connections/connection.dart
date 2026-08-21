import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:logging/logging.dart';

import '../hooks/hooks.dart';
import '../hooks/policy.dart';
import '../tools/tool_runner.dart';
import '../triggers/triggers.dart';
import '../types.dart';

part 'connection.mapper.dart';

/// Configuration schema for setting up an [Agent] in the Google Antigravity SDK.
///
/// This abstract class acts as the common data contract for setting up the agent's
/// capabilities, registered tools, security policies, triggers, workspaces,
/// and backend sessions.
@MappableClass(
  includeCustomMappers: [
    ToolMapper(),
    PolicyMapper(),
    HookMapper(),
    TriggerMapper(),
    LevelMapper(),
  ],
)
abstract class AgentConfig with AgentConfigMappable {
  /// The system instructions to steer the agent's behavior.
  /// Can be either a [String] or [SystemInstructions].
  final dynamic systemInstructions; // String or SystemInstructions

  /// Configuration of the agent's tools, compaction, and subagent capabilities.
  final CapabilitiesConfig capabilities;

  /// Custom tools available to the agent.
  final List<Tool> tools;

  /// Security and permission enforcement policies.
  final List<Policy> policies;

  /// Lifecycle hooks that intercept turn and tool events.
  final List<Hook> hooks;

  /// Background triggers that execute asynchronously.
  final List<Trigger> triggers;

  /// List of Server configurations using the Model Context Protocol (MCP).
  final List<McpServerConfig> mcpServers;

  /// List of statically configured subagents available to the agent.
  final List<SubagentConfig> subagents;

  /// Root directories representing the workspaces the agent is allowed to access.
  final List<String> workspaces;

  /// The active conversation identifier, if resuming a previous session.
  final String? conversationId;

  /// The mode for establishing a connection to an agent session.
  final SessionContinuationMode? sessionContinuationMode;

  /// The directory where the agent's persistent state is saved.
  final String? saveDir;

  /// The directory for local application data, such as downloaded harness binaries.
  final String? appDataDir;

  /// The JSON Schema targeting the structured response format of the finish tool.
  final dynamic responseSchema; // String, Map, or other schema formats

  /// Paths containing reusable agent skills.
  final List<String> skillsPaths;

  /// Optional debug configuration for debugging and observability.
  final DebugConfig? debugConfig;

  /// Optional retry configuration for model API calls and output validation.
  final RetryConfig? retryConfig;

  /// Optional budget configuration for session-level caps on model/tool calls and tokens.
  final BudgetConfig? budgetConfig;

  AgentConfig({
    this.systemInstructions,
    CapabilitiesConfig? capabilities,
    List<Tool>? tools,
    List<dynamic>? policies,
    List<Hook>? hooks,
    List<Trigger>? triggers,
    List<McpServerConfig>? mcpServers,
    List<SubagentConfig>? subagents,
    List<String>? workspaces,
    this.conversationId,
    this.sessionContinuationMode,
    this.saveDir,
    this.appDataDir,
    this.responseSchema,
    List<String>? skillsPaths,
    this.debugConfig,
    this.retryConfig,
    this.budgetConfig,
  })  : capabilities = capabilities ??
            CapabilitiesConfig(enabledTools: BuiltinTools.readOnly()),
        tools = tools ?? const [],
        policies = flattenPolicies(policies ?? const []),
        hooks = hooks ?? const [],
        triggers = triggers ?? const [],
        mcpServers = mcpServers ?? const [],
        subagents = subagents ?? const [],
        workspaces = workspaces ?? const [],
        skillsPaths = skillsPaths ?? const [] {
    if (conversationId != null) {
      if (conversationId!.length < 32) {
        throw AntigravityValidationException(
          'conversationId must be at least 32 characters long, got ${conversationId!.length}',
        );
      }
      if (!RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(conversationId!)) {
        throw AntigravityValidationException(
          "conversationId must match [a-zA-Z0-9-], got '$conversationId'",
        );
      }
    }
    if (sessionContinuationMode == SessionContinuationMode.resume &&
        conversationId == null) {
      throw AntigravityValidationException(
        'conversationId must be specified when sessionContinuationMode is RESUME',
      );
    }
  }

  /// Creates the [ConnectionStrategy] for this configuration.
  ///
  /// Takes a [toolRunner] to handle tool executions and a [hookRunner] to
  /// coordinate lifecycle hooks.
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  });
}

/// A live session with an agent backend in the Google Antigravity SDK.
///
/// This is the common contract that all connection types implement.
abstract interface class Connection {
  /// Returns the current conversation identifier.
  String get conversationId;

  /// Returns the pre-existing session steps restored during handshake.
  List<Step> get initialHistory => const [];

  /// Returns total cumulative token usage reported by the connection.
  UsageMetadata get cumulativeUsage => UsageMetadata();

  /// Returns per-trajectory cumulative token usage reported by the connection.
  Map<String, UsageMetadata> get trajectoryUsages => const {};

  /// Returns the reason why the most recent turn stopped.
  StopReason get lastTurnStopReason => StopReason.unspecified;

  /// Returns true if the session is idle (waiting for user input or periodic task).
  bool get isIdle;

  /// Sends user prompt or media content to the agent.
  Future<void> send(ContentPrimitive? prompt, {Map<String, dynamic>? kwargs});

  /// Returns a stream of processing steps from the agent.
  Stream<Step> receiveSteps();

  /// Sends tool execution results back to the agent backend.
  Future<void> sendToolResults(List<ToolResult> results);

  /// Sends an out-of-band notification (e.g. background trigger) to the backend.
  Future<void> sendTriggerNotification(String content);

  /// Gracefully cancels the current model run without disconnecting the session.
  Future<void> cancel();

  /// Terminates the session and kills any backend processes.
  Future<void> disconnect();

  /// Deletes this connection and any persistent state on the backend.
  Future<void> delete();

  /// Signals that the connection has entered an idle state.
  void signalIdle();

  /// Blocks until the connection operates and then returns to an idle state.
  Future<void> waitForIdle();

  /// Blocks until the connection is woken up, or until [timeout] is exceeded.
  Future<bool> waitForWakeup({double timeout});
}

/// Abstract strategy for establishing a [Connection] in the Google Antigravity SDK.
abstract interface class ConnectionStrategy {
  /// Returns the debug configuration for this strategy, or null if disabled.
  DebugConfig? get debugConfig;

  /// Performs the setup and handshake (async).
  Future<void> start();

  /// Returns the established [Connection].
  Connection connect();

  /// Cleans up the strategy.
  Future<void> stop();
}

/// Mapper helper to map [Tool] objects for serialization.
class ToolMapper extends SimpleMapper<Tool> {
  /// Creates a new [ToolMapper] instance.
  const ToolMapper();
  @override
  Tool decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Tool value) => throw UnimplementedError();
}

/// Mapper helper to map [Policy] objects for serialization.
class PolicyMapper extends SimpleMapper<Policy> {
  /// Creates a new [PolicyMapper] instance.
  const PolicyMapper();
  @override
  Policy decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Policy value) => throw UnimplementedError();
}

/// Mapper helper to map [Hook] objects for serialization.
class HookMapper extends SimpleMapper<Hook> {
  /// Creates a new [HookMapper] instance.
  const HookMapper();
  @override
  Hook decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Hook value) => throw UnimplementedError();
}

/// Mapper helper to map [Trigger] objects for serialization.
class TriggerMapper extends SimpleMapper<Trigger> {
  /// Creates a new [TriggerMapper] instance.
  const TriggerMapper();
  @override
  Trigger decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Trigger value) => throw UnimplementedError();
}

/// Mapper helper to map [Level] objects for serialization.
class LevelMapper extends SimpleMapper<Level> {
  /// Creates a new [LevelMapper] instance.
  const LevelMapper();
  @override
  Level decode(dynamic value) {
    if (value is Level) return value;
    if (value is String) {
      final upper = value.toUpperCase();
      return Level.LEVELS.firstWhere(
        (l) => l.name == upper,
        orElse: () => Level(value, 0),
      );
    }
    return Level.INFO;
  }

  @override
  dynamic encode(Level value) => value.name;
}

/// Configuration for client-side and server-side debugging and observability.
@MappableClass(
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
  includeCustomMappers: [LevelMapper()],
)
class DebugConfig with DebugConfigMappable {
  /// Whether to enable server-side distributed tracing in the backend.
  final bool enableServerSideTracing;

  /// Logging level string or instance to apply across SDK modules.
  final String? loggingLevel;

  /// Strongly-typed Dart [Level] corresponding to [loggingLevel].
  Level? get level {
    if (loggingLevel == null) return null;
    final levelName = loggingLevel!.toUpperCase();
    return Level.LEVELS.firstWhere(
      (l) => l.name == levelName,
      orElse: () => throw AntigravityValidationException(
        "Unknown logging level '$loggingLevel'. Expected one of: ${Level.LEVELS.map((l) => l.name).join(', ')}.",
      ),
    );
  }

  /// Creates a new [DebugConfig] instance.
  ///
  /// Accepts either a string [loggingLevel] ('FINE', 'INFO') or a strongly-typed Dart [Level] ([level]).
  DebugConfig({
    this.enableServerSideTracing = true,
    dynamic loggingLevel = 'FINE',
    Level? level,
  }) : loggingLevel = level != null
            ? level.name
            : (loggingLevel is Level
                ? loggingLevel.name
                : loggingLevel as String?);

  /// Applies the configured logging level to SDK loggers.
  void applyLogging() {
    final targetLevel = level;
    if (targetLevel != null) {
      hierarchicalLoggingEnabled = true;
      Logger('antigravity').level = targetLevel;
    }
  }

  static const fromMap = DebugConfigMapper.fromMap;
  static const fromJson = DebugConfigMapper.fromJson;
}
