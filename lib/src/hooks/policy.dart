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

/// A single tool call policy rule in the Google Antigravity SDK.
class Policy {
  /// The tool name that this policy targets (or '*' for a wildcard match).
  final String tool;

  /// The action/decision to apply when this policy matches.
  final Decision decision;

  /// Optional condition callback to test if this policy is applicable.
  final FutureOr<bool> Function(ToolCall toolCall)? when;

  /// Interactivity callback handler when the [decision] is [Decision.askUser].
  final FutureOr<bool> Function(ToolCall toolCall)? askUser;

  /// The unique descriptive name of the policy rule.
  final String name;

  /// Creates a new [Policy] rule.
  Policy({
    required this.tool,
    required this.decision,
    this.when,
    this.askUser,
    this.name = '',
  });
}

// --- Builder Helpers ---

List<Policy> _mcpPolicies(
  Decision decision,
  McpServerConfig mcpConfig,
  List<String>? mcpTools, {
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
  FutureOr<bool> Function(ToolCall toolCall)? handler,
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
      ),
    );
  }
  return policies;
}

/// Creates an APPROVE policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to allow tools on that MCP server.
dynamic allow(
  dynamic tool, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
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
        decision: Decision.approve,
        when: when,
        name: name,
      );
    case McpServerConfig mcp:
      return _mcpPolicies(
        Decision.approve,
        mcp,
        mcpTools,
        when: when,
        name: name,
      );
    default:
      throw ArgumentError(
        'Expected String or McpServerConfig, got ${tool.runtimeType}',
      );
  }
}

/// Creates a DENY policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to deny tools on that MCP server.
dynamic deny(
  dynamic tool, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  switch (tool) {
    case String s:
      if (mcpTools != null) {
        throw ArgumentError(
          'mcpTools cannot be specified when tool is a String.',
        );
      }
      return Policy(tool: s, decision: Decision.deny, when: when, name: name);
    case McpServerConfig mcp:
      return _mcpPolicies(Decision.deny, mcp, mcpTools, when: when, name: name);
    default:
      throw ArgumentError(
        'Expected String or McpServerConfig, got ${tool.runtimeType}',
      );
  }
}

/// Creates an ASK_USER policy.
///
/// [tool] can be either a [String] tool name, or an [McpServerConfig] to ask confirmation for tools on that MCP server.
dynamic askUser(
  dynamic tool, {
  List<String>? mcpTools,
  required FutureOr<bool> Function(ToolCall toolCall) handler,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
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
        decision: Decision.askUser,
        when: when,
        askUser: handler,
        name: name,
      );
    case McpServerConfig mcp:
      return _mcpPolicies(
        Decision.askUser,
        mcp,
        mcpTools,
        when: when,
        name: name,
        handler: handler,
      );
    default:
      throw ArgumentError(
        'Expected String or McpServerConfig, got ${tool.runtimeType}',
      );
  }
}

/// Creates a policy that approves all tool calls without confirmation.
Policy allowAll() => allow('*', name: 'allow_all');

/// Creates a policy that denies all tool calls.
Policy denyAll() => deny('*', name: 'deny_all');

/// Creates a list of safe default policies (allowing read-only, asking for everything else).
List<Policy> safeDefaults(FutureOr<bool> Function(ToolCall toolCall) handler) {
  return [
    ...BuiltinTools.readOnly().map((t) => allow(t.value)),
    askUser('*', handler: handler),
  ];
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

/// Creates a policy to allow tools only within a specific workspace.
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
    final mcpInfo = _parseMcpTool(toolCall.name);
    final String callTarget;
    final bool isMcp;
    if (mcpInfo != null) {
      callTarget = '${mcpInfo.key}/${mcpInfo.value}';
      isMcp = true;
    } else {
      callTarget = toolCall.name;
      isMcp = false;
    }

    if (!_matchesTarget(p.tool, callTarget, isMcp)) {
      return null;
    }

    try {
      if (p.when != null) {
        final matches = await p.when!(toolCall);
        if (!matches) {
          return null;
        }
      }

      final label = p.name.isNotEmpty ? p.name : p.tool;

      if (p.decision == Decision.deny) {
        return HookResult(allow: false, message: "Denied by policy '$label'.");
      }

      if (p.decision == Decision.approve) {
        return HookResult(allow: true);
      }

      // ASK_USER
      if (p.askUser != null) {
        final approved = await p.askUser!(toolCall);
        if (approved) {
          return HookResult(allow: true);
        }
        return HookResult(
          allow: false,
          message: "User denied tool '${toolCall.name}' (policy '$label').",
        );
      }
    } catch (e) {
      final label = p.name.isNotEmpty ? p.name : p.tool;
      return HookResult(
        allow: false,
        message: "Policy evaluation failed for policy '$label': $e",
      );
    }
    return null;
  }
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
