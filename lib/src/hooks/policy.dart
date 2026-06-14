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

/// Creates an APPROVE policy for [tool].
Policy allow(
  String tool, {
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return Policy(tool: tool, decision: Decision.approve, when: when, name: name);
}

/// Creates a DENY policy for [tool].
Policy deny(
  String tool, {
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return Policy(tool: tool, decision: Decision.deny, when: when, name: name);
}

/// Creates an ASK_USER policy for [tool].
Policy askUser(
  String tool, {
  required FutureOr<bool> Function(ToolCall toolCall) handler,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return Policy(
    tool: tool,
    decision: Decision.askUser,
    when: when,
    askUser: handler,
    name: name,
  );
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

List<Policy> _mcpPolicies(
  Decision decision,
  McpServerConfig mcpConfig,
  List<String>? mcpTools, {
  FutureOr<bool> Function(ToolCall)? when,
  String name = '',
  FutureOr<bool> Function(ToolCall)? handler,
}) {
  final server = mcpConfig.name;
  if (mcpTools == null) {
    final policyName =
        name.isNotEmpty ? name : '${decision.name}_${server}_all';
    return [
      Policy(
        tool: '$server/*',
        decision: decision,
        when: when,
        name: policyName,
        askUser: handler,
      )
    ];
  }

  return mcpTools.map((t) {
    final policyName =
        name.isNotEmpty ? '${name}_$t' : '${decision.name}_${server}_$t';
    return Policy(
      tool: '$server/$t',
      decision: decision,
      when: when,
      name: policyName,
      askUser: handler,
    );
  }).toList();
}

List<Policy> allowMcp(
  McpServerConfig mcpConfig, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return _mcpPolicies(Decision.approve, mcpConfig, mcpTools,
      when: when, name: name);
}

List<Policy> denyMcp(
  McpServerConfig mcpConfig, {
  List<String>? mcpTools,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return _mcpPolicies(Decision.deny, mcpConfig, mcpTools,
      when: when, name: name);
}

List<Policy> askUserMcp(
  McpServerConfig mcpConfig, {
  List<String>? mcpTools,
  required FutureOr<bool> Function(ToolCall toolCall) handler,
  FutureOr<bool> Function(ToolCall toolCall)? when,
  String name = '',
}) {
  return _mcpPolicies(Decision.askUser, mcpConfig, mcpTools,
      handler: handler, when: when, name: name);
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
    // For non-existent paths, use Uri normalization to resolve .. and . segments
    // File.absolute.path does NOT collapse .. in already-absolute paths on all
    // platforms; Uri.normalizePath() correctly handles directory traversal.
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
      .map((tool) => deny(tool, when: outsideWorkspace, name: 'workspace_only'))
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

int _bucketIndex(Policy p) {
  if (p.tool == '*') {
    switch (p.decision) {
      case Decision.deny:
        return _levelGlobalDeny;
      case Decision.askUser:
        return _levelGlobalAsk;
      case Decision.approve:
        return _levelGlobalAllow;
    }
  }
  if (p.tool.endsWith('/*')) {
    switch (p.decision) {
      case Decision.deny:
        return _levelPrefixDeny;
      case Decision.askUser:
        return _levelPrefixAsk;
      case Decision.approve:
        return _levelPrefixAllow;
    }
  }
  switch (p.decision) {
    case Decision.deny:
      return _levelSpecificDeny;
    case Decision.askUser:
      return _levelSpecificAsk;
    case Decision.approve:
      return _levelSpecificAllow;
  }
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
      : _serverNames = serverNames ?? [] {
    // Sort descending by length for secure longest-match parsing
    _serverNames.sort((a, b) => b.length.compareTo(a.length));
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
        message: 'Unexpected internal exception in policy hook: \$e',
      );
    }
    return HookResult(allow: true);
  }

  (String, String)? _parseMcpTool(String toolName) {
    if (!toolName.startsWith('mcp_')) {
      return null;
    }
    final rest = toolName.substring(4);
    for (final server in _serverNames) {
      if (rest.startsWith('${server}_')) {
        return (server, rest.substring(server.length + 1));
      }
    }
    return null;
  }

  bool _matchesTarget(String policyTool, String callTarget, bool isMcp) {
    if (policyTool == '*') return true;
    if (isMcp) {
      if (policyTool.endsWith('/*')) {
        final policyServer = policyTool.substring(0, policyTool.length - 2);
        final callServer = callTarget.split('/').first;
        return policyServer == callServer;
      }
      return policyTool == callTarget;
    }
    return policyTool == callTarget;
  }

  Future<HookResult?> _evaluatePolicy(Policy p, ToolCall toolCall) async {
    final mcpInfo = _parseMcpTool(toolCall.name);
    late String callTarget;
    late bool isMcp;

    if (mcpInfo != null) {
      final server = mcpInfo.$1;
      final tool = mcpInfo.$2;
      callTarget = '$server/$tool';
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
PreToolCallDecideHook enforce(List<Policy> policies,
    {List<McpServerConfig>? mcpServers}) {
  bool hasMcpPolicy = false;
  for (final p in policies) {
    if (p.decision == Decision.askUser && p.askUser == null) {
      throw ArgumentError(
        "ASK_USER policy '${p.name.isNotEmpty ? p.name : p.tool}' is missing an ask_user handler.",
      );
    }
    if (p.tool.contains('/') && p.tool != '*') {
      hasMcpPolicy = true;
    }
  }

  if (hasMcpPolicy && (mcpServers == null || mcpServers.isEmpty)) {
    throw ArgumentError(
        "MCP policies (containing '/') were detected, but 'mcpServers' was not "
        "provided to enforce(). You must pass the registered MCP servers to "
        "enable secure policy matching and prevent silent bypasses.");
  }

  final List<List<Policy>> buckets = List.generate(_numLevels, (_) => []);
  for (final p in policies) {
    buckets[_bucketIndex(p)].add(p);
  }

  final serverNames = mcpServers?.map((s) => s.name).toList() ?? [];
  return PolicyDecideHook(buckets, serverNames: serverNames);
}
