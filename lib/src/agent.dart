import 'dart:async';
import 'connections/connection.dart';
import 'conversation/conversation.dart';
import 'hooks/hooks.dart';
import 'hooks/policy.dart' as policy;
import 'mcp/mcp_bridge.dart';
import 'tools/tool_context.dart';
import 'tools/tool_runner.dart';
import 'triggers/trigger_runner.dart';
import 'triggers/triggers.dart';
import 'types.dart';

/// High-level Agent API for simplified interaction.
class Agent {
  final AgentConfig _config;
  ConnectionStrategy? _strategy;
  Conversation? _conversation;
  ToolRunner? _toolRunner;
  HookRunner? _hookRunner;
  TriggerRunner? _triggerRunner;
  McpBridge? _mcpBridge;

  final List<Hook> _pendingHooks = [];
  final List<Trigger> _pendingTriggers = [];

  Agent(AgentConfig config) : _config = config {
    if (_config.responseSchema != null) {
      _config.capabilities.finishToolSchemaJson = _config.responseSchema
          .toString();
    }
    _pendingHooks.addAll(_config.hooks.cast<Hook>());
    _pendingTriggers.addAll(_config.triggers.cast<Trigger>());
  }

  /// Registers a hook on the agent.
  void registerHook(Hook hook) {
    if (_hookRunner == null) {
      _pendingHooks.add(hook);
      return;
    }
    _hookRunner!.registerHook(hook);
  }

  /// Registers a background event trigger.
  void registerTrigger(Trigger trigger) {
    if (_triggerRunner != null) {
      throw StateError("Cannot register triggers after the agent has started.");
    }
    _pendingTriggers.add(trigger);
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
      final activePolicies = List.from(_config.policies);
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
          policy.enforce(activePolicies.cast<policy.Policy>()),
        );
      }

      final allTools = List<Tool>.from(_config.tools.cast<Tool>());

      // Connect MCP servers and collect their tools
      if (_config.mcpServers.isNotEmpty) {
        _mcpBridge = McpBridge();
        for (final serverCfg in _config.mcpServers) {
          await _mcpBridge!.connect(serverCfg);
        }
        allTools.addAll(_mcpBridge!.tools);
      }

      _toolRunner = ToolRunner(tools: allTools);

      _strategy = _config.createStrategy(
        toolRunner: _toolRunner,
        hookRunner: _hookRunner,
      );

      await _strategy!.start();

      _conversation = Conversation(_strategy!.connect());

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
    if (_mcpBridge != null) {
      await _mcpBridge!.stop();
      _mcpBridge = null;
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
}
