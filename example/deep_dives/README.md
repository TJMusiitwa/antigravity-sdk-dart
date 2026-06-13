# Deep Dives (Dart SDK)

Multi-feature examples that combine several SDK concepts into realistic mini-applications. Each example is self-contained and runnable — start with any that matches your use case.

> **Prerequisite:** Make sure you can run the basics first. See the getting started examples. Ensure your `GEMINI_API_KEY` is exported in your environment.

---

## 🔌 Middleware & Lifecycle

### [agent_middleware.dart](agent_middleware.dart)
**Hook middleware: transparent tool interception.**

Demonstrates how stacked hooks create emergent behavior the agent is unaware of. The agent calls tools normally; hooks enforce rate limits, log an audit trail, and recover from errors — all without the agent's knowledge.

**Concepts:** `PreToolCallDecideHook`, `PostToolCallHook`, `OnToolErrorHook`, hook composition.

```bash
dart run example/deep_dives/agent_middleware.dart
```

### [host_tool_hooks.dart](host_tool_hooks.dart)
**Every supported lifecycle hook wired and logged.**

Registers one hook for each supported lifecycle event and logs what was received — session start/end, pre/post turn, pre/post tool call, tool errors, compaction, interaction, and subagent hooks.

**Concepts:** `OnSessionStartHook`, `OnSessionEndHook`, `PreTurnHook`, `PostTurnHook`, `OnCompactionHook`, `OnInteractionHook`.

```bash
dart run example/deep_dives/host_tool_hooks.dart
```

---

## 💬 Multi-Agent Chat

### [round_based_chat.dart](round_based_chat.dart)
**Synchronized parallel agent chat room with opt-out.**

Three agents discuss topics as equals. All agents process in parallel each round via `Future.wait`. Each can call `passTurn()` to stay silent. Conversation continues until all agents pass or the max depth is reached.

**Concepts:** Custom tools, triggers, `Future.wait` parallelism, incremental prompt construction.

```bash
dart run example/deep_dives/round_based_chat.dart
```

### [async_chat.dart](async_chat.dart)
**Fully async peer-to-peer agent chat — no rounds.**

Each agent runs its own independent loop and reacts whenever any peer posts a new message. Ordering is emergent — whoever finishes `agent.chat()` first gets the next word. Uses a `StreamController.broadcast` event loop to signal state changes cleanly.

**Concepts:** Broadcast stream event loops, reactive wake-up, custom tools, self-terminating conversations.

```bash
dart run example/deep_dives/async_chat.dart
```

---

## 🎨 Multimodal

### [multimodal_pipeline.dart](multimodal_pipeline.dart)
**Generator/discriminator pipeline with multimodal I/O.**

A two-agent pipeline: a Generator creates an image using the built-in `generate_image` tool, then a completely separate Discriminator receives only the raw image bytes (no filename) and describes what it sees — demonstrating true end-to-end multimodal input.

**Concepts:** `generate_image` built-in tool, `Image` content type, multimodal `Content` input, independent agent instances.

```bash
dart run example/deep_dives/multimodal_pipeline.dart
```

---

## 🤖 Autonomous Agents

### [doc_maintenance_agent.dart](doc_maintenance_agent.dart)
**Autonomous documentation agent scoped to `.md` files.**

An agent that reads source code and ensures corresponding markdown documentation is accurate and up-to-date. Fine-grained policies restrict editing to `.md` files within a target directory.

**Concepts:** `allow` / `deny` policies, conditional `when:` predicates, `CapabilitiesConfig`, workspace scoping.

```bash
dart run example/deep_dives/doc_maintenance_agent.dart [directory]
```

### [docstring_maintenance_agent.dart](docstring_maintenance_agent.dart)
**Autonomous docstring agent scoped to `.dart` files.**

Audits all Dart files in a directory and ensures public symbols have high-quality Dart doc comments (`///`). Destructive tools (`createFile`, `runCommand`) are explicitly disabled via `CapabilitiesConfig`.

**Concepts:** `BuiltinTools` enum, `disabledTools`, policy-based file-type filtering, workspace scoping.

```bash
dart run example/deep_dives/docstring_maintenance_agent.dart [directory]
```

---

## 🖥️ Interactive

### [interactive_cli.dart](interactive_cli.dart)
**Full interactive CLI with custom tools and tool approval.**

A complete interactive agent session with custom Dart tools (including custom pirate math tools), hook-based tool approval via `askUser`, streaming responses, and optional token usage telemetry.

**Concepts:** Custom `Tool` definitions, `askUser` policy, custom `OnInteractionHook` (`AskQuestionHook`), `CapabilitiesConfig`, streaming, `UsageMetadata`.

```bash
dart run example/deep_dives/interactive_cli.dart [--show_usage]
```

### [multi_conversation.dart](multi_conversation.dart)
**Coordinating multiple independent or collaborative conversations.**

Demonstrates both approaches to managing multiple conversation threads:
1. **Approach A (Multi-Agent System - Layer 1 API)**: Two separate `Agent` instances (Wendy the Writer and Connor the Critic) collaborate iteratively while maintaining strictly isolated histories.
2. **Approach B (Direct Conversation Layer - Layer 2 API)**: Multiple stateful `Conversation` sessions created directly from connection strategies for isolated contextual branching.

**Concepts:** Collaborative agent workflows, direct Layer 2 `Conversation` API, `ConnectionStrategy` instantiation, context isolation.

```bash
dart run example/deep_dives/multi_conversation.dart
```
