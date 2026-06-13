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

/// Example demonstrating background triggers.
///
/// Triggers are long-lived async functions that run in the background alongside
/// an active agent session. They react to external events (timers, file
/// changes, webhooks) and push automated trigger notifications back to the
/// agent connection.
///
/// This example demonstrates:
/// 1. Periodic Triggers using the [every] helper — simulating SRE ticket queues.
/// 2. Custom Triggers using a plain Dart async function decorated as a [Trigger]
///    — simulating a CI/CD webhook listener.
///
/// To run:
///   dart run example/getting_started/triggers.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The periodic trigger fires and sends a system alert to the agent.
///   3. The custom CI/CD trigger fires and sends a build failure alert.
///   4. The agent acknowledges the trigger notifications in its responses.
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'package:antigravity/antigravity.dart';

// =============================================================================
// 1. PERIODIC TRIGGER: Customer Support Ticket Queue
// =============================================================================

int _ticketCounter = 0;
bool _standbyActive = false;

/// Callback for the periodic trigger — polls a simulated support ticket queue.
Future<void> _pollQueueCallback(TriggerContext ctx) async {
  // Avoid polling before Turn 1 completes to prevent race conditions.
  if (!_standbyActive) return;

  _ticketCounter++;

  // On the second tick after standby starts, simulate a ticket arrival.
  if (_ticketCounter == 2) {
    print('\n  [TRIGGER EVENT] Alert! New ticket detected in the queue…');
    await ctx.send(
      '[SYSTEM ALERT] New critical ticket assigned: b/98765. '
      'Title: Database Connection Leak in Prod.',
    );
  }
}

Future<void> _runPeriodicTriggerExample() async {
  print('  === Support Queue Trigger Demo ===');
  print('  Creating agent and starting session…');

  _ticketCounter = 0;
  _standbyActive = false;

  // Configure a trigger that checks every 1 second for demonstration.
  final myTrigger = every(const Duration(seconds: 1), _pollQueueCallback);

  final config = LocalAgentConfig(
    systemInstructions:
        'You are a system operations and support assistant. You monitor a '
        'queue of incoming support tickets. When the user asks for updates, '
        'you must check and report any tickets that came in from the '
        'background system alert trigger.',
    triggers: [myTrigger],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    // Turn 1: Instruct the agent to watch.
    const prompt1 =
        'Your task will be to standby and simply let me know if there are any '
        'critical tickets received.';
    print('\n  User: $prompt1');
    final response1 = await agent.chat(prompt1);
    print('  Agent: ${await response1.text()}');

    // Turn 1 resolved — enable the standby trigger.
    _standbyActive = true;

    // Sleep to let the background task execute.
    print(
      '\n  Sleeping for 5 seconds. A new ticket will be simulated '
      'in the background…',
    );
    await Future.delayed(const Duration(seconds: 5));

    // Turn 2: Ask for updates.
    const prompt2 =
        "I'm back. Did anything critical come in while I was working?";
    print('\n  User: $prompt2');
    final response2 = await agent.chat(prompt2);
    print('  Agent: ${await response2.text()}');

    print('\n  Ending session. Background triggers will stop automatically.');
  } finally {
    await agent.stop();
  }
}

// =============================================================================
// 2. CUSTOM TRIGGER: CI/CD Webhook Alert Listener
// =============================================================================

bool _webhookActive = false;

/// A custom trigger — any async function with signature `Future<void> Function(TriggerContext)`.
Future<void> _webhookListener(TriggerContext ctx) async {
  print('\n  [WEBHOOK TRIGGER] Custom Webhook listener started…');

  int tick = 0;
  while (!ctx.isCancelled) {
    await Future.delayed(const Duration(seconds: 1));
    if (!_webhookActive) continue;
    tick++;
    // On the third tick inside standby, push a simulated build failure alert.
    if (tick == 3) {
      print(
        "\n  [WEBHOOK TRIGGER] Event received: 'AppBuild-42' status FAILED.",
      );
      await ctx.send(
        "[WEBHOOK ALERT] CI/CD Build Pipeline 'AppBuild-42' FAILED on "
        "branch 'main'. Reason: Lint errors in routes.py.",
      );
    }
  }
}

Future<void> _runCustomTriggerExample() async {
  print('  === Custom Webhook Trigger Demo ===');
  print('  Creating agent and starting session…');

  _webhookActive = false;

  final config = LocalAgentConfig(
    systemInstructions:
        'You are a CI/CD operations assistant. You monitor pipeline status '
        'via an external webhook trigger. When the user asks for updates, '
        'you must check and report any failures that came in from the '
        'webhook alert trigger.',
    triggers: [_webhookListener],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt1 =
        'Your task will be to standby and simply let me know if there are any '
        'critical pipeline webhook alerts received.';
    print('\n  User: $prompt1');
    final response1 = await agent.chat(prompt1);
    print('  Agent: ${await response1.text()}');

    _webhookActive = true;

    print(
      '\n  Sleeping for 5 seconds. A pipeline failure will be simulated '
      'in the background…',
    );
    await Future.delayed(const Duration(seconds: 5));

    const prompt2 = "I'm back. Any updates on my builds?";
    print('\n  User: $prompt2');
    final response2 = await agent.chat(prompt2);
    print('  Agent: ${await response2.text()}');

    print('\n  Ending session. Background triggers will stop automatically.');
  } finally {
    await agent.stop();
  }
}

// =============================================================================
// Main
// =============================================================================

Future<void> main() async {
  await _runPeriodicTriggerExample();
  print('\n${'=' * 60}\n');
  await _runCustomTriggerExample();
}
