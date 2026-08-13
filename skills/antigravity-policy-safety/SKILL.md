---
name: antigravity-policy-safety
description: "Configure declarative safety policies (allow/deny/askUser), path containment, confirmation handlers, or sandboxing in Dart."
---

# Safety Policies & Sandboxing in Dart

Guidelines for configuring priority-bucketed declarative safety policies to safeguard local files and system processes.

## 1. Declarative Policy Setup & Agent Modes

1. **Top-Down Evaluation**: The SDK evaluates safety rules sequentially across a 9-level priority framework. The first matching rule dictates the decision (`allow`, `deny`, or `askUser`).
2. **Default-Deny Fallback**: Always place an explicit catch-all fallback rule denying unmatched tools (`deny("*")`) at the end of the rule list.
3. **Agent Behavior Interaction**: In `AgentBehavior.interactive`, tool execution policies trigger user confirmation prompts (`askUser`), whereas `AgentBehavior.autonomous` processes policies silently according to matching rules.

```dart
final policies = [
  allow("view_file"),
  askUser("run_command", handler: customCliHandler),
  deny("*"),
];
```

## 2. Interactive Handlers & Sandboxing

- **Asynchronous Confirmation Gate**: Implement asynchronous handlers returning `Future<bool>` to prompt users prior to executing privileged tools. Inspect [`references/safety_patterns.md`](file://references/safety_patterns.md).
- **Workspace Path Containment**: Verify target file paths lie inside the active workspace directory using path canonicalization. Read [`references/safety_patterns.md`](file://references/safety_patterns.md) for implementation.

## Completion Criteria

- [ ] Policy configuration ends with an explicit fallback rule (`deny("*")`).
- [ ] Interactive handlers return non-blocking `Future<bool>` decisions.
- [ ] File operations enforce workspace path containment checks (`p.isWithin`).


