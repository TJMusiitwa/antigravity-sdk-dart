import 'dart:async';
import 'dart:io';

import '../types.dart';
import 'hooks.dart';

/// Outcomes that a policy can produce in the Google Antigravity SDK.
enum Decision {
  /// Approve the tool execution without checking with the user.
  approve,

  /// Explicitly deny the tool execution immediately.
  deny,

  /// Prompt the user to approve or deny the tool execution.
  askUser,
}

/// An ask-user handler.
///
/// Receives the pending [ToolCall]. Handlers may optionally accept a `reason`
/// supplied by the policy evaluation runtime (for example a safety assessment
/// in auto policy mode), declared as an optional positional or named
/// parameter. [executeAskUser] passes it only when the handler declares it, so
/// existing one-argument handlers remain valid.
typedef AskUserHandler = FutureOr<bool> Function(ToolCall toolCall);

/// A single tool call policy rule in the Google Antigravity SDK.
class Policy {
  /// The tool name that this policy targets (or '*' for a wildcard match).
  final String tool;

  /// The action/decision to apply when this policy matches.
  final Decision decision;

  /// Optional condition callback to test if this policy is applicable.
  final FutureOr<bool> Function(ToolCall toolCall)? when;

  /// Interactivity callback handler when the [decision] is [Decision.askUser].
  final AskUserHandler? askUser;

  /// The unique descriptive name of the policy rule.
  final String name;

  /// Optional explanation for why the policy matched.
  ///
  /// Forwarded to [askUser] handlers, and used as the deny reason when the
  /// decision is [Decision.deny] or the user rejects the call.
  final String reason;

  /// Whether this policy enables auto policy mode safety evaluation.
  ///
  /// Always false for ordinary rules. [AutoPolicy] overrides this.
  bool get auto => false;

  /// Creates a new [Policy] rule.
  Policy({
    required this.tool,
    required this.decision,
    this.when,
    this.askUser,
    this.name = '',
    this.reason = '',
  });
}

/// A policy rule enabling auto policy mode safety evaluation.
///
/// When running in auto policy mode, commands and tool calls are assessed for
/// safety by pre-tool safety assessors before execution. If flagged, execution
/// is blocked, or user confirmation is requested when [askUser] is set.
///
/// Auto policy mode evaluates tools with inherent execution or network risk,
/// such as shell command execution and external URL fetching. Standard
/// read-only workspace operations are allowed without prompting. For file-write
/// containment, pair [auto] with [workspaceOnly].
///
/// Evaluation order when combined with other policies:
/// 1. Specific tool rules and server prefix rules run first and take precedence.
/// 2. [auto] runs next for assessed tools and safety-flagged invocations.
/// 3. Global wildcard rules ([denyAll], [allowAll]) run last as catch-all
///    fallbacks for unassessed tools.
class AutoPolicy extends Policy {
  /// Optional Gemini model name used for safety evaluation.
  ///
  /// When null, the runtime's default safety assessment model is used.
  final String? model;

  @override
  bool get auto => true;

  /// Creates an [AutoPolicy].
  ///
  /// The tool target is always `*`. The decision is [Decision.askUser] when
  /// [askUser] is set, otherwise [Decision.deny].
  AutoPolicy({
    super.askUser,
    super.name = 'auto',
    this.model,
  }) : super(
          tool: '*',
          decision: askUser != null ? Decision.askUser : Decision.deny,
        );
}

// --- Builder Helpers ---

List<Policy> _mcpPolicies(
  Decision decision,
  McpServerConfig mcpConfig,
  List<String>? mcpTools, {
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
  AskUserHandler? handler,
  String reason = '',
}) {
  final server = mcpConfig.name;

  if (mcpTools == null) {
    final policyName =
        name.isNotEmpty ? name : '${decision.name.toLowerCase()}_${server}_all';
    return [
      Policy(
        tool: '$server/*',
        decision: decision,
        when: when,
        name: policyName,
        askUser: handler,
        reason: reason,
      ),
    ];
  }

  final List<Policy> policies = [];
  for (final t in mcpTools) {
    final policyName = name.isNotEmpty
        ? '${name}_$t'
        : '${decision.name.toLowerCase()}_${server}_$t';
    policies.add(
      Policy(
        tool: '$server/$t',
        decision: decision,
        when: when,
        name: policyName,
        askUser: handler,
        reason: reason,
      ),
    );
  }
  return policies;
}

/// Creates an APPROVE policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to allow tools on that MCP server.
dynamic _createPolicy(
  Decision decision,
  dynamic tool, {
  List<String>? mcpTools,
  AskUserHandler? handler,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
  String reason = '',
}) {
  switch (tool) {
    case String s:
      if (mcpTools != null) {
        throw ArgumentError(
          'mcpTools cannot be specified when tool is a String.',
        );
      }
      return Policy(
        tool: s,
        decision: decision,
        when: when,
        askUser: handler,
        name: name,
        reason: reason,
      );
    case McpServerConfig mcp:
      return _mcpPolicies(
        decision,
        mcp,
        mcpTools,
        when: when,
        name: name,
        handler: handler,
        reason: reason,
      );
    default:
      throw ArgumentError(
        'Expected String or McpServerConfig, got ${tool.runtimeType}',
      );
  }
}

/// Creates an APPROVE policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to allow tools on that MCP server.
dynamic allow(
  dynamic tool, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) =>
    _createPolicy(
      Decision.approve,
      tool,
      mcpTools: mcpTools,
      when: when,
      name: name,
    );

/// Creates a DENY policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to deny tools on that MCP server.
dynamic deny(
  dynamic tool, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
  String reason = '',
}) =>
    _createPolicy(
      Decision.deny,
      tool,
      mcpTools: mcpTools,
      when: when,
      name: name,
      reason: reason,
    );

/// Creates an ASK_USER policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to ask confirmation for tools on that MCP server.
///
/// The optional [handler] callback is invoked client-side to prompt the user or evaluate
/// dynamic approval asynchronously before tool execution. If [handler] is omitted (`null`),
/// confirmation is delegated to the host platform environment (e.g. IDE UI / Flutter dialog);
/// note that if client-side [enforce] is called with an [askUser] policy without a [handler],
/// an [ArgumentError] is thrown to prevent unhandled confirmation gates.
///
/// Custom handlers receive the pending [ToolCall] and can optionally accept a
/// `reason` parameter explaining why confirmation was requested by the runtime
/// (for example a safety assessment in auto policy mode). [reason] is that
/// explanation when the policy itself supplies one.
dynamic askUser(
  dynamic tool, {
  List<String>? mcpTools,
  AskUserHandler? handler,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
  String reason = '',
}) =>
    _createPolicy(
      Decision.askUser,
      tool,
      mcpTools: mcpTools,
      handler: handler,
      when: when,
      name: name,
      reason: reason,
    );

/// Creates a policy that approves all tool calls without confirmation.
Policy allowAll() => allow('*', name: 'allow_all');

/// Creates a policy that denies all tool calls.
Policy denyAll() => deny('*', name: 'deny_all');

/// Creates a list of safe default policies (allowing read-only, asking for everything else).
///
/// Deprecated tools ([BuiltinTools.deprecated]) are treated as read-only here,
/// matching upstream: they stay allowed when explicitly enabled, but are not
/// part of [BuiltinTools.readOnly].
List<Policy> safeDefaults(AskUserHandler handler) {
  final readOnlyTools = [
    ...BuiltinTools.readOnly(),
    ...BuiltinTools.deprecated(),
  ];
  return [
    ...readOnlyTools.map((t) => allow(t.value)),
    askUser('*', handler: handler),
  ];
}

/// Creates a policy enabling auto policy mode safety evaluation.
///
/// When running in auto policy mode, commands and tool calls are assessed for
/// safety before execution. If flagged, execution is blocked, or [handler] is
/// invoked to request confirmation. At most one [auto] rule may be specified.
///
/// [model] is an optional Gemini model name used for safety evaluation. When
/// null, the runtime's default safety assessment model is used.
AutoPolicy auto({
  String name = 'auto',
  AskUserHandler? handler,
  String? model,
}) {
  return AutoPolicy(name: name, askUser: handler, model: model);
}

/// Denies or asks confirmation for running commands, allowing everything else.
List<Policy> confirmRunCommand({FutureOr<bool> Function(ToolCall)? handler}) {
  if (handler != null) {
    return [
      askUser(
        BuiltinTools.runCommand.value,
        handler: handler,
        name: 'confirm_run_command',
      ),
      allow('*', name: 'confirm_run_command'),
    ];
  }
  return [
    deny(BuiltinTools.runCommand.value, name: 'confirm_run_command'),
    allow('*', name: 'confirm_run_command'),
  ];
}

// --- Path Verification & Workspace Scoping ---

String _secureNormalizePath(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return file.resolveSymbolicLinksSync();
    }
    final dir = Directory(path);
    if (dir.existsSync()) {
      return dir.resolveSymbolicLinksSync();
    }
    final absolutePath = file.absolute.path;
    return Uri.file(absolutePath).normalizePath().toFilePath();
  } catch (_) {
    try {
      return Uri.file(File(path).absolute.path).normalizePath().toFilePath();
    } catch (_) {
      return File(path).absolute.path;
    }
  }
}

/// Returns true if [targetPath] canonicalizes strictly within [workspacePath].
bool isPathInWorkspace(String targetPath, String workspacePath) {
  try {
    final normTarget = _secureNormalizePath(targetPath);
    final normWs = _secureNormalizePath(workspacePath);

    final targetParts = normTarget
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .toList();
    final wsParts = normWs
        .split(Platform.pathSeparator)
        .where((p) => p.isNotEmpty)
        .toList();

    if (targetParts.length < wsParts.length) {
      return false;
    }

    final isWindows = Platform.isWindows;

    for (int i = 0; i < wsParts.length; i++) {
      final tPart = isWindows ? targetParts[i].toLowerCase() : targetParts[i];
      final wPart = isWindows ? wsParts[i].toLowerCase() : wsParts[i];
      if (tPart != wPart) {
        return false;
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

/// Restricts file manipulation tools to specific workspace directories.
List<Policy> workspaceOnly(List<String> workspaces) {
  final fileTools = BuiltinTools.fileTools().map((t) => t.value).toList();

  bool outsideWorkspace(ToolCall tc) {
    final path = tc.canonicalPath ?? '';
    if (path.isEmpty) {
      return false;
    }
    return !workspaces.any((ws) => isPathInWorkspace(path, ws));
  }

  return fileTools
      .map(
        (tool) => deny(tool, when: outsideWorkspace, name: 'workspace_only')
            as Policy,
      )
      .toList();
}

/// Creates a wildcard allow rule that matches non-file tools and file tools
/// inside [workspacePath].
///
/// This rule never denies: a file call outside [workspacePath] simply does not
/// match it. Local configs restrict file tools to their `workspaces` in the
/// harness, and [workspaceOnly] denies file access outside a set of
/// directories on the client.
@Deprecated(
  'Allows every non-file tool and never denies. Use the config `workspaces` '
  '(enforced by the harness) or workspaceOnly() instead.',
)
Policy workspace(String workspacePath) {
  return allow(
    '*',
    when: (tc) {
      final path = tc.canonicalPath ?? '';
      if (path.isEmpty) return true; // Non-file tools
      return isPathInWorkspace(path, workspacePath);
    },
    name: 'workspace_containment',
  );
}

// --- Bucket Pre-Sorting & Enforcement Hook ---

const int _levelSpecificDeny = 0;
const int _levelSpecificAsk = 1;
const int _levelSpecificAllow = 2;

const int _levelPrefixDeny = 3;
const int _levelPrefixAsk = 4;
const int _levelPrefixAllow = 5;

const int _levelGlobalDeny = 6;
const int _levelGlobalAsk = 7;
const int _levelGlobalAllow = 8;

const int _numLevels = 9;

bool _isGlobalWildcard(String tool) => tool == '*';

bool _isPrefixWildcard(String tool) => tool.endsWith('/*');

int _bucketIndex(Policy p) => switch (p.decision) {
      Decision.deny when _isGlobalWildcard(p.tool) => _levelGlobalDeny,
      Decision.askUser when _isGlobalWildcard(p.tool) => _levelGlobalAsk,
      Decision.approve when _isGlobalWildcard(p.tool) => _levelGlobalAllow,
      Decision.deny when _isPrefixWildcard(p.tool) => _levelPrefixDeny,
      Decision.askUser when _isPrefixWildcard(p.tool) => _levelPrefixAsk,
      Decision.approve when _isPrefixWildcard(p.tool) => _levelPrefixAllow,
      Decision.deny => _levelSpecificDeny,
      Decision.askUser => _levelSpecificAsk,
      Decision.approve => _levelSpecificAllow,
    };

bool _matchesTarget(String policyTool, String callTarget, bool isMcp) {
  if (policyTool == '*') {
    return true;
  }

  if (isMcp) {
    if (_isPrefixWildcard(policyTool)) {
      final policyServer = policyTool.substring(0, policyTool.length - 2);
      final parts = callTarget.split('/');
      if (parts.isEmpty) return false;
      final callServer = parts[0];
      return policyServer == callServer;
    }
    return policyTool == callTarget;
  }

  return policyTool == callTarget;
}

List<Policy> flattenPolicies(List<dynamic> policies) {
  final List<Policy> flat = [];
  for (final p in policies) {
    if (p is Policy) {
      flat.add(p);
    } else if (p is Iterable) {
      for (final subP in p) {
        if (subP is Policy) {
          flat.add(subP);
        } else {
          throw ArgumentError('Expected Policy, got ${subP.runtimeType}');
        }
      }
    } else {
      throw ArgumentError('Expected Policy or Iterable, got ${p.runtimeType}');
    }
  }
  return flat;
}

/// A security policy decision hook in the Google Antigravity SDK.
///
/// Pre-sorts policies into priority buckets and evaluates them sequentially
/// to determine tool call authorization.
class PolicyDecideHook extends PreToolCallDecideHook {
  final List<List<Policy>> _buckets;
  final List<String> _serverNames;

  /// Creates a new [PolicyDecideHook] instance.
  PolicyDecideHook(this._buckets, {List<String>? serverNames})
      : _serverNames = List.from(serverNames ?? const [])
          ..sort((a, b) => b.length.compareTo(a.length));

  MapEntry<String, String>? _parseMcpTool(String toolName) {
    if (!toolName.startsWith('mcp_')) {
      return null;
    }
    final rest = toolName.substring(4);
    for (final server in _serverNames) {
      if (rest.startsWith('${server}_')) {
        return MapEntry(server, rest.substring(server.length + 1));
      }
    }
    return null;
  }

  @override
  Future<HookResult> run(HookContext context, ToolCall toolCall) async {
    try {
      for (final bucket in _buckets) {
        for (final p in bucket) {
          final matched = await _evaluatePolicy(p, toolCall);
          if (matched != null) {
            return matched;
          }
        }
      }
    } catch (e) {
      return HookResult(
        allow: false,
        message: 'Unexpected internal exception in policy hook: $e',
      );
    }
    return HookResult(allow: true);
  }

  Future<HookResult?> _evaluatePolicy(Policy p, ToolCall toolCall) async {
    // Auto policy mode safety evaluation is enforced at the
    // platform/execution layer, not by this client hook.
    if (p.auto) {
      return null;
    }
    final targetInfo = _resolveCallTarget(toolCall);
    if (!_matchesTarget(p.tool, targetInfo.target, targetInfo.isMcp)) {
      return null;
    }

    final label = p.name.isNotEmpty ? p.name : p.tool;
    try {
      if (p.when != null) {
        final matches = await p.when!(toolCall);
        if (!matches) return null;
      }
      return await _executePolicyDecision(p, toolCall, label);
    } catch (e) {
      return HookResult(
        allow: false,
        message: "Policy evaluation failed for policy '$label': $e",
      );
    }
  }

  ({String target, bool isMcp}) _resolveCallTarget(ToolCall toolCall) {
    if (toolCall.serverName != null && toolCall.serverName!.isNotEmpty) {
      return (target: '${toolCall.serverName}/${toolCall.name}', isMcp: true);
    }
    final legacyMcp = _parseMcpTool(toolCall.name);
    if (legacyMcp != null) {
      return (target: '${legacyMcp.key}/${legacyMcp.value}', isMcp: true);
    }
    return (target: toolCall.name, isMcp: false);
  }

  static Future<HookResult?> _executePolicyDecision(
    Policy p,
    ToolCall toolCall,
    String label,
  ) async {
    if (p.decision == Decision.deny) {
      return HookResult(
        allow: false,
        message: p.reason.isNotEmpty ? p.reason : "Denied by policy '$label'.",
      );
    }
    if (p.decision == Decision.approve) {
      return HookResult(allow: true);
    }
    if (p.askUser != null) {
      final approved = await executeAskUser(p, toolCall, reason: p.reason);
      if (approved) return HookResult(allow: true);
      return HookResult(
        allow: false,
        message: p.reason.isNotEmpty
            ? p.reason
            : "User denied tool '${toolCall.name}' (policy '$label').",
      );
    }
    return null;
  }
}

/// Invokes [policy]'s ask-user handler, passing [reason] when the callback
/// accepts it.
///
/// [AskUserHandler] only requires the tool call, so pre-0.15.0 one-argument
/// handlers stay valid. A handler that also declares an optional positional
/// `reason` (`[String reason = '']` or `[String? reason]`) receives it, as does
/// one declaring a named `{String reason = ''}` or `{String? reason}`. The
/// handler is called exactly once.
Future<bool> executeAskUser(
  Policy policy,
  ToolCall toolCall, {
  String reason = '',
}) async {
  final handler = policy.askUser;
  if (handler == null) {
    throw StateError('ask_user handler is null');
  }
  if (handler is FutureOr<bool> Function(ToolCall, [String])) {
    return await handler(toolCall, reason);
  }
  if (handler is FutureOr<bool> Function(ToolCall, {String reason})) {
    return await handler(toolCall, reason: reason);
  }
  return await handler(toolCall);
}

/// Compiles list of Policies into a high-performance PreToolCallDecideHook.
PreToolCallDecideHook enforce(
  List<dynamic> policies, {
  List<McpServerConfig>? mcpServers,
}) {
  final flatPolicies = flattenPolicies(policies);

  // Validate MCP policies against mcpServers (Fail-Closed Security Guard)
  final hasMcpPolicy = flatPolicies.any(
    (p) => p.tool.contains('/') && p.tool != '*',
  );
  if (hasMcpPolicy && (mcpServers == null || mcpServers.isEmpty)) {
    throw ArgumentError(
      "MCP policies (containing '/') were detected, but 'mcpServers' was not "
      "provided to enforce(). You must pass the registered MCP servers to "
      "enable secure policy matching and prevent silent bypasses.",
    );
  }

  for (final p in flatPolicies) {
    // Auto policy without a handler denies flagged calls at the harness; it
    // is not a client-side confirmation gate.
    if (p.auto) continue;
    if (p.decision == Decision.askUser && p.askUser == null) {
      throw ArgumentError(
        "ASK_USER policy '${p.name.isNotEmpty ? p.name : p.tool}' is missing an ask_user handler.",
      );
    }
  }

  final List<List<Policy>> buckets = List.generate(_numLevels, (_) => []);
  for (final p in flatPolicies) {
    buckets[_bucketIndex(p)].add(p);
  }

  final serverNames = mcpServers?.map((s) => s.name).toList();
  return PolicyDecideHook(buckets, serverNames: serverNames);
}

const String _policyDecisionAllow = 'POLICY_DECISION_ALLOW';
const String _policyDecisionDeny = 'POLICY_DECISION_DENY';
const String _policyDecisionAskUser = 'POLICY_DECISION_ASK_USER';

/// Wire name of the workspace-only rule, skipped by dynamic evaluation.
const String workspaceOnlyPolicyName = 'workspace_only';

({String tool, String serverName}) _parseToolTarget(String tool) {
  if (tool == '*') return (tool: '*', serverName: '');
  final slash = tool.indexOf('/');
  if (slash >= 0) {
    return (
      tool: tool.substring(slash + 1),
      serverName: tool.substring(0, slash),
    );
  }
  return (tool: tool, serverName: '');
}

String _decisionProto(Decision decision) => switch (decision) {
      Decision.approve => _policyDecisionAllow,
      Decision.deny => _policyDecisionDeny,
      Decision.askUser => _policyDecisionAskUser,
    };

/// Serializes [policies] into the `localharness` `policy_config` map.
///
/// Static rules (no condition, not ASK_USER) are handled entirely by the
/// harness. Dynamic rules are tagged with a `rule_id` and returned in
/// [PolicyConfigProto.dynamicPolicies] so the connection can answer a
/// `PolicyDecisionRequest`. At most one [AutoPolicy] is accepted; it is
/// emitted as `auto_config` and stored under the rule id `auto`.
({Map<String, dynamic> config, Map<String, Policy> dynamicPolicies})
    toPolicyConfigProto(List<dynamic> policies) {
  final flat = flattenPolicies(policies);
  final dynamicPolicies = <String, Policy>{};
  final rules = <Map<String, dynamic>>[];
  AutoPolicy? autoPolicy;

  for (var i = 0; i < flat.length; i++) {
    final p = flat[i];
    if (p is AutoPolicy) {
      if (autoPolicy != null) {
        throw ArgumentError(
          'Multiple AutoPolicy rules found; at most one policy.auto() '
          'rule may be specified.',
        );
      }
      autoPolicy = p;
      continue;
    }

    final target = _parseToolTarget(p.tool);
    final isWorkspaceOnly = p.name == workspaceOnlyPolicyName;
    final isDynamic =
        (p.when != null || p.decision == Decision.askUser) && !isWorkspaceOnly;
    final ruleId = isDynamic ? 'rule_$i' : '';
    if (isDynamic) {
      dynamicPolicies[ruleId] = p;
    }
    rules.add({
      'tool': target.tool,
      'server_name': target.serverName,
      'name': p.name.isNotEmpty ? p.name : p.tool,
      'decision': _decisionProto(p.decision),
      'deny_reason': p.reason,
      'is_dynamic': isDynamic,
      'rule_id': ruleId,
    });
  }

  Map<String, dynamic>? autoConfig;
  if (autoPolicy != null) {
    autoConfig = {
      'enabled': true,
      'model': autoPolicy.model ?? '',
    };
    dynamicPolicies['auto'] = autoPolicy;
  }

  return (
    config: {
      'rules': rules,
      if (autoConfig != null) 'auto_config': autoConfig,
    },
    dynamicPolicies: dynamicPolicies,
  );
}
