import 'dart:async';
import 'package:dart_mappable/dart_mappable.dart';
import '../types.dart';

part 'connection.mapper.dart';

/// Abstract base class for agent configuration.
///
/// Each ConnectionStrategy defines a concrete subclass with the config fields it needs.
@MappableClass()
abstract class AgentConfig with AgentConfigMappable {
  final dynamic systemInstructions; // String or SystemInstructions
  final CapabilitiesConfig capabilities;
  final List<dynamic> tools;
  final List<dynamic> policies;
  final List<dynamic> hooks;
  final List<dynamic> triggers;
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
    List<dynamic>? tools,
    List<dynamic>? policies,
    List<dynamic>? hooks,
    List<dynamic>? triggers,
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
       tools = tools ?? [],
       policies = policies ?? [],
       hooks = hooks ?? [],
       triggers = triggers ?? [],
       mcpServers = mcpServers ?? [],
       workspaces = workspaces ?? [],
       skillsPaths = skillsPaths ?? [];

  /// Creates the [ConnectionStrategy] for this configuration.
  ConnectionStrategy createStrategy({
    required dynamic toolRunner,
    required dynamic hookRunner,
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
