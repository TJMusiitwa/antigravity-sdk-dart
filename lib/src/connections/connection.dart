import 'dart:async';
import 'package:dart_mappable/dart_mappable.dart';
import '../types.dart';
import '../hooks/hooks.dart';
import '../hooks/policy.dart';
import '../tools/tool_runner.dart';
import '../triggers/triggers.dart';

part 'connection.mapper.dart';

@MappableClass(
  includeCustomMappers: [
    ToolMapper(),
    PolicyMapper(),
    HookMapper(),
    TriggerMapper(),
  ],
)
abstract class AgentConfig with AgentConfigMappable {
  final dynamic systemInstructions; // String or SystemInstructions
  final CapabilitiesConfig capabilities;

  final List<Tool> tools;
  final List<Policy> policies;
  final List<Hook> hooks;
  final List<Trigger> triggers;

  final List<McpServerConfig> mcpServers;
  final List<String> workspaces;
  final String? conversationId;
  final String? saveDir;
  final String? appDataDir;
  final dynamic responseSchema; // String, Map, or other schema formats
  final List<String> skillsPaths;

  AgentConfig({
    this.systemInstructions,
    CapabilitiesConfig? capabilities,
    List<Tool>? tools,
    List<Policy>? policies,
    List<Hook>? hooks,
    List<Trigger>? triggers,
    List<McpServerConfig>? mcpServers,
    List<String>? workspaces,
    this.conversationId,
    this.saveDir,
    this.appDataDir,
    this.responseSchema,
    List<String>? skillsPaths,
  }) : capabilities =
           capabilities ??
           CapabilitiesConfig(enabledTools: BuiltinTools.readOnly()),
       tools = tools ?? const [],
       policies = policies ?? const [],
       hooks = hooks ?? const [],
       triggers = triggers ?? const [],
       mcpServers = mcpServers ?? const [],
       workspaces = workspaces ?? const [],
       skillsPaths = skillsPaths ?? const [];

  /// Creates the [ConnectionStrategy] for this configuration.
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  });
}

/// A live session with an agent backend.
///
/// This is the common contract that all connection types implement.
abstract class Connection {
  /// Returns the current conversation identifier.
  String get conversationId;

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

  // Internal helper methods for state management
  Future<void> delete();
  void signalIdle();
  Future<void> waitForIdle();
  Future<bool> waitForWakeup({double timeout});
}

/// Abstract strategy for establishing a connection.
abstract class ConnectionStrategy {
  /// Performs the setup and handshake (async).
  Future<void> start();

  /// Returns the established [Connection].
  Connection connect();

  /// Cleans up the strategy.
  Future<void> stop();
}

class ToolMapper extends SimpleMapper<Tool> {
  const ToolMapper();
  @override
  Tool decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Tool value) => throw UnimplementedError();
}

class PolicyMapper extends SimpleMapper<Policy> {
  const PolicyMapper();
  @override
  Policy decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Policy value) => throw UnimplementedError();
}

class HookMapper extends SimpleMapper<Hook> {
  const HookMapper();
  @override
  Hook decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Hook value) => throw UnimplementedError();
}

class TriggerMapper extends SimpleMapper<Trigger> {
  const TriggerMapper();
  @override
  Trigger decode(dynamic value) => throw UnimplementedError();
  @override
  dynamic encode(Trigger value) => throw UnimplementedError();
}
