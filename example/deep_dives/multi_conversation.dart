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

/// Advanced example demonstrating managing multiple independent conversations.
///
/// This example showcases two patterns mentioned in the Conversation design documentation:
/// 1. **Approach A (Multi-Agent System - Layer 1 API)**:
///    Creating separate [Agent] instances with distinct system instructions (Wendy the Writer
///    and Connor the Critic). Demonstrates using `.copyWith()` for easy configuration branching.
/// 2. **Approach B (Direct Conversation Layer - Layer 2 API)**:
///    Creating multiple stateful [Conversation] sessions using separate connection strategies,
///    allowing direct control over step-level streams and isolated branching contexts.
///
/// To run:
///   dart run example/deep_dives/multi_conversation.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'package:antigravity/antigravity.dart';

void _printHeader(String title) {
  final line = '=' * 70;
  print('\n$line');
  print('🔮 $title');
  print('$line\n');
}

void _printSubHeader(String title) {
  print('\n--- $title ---');
}

// ============================================================================
// Approach A: Multi-Agent Collaboration (Layer 1 API)
// ============================================================================
Future<void> runMultiAgentScenario() async {
  _printHeader("Approach A: Multi-Agent Collaboration (Wendy & Connor)");

  // 1. Base configuration for agents
  final baseConfig = LocalAgentConfig(
    model: 'gemini-3.5-flash',
    policies: [allowAll()],
  );

  // 2. Configure Wendy using copyWith()
  final wendyConfig = baseConfig.copyWith(
    systemInstructions: CustomSystemInstructions(
      text:
          "You are Wendy, a creative micro-fiction writer. Write beautiful, imaginative "
          "micro-stories that are strictly under 3 sentences. When given advice or "
          "criticism by Connor the Critic, rewrite your story to elegantly incorporate it.",
    ),
  );

  // 3. Configure Connor using copyWith() from wendyConfig (overriding only instructions)
  final connorConfig = wendyConfig.copyWith(
    systemInstructions: CustomSystemInstructions(
      text:
          "You are Connor, a strict literary critic. Be highly constructive, brief, "
          "and point out exactly one specific improvement regarding vocabulary, pacing, or imagery. "
          "Limit your review to 2 sentences.",
    ),
  );

  final wendy = Agent(wendyConfig);
  final connor = Agent(connorConfig);

  print("🚀 Starting Wendy (Writer Agent) and Connor (Critic Agent)...");
  await wendy.start();
  await connor.start();

  try {
    // Step 1: User prompts Wendy to write a story
    final prompt =
        "Write a sci-fi micro-story about a robot learning to paint flowers.";
    print('\n[User -> Wendy]: "$prompt"');

    print('\n[Wendy is writing...]');
    final wendyResponse1 = await wendy.chat(prompt);
    final wendyStory1 = (await wendyResponse1.text()).trim();
    print(' Wendy\'s Story (Draft 1):\n"$wendyStory1"');

    // Step 2: Connor reviews the story
    final reviewPrompt =
        "Please critique this micro-story constructive and suggest one upgrade:\n$wendyStory1";
    print('\n[Wendy -> Connor]: (sending draft for review)');

    print('\n[Connor is analyzing...]');
    final connorResponse = await connor.chat(reviewPrompt);
    final connorReview = (await connorResponse.text()).trim();
    print(' Connor\'s Critique:\n"$connorReview"');

    // Step 3: Wendy rewrites incorporating Connor's advice
    final rewritePrompt =
        "Connor the Critic provided the following advice: '$connorReview'. "
        "Please rewrite your previous story incorporating this advice.";
    print('\n[Connor -> Wendy]: (sending critique for revision)');

    print('\n[Wendy is revising...]');
    final wendyResponse2 = await wendy.chat(rewritePrompt);
    final wendyStory2 = (await wendyResponse2.text()).trim();
    print(' Wendy\'s Revised Story (Draft 2):\n"$wendyStory2"');

    // Step 4: Verification of Isolated History
    _printSubHeader("Verifying Conversation Histories Are Strictly Isolated");
    print("Wendy's turn count: ${wendy.conversation.turnCount} turns.");
    print("Connor's turn count: ${connor.conversation.turnCount} turns.");

    print("\nWendy's full trajectory summary:");
    for (int i = 0; i < wendy.conversation.history.length; i++) {
      final step = wendy.conversation.history[i];
      if (step.type == StepType.textResponse && step.content.isNotEmpty) {
        // Step is a data class with value equality and copyWith
        print(
          "  [$i] ${step.source.name.toUpperCase()}: ${step.content.substring(0, step.content.length > 50 ? 50 : step.content.length)}...",
        );
      }
    }

    print("\nConnor's full trajectory summary:");
    for (int i = 0; i < connor.conversation.history.length; i++) {
      final step = connor.conversation.history[i];
      if (step.type == StepType.textResponse && step.content.isNotEmpty) {
        print(
          "  [$i] ${step.source.name.toUpperCase()}: ${step.content.substring(0, step.content.length > 50 ? 50 : step.content.length)}...",
        );
      }
    }
  } finally {
    print("\nStopping Wendy and Connor agents...");
    await wendy.stop();
    await connor.stop();
  }
}

// ============================================================================
// Approach B: Direct Conversation Layer (Layer 2 API)
// ============================================================================
Future<void> runDirectConversationScenario() async {
  _printHeader("Approach B: Direct Stateful Conversations on Strategies");

  // Define a single configuration.
  final config = LocalAgentConfig(
    model: 'gemini-3.5-flash',
    systemInstructions:
        "You are an academic trivia database assistant. Answer questions as "
        "briefly as possible (1 sentence maximum). Keep memory of the context.",
    policies: [allowAll()],
  );

  final toolRunner = ToolRunner(tools: []);
  final hookRunner = HookRunner();
  hookRunner.registerHook(enforce([allowAll()]));

  // Spawn two separate strategies/connections to guarantee isolated process contexts.
  final strategyScience = config.createStrategy(
    toolRunner: toolRunner,
    hookRunner: hookRunner,
  );

  final strategyHistory = config.createStrategy(
    toolRunner: toolRunner,
    hookRunner: hookRunner,
  );

  print("🚀 Initializing isolated Layer 2 Conversations...");
  final conversationScience = await Conversation.create(strategyScience);
  final conversationHistory = await Conversation.create(strategyHistory);

  try {
    // Turn 1: Interleaved questions to both conversations
    print("\n[Sending parallel Turn 1...]");

    final promptSci1 = "What is the nearest star to Earth besides the Sun?";
    print('  -> Science Conversation: "$promptSci1"');
    final respSci1 = await conversationScience.chat(promptSci1);
    final ansSci1 = await respSci1.text();
    print('  <- Science Answer: ${ansSci1.trim()}');

    final promptHist1 = "Who was the first President of the United States?";
    print('  -> History Conversation: "$promptHist1"');
    final respHist1 = await conversationHistory.chat(promptHist1);
    final ansHist1 = await respHist1.text();
    print('  <- History Answer: ${ansHist1.trim()}');

    // Turn 2: Follow-up questions relying on isolated state
    print("\n[Sending stateful follow-up Turn 2...]");

    // The Science conversation must remember the nearest star is Proxima Centauri
    final promptSci2 = "How far away is it in light years?";
    print('  -> Science Conversation: "$promptSci2"');
    final respSci2 = await conversationScience.chat(promptSci2);
    final ansSci2 = await respSci2.text();
    print('  <- Science Answer: ${ansSci2.trim()}');

    // The History conversation must remember the president is George Washington
    final promptHist2 = "When and where was he born?";
    print('  -> History Conversation: "$promptHist2"');
    final respHist2 = await conversationHistory.chat(promptHist2);
    final ansHist2 = await respHist2.text();
    print('  <- History Answer: ${ansHist2.trim()}');

    // Turn 3: Cross-verification to confirm zero leaks
    _printSubHeader("Validating Complete Session Independence");
    print("Science Turn Count: ${conversationScience.turnCount}");
    print("History Turn Count: ${conversationHistory.turnCount}");

    print("\nScience Conversation memory checkpoint:");
    print("  Last response was: '${conversationScience.lastResponse.trim()}'");

    print("\nHistory Conversation memory checkpoint:");
    print("  Last response was: '${conversationHistory.lastResponse.trim()}'");
  } finally {
    print("\nDisconnecting conversation strategies...");
    await conversationScience.disconnect();
    await conversationHistory.disconnect();
  }
}

Future<void> main() async {
  print("🌌 Unofficial Google Antigravity SDK - Multi-Conversation Demo 🌌");

  try {
    await runMultiAgentScenario();
    await runDirectConversationScenario();
    _printHeader("All Scenarios Completed Successfully! 🎉");
  } catch (e, stack) {
    print("❌ Critical Error during execution: $e");
    print(stack);
  }
}
