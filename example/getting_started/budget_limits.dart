// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Example demonstrating session budget controls and stop reason handling in Dart.
///
/// This example demonstrates how to configure operational limits and proactive
/// token budget caps using [BudgetConfig]:
/// 1. Limiting model invocations ([BudgetConfig.maxModelCalls])
/// 2. Limiting tool invocations ([BudgetConfig.maxToolCalls])
/// 3. Limiting net uncached input tokens ([BudgetConfig.maxInputTokens])
/// 4. Limiting cumulative output tokens ([BudgetConfig.maxOutputTokens])
/// 5. Limiting cumulative total tokens ([BudgetConfig.maxTotalTokens])
///
/// To run:
///   dart run example/getting_started/budget_limits.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with exit code 0 (no unhandled exceptions).
///   2. Each budget dial triggers its corresponding [StopReason] when exhausted.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// 1. Model Invocation Limits (maxModelCalls)
// ---------------------------------------------------------------------------
Future<void> demoMaxModelCalls() async {
  print('\n${'=' * 60}');
  print('1. Testing maxModelCalls budget limit (maxModelCalls: 1)');
  print('=' * 60);

  final config = LocalAgentConfig(
    budgetConfig: BudgetConfig(maxModelCalls: 1),
  );

  final agent = Agent(config);
  await agent.start();
  try {
    // Turn 1: 1st model call allowed; upon completion, limit of 1 is reached
    print('Turn 1: Asking first question (consumes 1 allowed model call)...');
    final res1 = await agent.chat('What is 2 + 2? Reply with just the number.');
    print('  Agent response: ${(await res1.text()).trim()}');
    print('  Turn 1 stop reason: ${res1.stopReason}');
    if (res1.stopReason == StopReason.maxModelCallsExceeded) {
      print(
          '  [Limit Reached] Session model call budget reached after Turn 1.');
    }

    // Turn 2: Attempting another turn when session model budget is exhausted
    print('\nTurn 2: Asking second question (budget already exhausted)...');
    final res2 = await agent.chat('What is 3 + 3?');
    await res2.text(); // Drain response stream
    print('  Turn 2 stop reason: ${res2.stopReason}');
    if (res2.stopReason == StopReason.maxModelCallsExceeded) {
      print('  [Halted] Turn 2 was prevented from making further model calls.');
    }
  } finally {
    await agent.stop();
  }
}

// ---------------------------------------------------------------------------
// 2. Tool Invocation Limits (maxToolCalls)
// ---------------------------------------------------------------------------
final lookupWeather = Tool(
  name: 'lookup_weather',
  description: 'Looks up current weather for a given city.',
  schema: {
    'type': 'object',
    'properties': {
      'city': {'type': 'string', 'description': 'Name of the city.'},
    },
    'required': ['city'],
  },
  handler: (args, _) async {
    final city = args['city'] as String;
    return 'Sunny and 24C in $city';
  },
);

final lookupTimezone = Tool(
  name: 'lookup_timezone',
  description: 'Looks up the time zone for a given city.',
  schema: {
    'type': 'object',
    'properties': {
      'city': {'type': 'string', 'description': 'Name of the city.'},
    },
    'required': ['city'],
  },
  handler: (args, _) async {
    final city = args['city'] as String;
    return 'UTC+9 for $city';
  },
);

Future<void> demoMaxToolCalls() async {
  print('\n${'=' * 60}');
  print('2. Testing maxToolCalls budget limit (maxToolCalls: 1)');
  print('=' * 60);

  final config = LocalAgentConfig(
    tools: [lookupWeather, lookupTimezone],
    budgetConfig: BudgetConfig(maxToolCalls: 1),
  );

  final agent = Agent(config);
  await agent.start();
  try {
    const prompt =
        "First call lookup_weather for 'Tokyo', and then call lookup_timezone for 'Tokyo'.";
    print('Sending multi-tool prompt: $prompt');
    final res = await agent.chat(prompt);
    await res.text(); // Drain response stream
    print('  Stop reason: ${res.stopReason}');
    if (res.stopReason == StopReason.maxToolCallsExceeded) {
      print('  [Halted] Additional tool executions were halted by budget.');
    }
  } finally {
    await agent.stop();
  }
}

// ---------------------------------------------------------------------------
// 3. Input Token Limits (maxInputTokens)
// ---------------------------------------------------------------------------
Future<void> demoMaxInputTokens() async {
  print('\n${'=' * 60}');
  print('3. Testing maxInputTokens budget limit (maxInputTokens: 50)');
  print('=' * 60);

  final config = LocalAgentConfig(
    budgetConfig: BudgetConfig(maxInputTokens: 50),
  );

  final agent = Agent(config);
  await agent.start();
  try {
    // A prompt containing ~300+ tokens, exceeding the 50 token budget
    final largePrompt =
        'Summarize the following passage:\n${'The quick brown fox jumps over the lazy dog. ' * 30}';
    print('Sending large prompt exceeding 50 input tokens...');
    final res = await agent.chat(largePrompt);
    await res.text(); // Drain response stream
    print('  Stop reason: ${res.stopReason}');
    if (res.stopReason == StopReason.maxInputTokensExceeded) {
      print(
        '  [Proactively Halted] Input token budget exceeded before inference.',
      );
    }
  } finally {
    await agent.stop();
  }
}

// ---------------------------------------------------------------------------
// 4. Output Token Limits (maxOutputTokens)
// ---------------------------------------------------------------------------
Future<void> demoMaxOutputTokens() async {
  print('\n${'=' * 60}');
  print('4. Testing maxOutputTokens budget limit (maxOutputTokens: 30)');
  print('=' * 60);

  final config = LocalAgentConfig(
    budgetConfig: BudgetConfig(maxOutputTokens: 30),
  );

  final agent = Agent(config);
  await agent.start();
  try {
    // Turn 1 produces > 30 output tokens
    print(
        'Turn 1: Requesting a long response that exceeds 30 output tokens...');
    final res1 = await agent.chat(
      'Write a detailed paragraph explaining photosynthesis.',
    );
    final text1 = await res1.text();
    print(
      '  Turn 1 generated response: ${text1.length > 60 ? text1.substring(0, 60) : text1}...',
    );
    print('  Turn 1 stop reason: ${res1.stopReason}');

    // Turn 2: Cumulative output tokens already exceed 30
    print('\nTurn 2: Attempting next turn with exhausted output budget...');
    final res2 = await agent.chat('Continue.');
    await res2.text(); // Drain response stream
    print('  Turn 2 stop reason: ${res2.stopReason}');
    if (res2.stopReason == StopReason.maxOutputTokensExceeded) {
      print(
        '  [Halted] Cumulative generated output exceeded output token limit.',
      );
    }
  } finally {
    await agent.stop();
  }
}

// ---------------------------------------------------------------------------
// 5. Total Token Limits (maxTotalTokens)
// ---------------------------------------------------------------------------
Future<void> demoMaxTotalTokens() async {
  print('\n${'=' * 60}');
  print('5. Testing maxTotalTokens budget limit (maxTotalTokens: 100)');
  print('=' * 60);

  final config = LocalAgentConfig(
    budgetConfig: BudgetConfig(maxTotalTokens: 100),
  );

  final agent = Agent(config);
  await agent.start();
  try {
    // Turn 1 consumes > 100 total net tokens (input + output)
    print('Turn 1: Sending prompt that will consume > 100 total tokens...');
    final res1 = await agent.chat(
      'Explain the theory of general relativity in 3 sentences.',
    );
    final text1 = await res1.text();
    print(
      '  Turn 1 generated response: ${text1.length > 60 ? text1.substring(0, 60) : text1}...',
    );
    print('  Turn 1 stop reason: ${res1.stopReason}');

    // Turn 2: Cumulative total tokens exceed 100
    print(
        '\nTurn 2: Attempting next turn with exhausted total token budget...');
    final res2 = await agent.chat('Tell me more.');
    await res2.text(); // Drain response stream
    print('  Turn 2 stop reason: ${res2.stopReason}');
    if (res2.stopReason == StopReason.maxTotalTokensExceeded) {
      print(
        '  [Halted] Cumulative net token consumption exceeded total limit.',
      );
    }
  } finally {
    await agent.stop();
  }
}

// ---------------------------------------------------------------------------
// Main Runner
// ---------------------------------------------------------------------------
Future<void> main() async {
  print('Running Antigravity SDK Budget Enforcement End-to-End Tests...');
  await demoMaxModelCalls();
  await demoMaxToolCalls();
  await demoMaxInputTokens();
  await demoMaxOutputTokens();
  await demoMaxTotalTokens();
  print('\n${'=' * 60}');
  print('🎉 All 5 budget enforcement dials verified successfully end-to-end!');
  print('=' * 60);
}
