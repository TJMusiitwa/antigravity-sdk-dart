---
name: antigravity-policy-safety
description: "Guidelines for configuring safety policies, sandboxing workspaces, and implementing user confirmations."
---

# Safety Policies & Sandboxing in Dart

This skill describes how to configure priority-bucketed declarative safety policies to safeguard local files and system processes from autonomous agent operations.

## 1. Declarative Policies Configuration

The Antigravity SDK evaluates safety rules in a top-down list. The first rule matching a tool name dictates the action: `allow`, `deny`, or `askUser` (interactive prompt).

### Default-Deny Configuration
Always declare a fallback rule denying access to all tools (`deny("*")`) at the end of the policy list.

```dart
import 'package:antigravity/antigravity.dart';

final policies = [
  // 1. Explicitly allow safe read actions
  allow("view_file"),
  
  // 2. Interactively confirm high-risk operations
  askUser("run_command", handler: customCliHandler),
  
  // 3. Reject all other actions by default
  deny("*"),
];

final config = LocalAgentConfig(
  policies: policies,
  capabilities: CapabilitiesConfig(),
);
```

---

## 2. Interactive Policy Handlers

Interactive handlers allow you to prompt the user (via CLI stdin or UI overlays) before executing matching tools.

### Writing a CLI Confirmation Handler
The handler function receives the `ToolCall` context and returns a `Future<bool>`:

```dart
import 'dart:io';

Future<bool> customCliHandler(ToolCall toolCall) async {
  stdout.writeln("\n[POLICY ALERT] Agent wants to execute: ${toolCall.name}");
  if (toolCall.args.isNotEmpty) {
    stdout.writeln("Arguments: ${toolCall.args}");
  }
  
  stdout.write("Proceed? (y/N): ");
  final input = stdin.readLineSync()?.trim().toLowerCase() ?? '';
  return input == 'y' || input == 'yes';
}
```

---

## 3. Path Containment & Sandboxing

Prevent path-traversal attacks (`../../etc/passwd`) by checking that target paths are contained inside the designated workspace.

### Safe Path Verification Utility
```dart
import 'package:path/path.dart' as p;

bool isPathWithinWorkspace(String targetPath, String workspacePath) {
  final canonicalTarget = p.canonicalize(targetPath);
  final canonicalWorkspace = p.canonicalize(workspacePath);
  
  return p.isWithin(canonicalWorkspace, canonicalTarget) || 
         canonicalTarget == canonicalWorkspace;
}
```

Implement this check inside custom file tools or file-system hooks to reject target paths lying outside the safe workspace.
