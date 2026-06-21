import 'dart:async';
import 'dart:convert';

import 'connections/connection.dart';
import 'conversation/conversation.dart';
import 'hooks/hooks.dart';
import 'hooks/policy.dart' as policy;
import 'tools/tool_context.dart';
import 'tools/tool_runner.dart';
import 'triggers/trigger_runner.dart';
import 'triggers/triggers.dart';
import 'types.dart';

/// A high-level agent coordinator for the Google Antigravity SDK.
///
/// The [Agent] manages the lifecycle of an agent session, including tools,
/// connection strategies, safety policies, execution triggers, hooks, and MCP servers.
class Agent {
  final AgentConfig _config;
  ConnectionStrategy? _strategy;
  Conversation? _conversation;
  ToolRunner? _toolRunner;
  HookRunner? _hookRunner;
  TriggerRunner? _triggerRunner;

  final List<Hook> _pendingHooks = [];
  final List<Trigger> _pendingTriggers = [];

  /// Creates a new [Agent] with the given [config].
  ///
  /// The configuration defines capabilities, safety policies, tools, and hooks
  /// used by the agent during its execution session.
  Agent(AgentConfig config) : _config = config {
    if (_config.responseSchema != null) {
      if (_config.responseSchema is String) {
        _config.capabilities.finishToolSchemaJson =
            _config.responseSchema as String;
      } else {
        _config.capabilities.finishToolSchemaJson = jsonEncode(
          _config.responseSchema,
        );
      }
    }
    _pendingHooks.addAll(_config.hooks);
    _pendingTriggers.addAll(_config.triggers);
  }

  /// Starts the agent session.
  Future<Agent> start() async {
    try {
      _hookRunner = HookRunner();

      // Register pending hooks
      for (final hook in _pendingHooks) {
        _hookRunner!.registerHook(hook);
      }
      _pendingHooks.clear();

      // Apply policies
      final activePolicies = List<policy.Policy>.from(_config.policies);
      final cfg = _config.capabilities;
      final readOnlyTools = BuiltinTools.readOnly().toSet();

      Set<BuiltinTools> activeTools;
      if (cfg.enabledTools != null) {
        activeTools = cfg.enabledTools!.toSet();
      } else if (cfg.disabledTools != null) {
        activeTools = BuiltinTools.values.toSet().difference(
              cfg.disabledTools!.toSet(),
            );
      } else {
        activeTools = BuiltinTools.values.toSet();
      }

      final hasWriteTools = activeTools.difference(readOnlyTools).isNotEmpty;
      final hasMcpServers = _config.mcpServers.isNotEmpty;
      final hasToolDecideHook = _hookRunner!.preToolCallDecideHooks.isNotEmpty;

      if ((hasWriteTools || hasMcpServers) &&
          activePolicies.isEmpty &&
          !hasToolDecideHook) {
        throw ArgumentError(
          "Write tools or MCP servers are enabled without a safety policy. "
          "Add policies: [policy.allowAll()] to approve all tool calls, "
          "or policies: [policy.denyAll(), policy.allow('tool_name')] "
          "to selectively allow specific tools.",
        );
      }

      if (activePolicies.isNotEmpty) {
        _hookRunner!.registerHook(
          policy.enforce(activePolicies, mcpServers: _config.mcpServers),
        );
      }

      final allTools = List<Tool>.from(_config.tools);

      _toolRunner = ToolRunner(tools: allTools);

      _strategy = _config.createStrategy(
        toolRunner: _toolRunner!,
        hookRunner: _hookRunner!,
      );

      await _strategy!.start();

      _conversation = Conversation(
        _strategy!.connect(),
        hookRunner: _hookRunner,
      );

      // Start triggers via TriggerRunner
      if (_pendingTriggers.isNotEmpty) {
        _triggerRunner = TriggerRunner(
          triggers: List.from(_pendingTriggers),
          connection: _conversation!.connection,
        );
        await _triggerRunner!.start();
        _pendingTriggers.clear();
      }

      // Wire ToolContext into ToolRunner
      final ctx = ToolContext(_conversation!.connection);
      _toolRunner!.setContext(ctx);

      return this;
    } catch (e) {
      await stop();
      rethrow;
    }
  }

  /// Stops the agent session.
  Future<void> stop() async {
    if (_triggerRunner != null) {
      await _triggerRunner!.stop();
      _triggerRunner = null;
    }
    if (_conversation != null) {
      await _conversation!.disconnect();
      _conversation = null;
    }
    if (_strategy != null) {
      await _strategy!.stop();
      _strategy = null;
    }
  }

  /// Sends a prompt and returns the final response.
  Future<ChatResponse> chat(
    ContentPrimitive prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    return await conversation.chat(prompt, kwargs: kwargs);
  }

  /// Whether the agent session is active.
  bool get isStarted => _conversation != null;

  /// The active Conversation session.
  Conversation get conversation {
    if (_conversation == null) {
      throw StateError(
        "Agent session not started. Call 'await agent.start()'.",
      );
    }
    return _conversation!;
  }

  /// Returns the conversation identifier.
  String? get conversationId {
    if (_conversation == null) return null;
    final cid = _conversation!.conversationId;
    return cid.isEmpty ? null : cid;
  }

  /// Returns the agent's configuration.
  AgentConfig get config => _config;

  /// Returns the agent's hook runner.
  HookRunner? get hookRunner => _hookRunner;
}
