---
name: antigravity-local-inference-dart
description: "Configure local Gemma models via LiteRTAgentConfig, OpenAI-compatible backends, or custom ModelEndpoints with RetryConfig in Dart."
---

# Local Inference, Custom Endpoints & Model Retry Tuning in Dart

Guidelines for running local Gemma models via LiteRT, connecting to local OpenAI-compatible backends (Ollama/LM Studio), configuring custom `ModelEndpoint` instances, and tuning retry backoff.

## 1. Local Model Execution (LiteRT & OpenAI)

1. **LiteRT Setup**: Use `LiteRTAgentConfig(modelPath: "path/to/gemma.task")` to run local Gemma inference via Python loopback HTTP server.
2. **OpenAI Endpoint Integration**: Use `LocalOpenAIAgentConfig(baseUrl: "http://localhost:11434/v1", model: "llama3")` for Ollama, LM Studio, or local vLLM instances.

For code examples, inspect [`references/inference_patterns.md`](file://references/inference_patterns.md).

## 2. Model Endpoint Switching & Retry Backoff Configurations

- **Model Endpoints**: Switch between `GeminiAPIEndpoint` and `VertexEndpoint` (with automatic project/location resolution).
- **Retry & Backoff**: Pass `RetryConfig.benchmark()` or tune `ModelAPIRetryConfig(maxRetries: 5, initialSleepDuration: Duration(seconds: 2))` to handle transient network errors gracefully.

For code patterns, read [`references/inference_patterns.md`](file://references/inference_patterns.md).

## Completion Criteria

- [ ] `LiteRTAgentConfig` model file path existence is verified before initialization.
- [ ] `LocalOpenAIAgentConfig` base URL includes protocol and port (`http://localhost:11434/v1`).
- [ ] Retry backoff limits (`maxRetries`, `initialSleepDuration`) are explicitly set for unstable networks.
