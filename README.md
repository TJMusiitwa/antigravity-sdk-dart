# Antigravity SDK for Dart 🌌

[![pub package](https://img.shields.io/badge/pub-v0.0.1-blue.svg)](https://pub.dev/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Dart Analyze & Test](https://github.com/google/antigravity-sdk-dart/actions/workflows/dart.yml/badge.svg)](https://github.com/)

> [!IMPORTANT]
> **Disclaimer:** This is a community-maintained, unofficial Dart & Flutter port of the Google Antigravity SDK. It is not affiliated with, sponsored by, or endorsed by Google or the official Antigravity team.

A pure Dart & Flutter port of the **Google Antigravity SDK**. 

The Google Antigravity SDK provides a secure, scalable, and stateful infrastructure layer that abstracts the agentic loop, letting you build advanced AI agents powered by Antigravity and Gemini. Focus on what your agent *does* rather than how it runs, handles tools, or manages state.

---

## ⚡ Quickstart

Get started by running the `hello_world.dart` example:

```bash
# 1. Set your Gemini API Key
export GEMINI_API_KEY="your_api_key_here"

# 2. Run the hello world example
dart run example/getting_started/hello_world.dart
```

> [!NOTE]
> **Zero Configuration:** You do *not* need to manually install the Python SDK or download the orchestration harness binary. On the first run, the SDK will automatically detect your platform (OS and CPU architecture), download the official precompiled `localharness` binary from PyPI, extract it, and cache it locally in `~/.antigravity/bin/`.

---

## 🏗️ Architecture

The SDK is organized into a clean, decoupled three-layer architecture:

| Layer | Purpose | Key Classes / Files |
| :--- | :--- | :--- |
| **Layer 1 — Simplified** | High-level, batteries-included async agent session | `Agent` |
| **Layer 2 — Session & Runs** | Stateful session management, history accumulation, tool/trigger runners | `Conversation`, `ChatResponse`, `Step`, `ToolCall`, `HookRunner`, `TriggerRunner` |
| **Layer 3 — Adapter & Transport** | Low-level binary communication and transport serialization | `Connection`, `LocalConnection`, `LocalAgentConfig`, `BinaryDiscovery` |

---

## 🧩 Key Concepts & Usage

### 1. Simple Agent Lifecycle
The `Agent` class handles binary discovery, stateful connection setup, tool dispatch, hooks, and policy enforcement behind a simple async lifecycle.

```dart
import 'package:antigravity/antigravity.dart';

void main() async {
  final config = LocalAgentConfig(
    systemInstructions: "You are an expert software developer assisting with code reviews.",
  );

  final agent = Agent(config);
  await agent.start();

  try {
    final response = await agent.chat("What files are in the current workspace?");
    print("Agent reply: ${await response.text()}");
  } finally {
    await agent.stop();
  }
}
```

### 2. Streaming Thoughts & Text Tokens
Stream thoughts (internal model reasoning) or chat text tokens reactively in real time:

```dart
final response = await agent.chat("Write a short poem about gravity.");

// Stream text tokens as they arrive from the model
await for (final token in response.textStream) {
  stdout.write(token);
}

// Or stream reasoning thoughts (internal model thinking process)
await for (final thought in response.thoughtStream) {
  print("Thinking bubble delta: $thought");
}
```

### 3. Declarative Safety Policies
Protect your local filesystem and commands with priority-bucketed declarative safety policies:

```dart
final policies = [
  deny("*"), // Deny all tools by default
  allow("view_file"), // Safely permit reading files
  askUser("run_command", handler: myInteractiveCmdHandler), // Ask user on CLI before running commands
];

final config = LocalAgentConfig(
  capabilities: CapabilitiesConfig(), // Enable tool execution capabilities
  policies: policies,
);
```

### 4. Stateful & Stateless Custom Tools
Directly register standard Dart functions as tools that your agent can invoke dynamically:

```dart
// Register any function as a tool
String getSystemWeather(String city) {
  return "It is currently sunny and 22°C in $city.";
}

final config = LocalAgentConfig(
  tools: [getSystemWeather],
);
```

### 5. Automated Background Triggers
Execute continuous background tasks that react to external changes or cron schedules, and safely inject messages back into the agentic loop:

```dart
import 'dart:async';

Future<void> runDeploymentMonitor(TriggerContext ctx) async {
  // Check external systems and inject messages to the agent
  await ctx.send("Check if deployment finished successfully.");
}

final config = LocalAgentConfig(
  triggers: [
    every(Duration(minutes: 5), runDeploymentMonitor),
  ],
);
```

---

## 🧪 Testing

To run the full suite of unit and integration tests (including varint protobuf handshake encoding, binary discovery, safety policy enforcement, and workspace path containment):

```bash
dart test
```

To run static analysis and linting:

```bash
dart analyze
```

---

## 📂 Examples Directory

The [`example/`](example/) directory contains high-fidelity ports of every script from the official Python SDK, categorized by complexity:

### Getting Started
| File | Focus Concept |
| :--- | :--- |
| `example/getting_started/hello_world.dart` | Basic agent prompt & await response |
| `example/getting_started/streaming.dart` | Streams conversational tokens & reasoning chunks |
| `example/getting_started/custom_tools.dart` | Registers custom functional tools with the agent |
| `example/getting_started/hooks.dart` | Demonstrates all nine lifecycle hooks |
| `example/getting_started/policies.dart` | Integrates priority policies (deny, allow, ask) |
| `example/getting_started/persistence.dart` | Resumes sessions from disk-backed `saveDir` |
| `example/getting_started/triggers.dart` | Periodic and custom trigger invocation |
| `example/getting_started/structured_output.dart`| Forces schema-conforming JSON structure responses |
| `example/getting_started/observability.dart` | Audits token counts and internal metrics |
| `example/getting_started/autonomous_shell.dart` | Provides an autonomous shell agent run |
| `example/getting_started/multimodal.dart` | Ingests mixed text, images, and document attachments |
| `example/getting_started/human_in_the_loop.dart`| Implements stdin-based interactive confirmation |

### Deep Dives
| File | Focus Concept |
| :--- | :--- |
| `example/deep_dives/agent_middleware.dart` | Hook middleware for transparent tool interception |
| `example/deep_dives/async_chat.dart` | Fully async peer-to-peer agent chat with broadcast events |
| `example/deep_dives/doc_maintenance_agent.dart` | Autonomous documentation agent with file-type policies |
| `example/deep_dives/docstring_maintenance_agent.dart`| Autonomous docstring audit agent for Dart files |
| `example/deep_dives/host_tool_hooks.dart` | Exhaustive implementation of all lifecycle hooks |
| `example/deep_dives/interactive_cli.dart` | Interactive CLI with custom tools & human-in-the-loop |
| `example/deep_dives/multi_conversation.dart` | Managing parallel threads with Agents or direct Layer 2 |
| `example/deep_dives/multimodal_pipeline.dart` | Image generation & vision discriminator pipeline |
| `example/deep_dives/round_based_chat.dart` | Synchronized multi-agent discussion room |

For detailed information on how to configure and run each example, check out the [Example getting-started guide](example/README.md).

---

## 📄 License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
