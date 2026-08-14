# Local Inference & Retry Configuration Patterns

Disclosed reference file containing setup code for LiteRT, OpenAI-compatible local servers, and `RetryConfig` presets in Dart.

## 1. LiteRT Local Gemma Execution

```dart
import 'package:antigravity/antigravity.dart';

final config = LiteRTAgentConfig(
  modelPath: '/path/to/gemma-2b-it-gpu.task',
  maxContextTokens: 16384,
  systemInstructions: 'You are a local privacy-first assistant.',
);

final agent = Agent(config);
await agent.start();
```

## 2. Local OpenAI-Compatible Server (Ollama / LM Studio)

```dart
final config = LocalOpenAIAgentConfig(
  baseUrl: 'http://localhost:11434/v1',
  model: 'llama3:latest',
  apiKey: 'ollama', // optional stub key for local endpoints
);
```

## 3. Exponential Backoff & Retry Presets

```dart
final retryConfig = RetryConfig(
  apiRetry: ModelAPIRetryConfig(
    maxRetries: 5,
    initialSleepDuration: const Duration(seconds: 1),
    jitterRange: 0.2, // 20% randomized jitter
  ),
  modelOutputRetry: ModelOutputRetryConfig(
    maxRetries: 3,
  ),
);

final config = LocalAgentConfig(
  retryConfig: retryConfig,
);
```
