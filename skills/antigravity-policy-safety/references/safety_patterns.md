# Safety Policies & Sandboxing Code Patterns

Disclosed reference file containing implementations for interactive policy handlers and path containment checks.

## 1. CLI Interactive Policy Confirmation Handler

```dart
import 'dart:io';
import 'package:antigravity/antigravity.dart';

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

## 2. Workspace Path Containment Utility

```dart
import 'package:path/path.dart' as p;

/// Returns true if [targetPath] is safely inside [workspacePath].
bool isPathWithinWorkspace(String targetPath, String workspacePath) {
  final canonicalTarget = p.canonicalize(targetPath);
  final canonicalWorkspace = p.canonicalize(workspacePath);
  
  return p.isWithin(canonicalWorkspace, canonicalTarget) || 
         canonicalTarget == canonicalWorkspace;
}
```
