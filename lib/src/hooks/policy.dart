import 'dart:async';
import 'dart:io';
import '../types.dart';
import 'hooks.dart';

/// Outcomes that a policy can produce.
enum Decision { approve, deny, askUser }

/// A single tool call policy rule.
class Policy {
  final String tool;
  final Decision decision;
  final FutureOr<bool> Function(ToolCall toolCall)? when;
  final FutureOr<bool> Function(ToolCall toolCall)? askUser;
  final String name;

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
const int _levelWildcardDeny = 3;
const int _levelWildcardAsk = 4;
const int _levelWildcardAllow = 5;

int _bucketIndex(Policy p) {
  final isWildcard = p.tool == '*';
  switch (p.decision) {
    case Decision.deny:
      return isWildcard ? _levelWildcardDeny : _levelSpecificDeny;
    case Decision.askUser:
      return isWildcard ? _levelWildcardAsk : _levelSpecificAsk;
    case Decision.approve:
      return isWildcard ? _levelWildcardAllow : _levelSpecificAllow;
  }
}

class PolicyDecideHook extends PreToolCallDecideHook {
  final List<List<Policy>> _buckets;

  PolicyDecideHook(this._buckets);

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
    if (p.tool != '*' && p.tool != toolCall.name) {
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
PreToolCallDecideHook enforce(List<Policy> policies) {
  for (final p in policies) {
    if (p.decision == Decision.askUser && p.askUser == null) {
      throw ArgumentError(
        "ASK_USER policy '${p.name.isNotEmpty ? p.name : p.tool}' is missing an ask_user handler.",
      );
    }
  }

  final List<List<Policy>> buckets = List.generate(6, (_) => []);
  for (final p in policies) {
    buckets[_bucketIndex(p)].add(p);
  }

  return PolicyDecideHook(buckets);
}
