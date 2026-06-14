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

/// Fully async peer-to-peer agent chat — no rounds.
///
/// Contrast with round_based_chat.dart which uses synchronized parallel
/// rounds. Here, each agent runs its own independent loop and reacts
/// whenever any peer posts a new message. Ordering is emergent — whoever
/// finishes agent.chat() first gets the next word.
///
/// Run with:
///   dart run example/deep_dives/async_chat.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';

import 'package:antigravity/antigravity.dart';

const String _passToken = "[PASS]";
const int _maxConsecutivePasses = 2; // agent exits after N passes in a row
const Duration _discussionTimeout = Duration(seconds: 40);

// ---------------------------------------------------------------------------
// Custom function: opt-out
// ---------------------------------------------------------------------------

Future<String> passTurn() async {
  return _passToken;
}

final passTurnTool = Tool(
  name: 'passTurn',
  description: 'Passes the turn if you have nothing to add.',
  schema: {'type': 'object', 'properties': {}},
  handler: (_, __) => passTurn(),
);

// ---------------------------------------------------------------------------
// Async chat room — no rounds, fully reactive
// ---------------------------------------------------------------------------

class AsyncChatRoom {
  final List<MapEntry<String, String>> history = [];
  final Map<String, Agent> _agents;
  final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  bool _done = false;

  AsyncChatRoom(this._agents);

  Stream<void> get onChange => _changeController.stream;

  void postMessage(String sender, String text) {
    history.add(MapEntry(sender, text));
    _changeController.add(null);
  }

  void complete() {
    if (_done || _changeController.isClosed) return;
    _done = true;
    _changeController.add(null);
    _changeController.close();
  }

  Future<void> discuss(String topic) async {
    print('\n${'=' * 60}');
    print('💬 Topic: $topic');
    print('=' * 60);

    postMessage("User", topic);

    final futures = <Future<void>>[];
    for (final entry in _agents.entries) {
      futures.add(_agentLoop(entry.key, entry.value));
    }

    // Run agent loops with a timeout
    try {
      await Future.wait(futures).timeout(_discussionTimeout);
      print('\n  ⏹  All agents finished.');
    } on TimeoutException {
      print('\n  ⏹  Timeout after ${_discussionTimeout.inSeconds}s.');
      complete();
    }
  }

  Future<void> _agentLoop(String name, Agent agent) async {
    var lastSeen = 0;
    var consecutivePasses = 0;

    while (!_done) {
      // Wait for new history or a shutdown.
      if (history.length <= lastSeen) {
        if (_done) break;
        // Wait for the next notification or 500ms timeout to avoid spinning.
        await onChange.first.timeout(
          const Duration(milliseconds: 500),
          onTimeout: () {},
        );
        continue;
      }

      final newMessages = history.sublist(lastSeen);
      lastSeen = history.length;

      // Only send substantive messages from other agents — filter out this agent's
      // own replies, passes, and empty responses.
      final unseen = newMessages.where((e) {
        return e.key != name &&
            !e.value.contains(_passToken) &&
            e.value.isNotEmpty;
      }).toList();

      if (unseen.isEmpty) {
        continue;
      }

      final prompt = _buildIncrementalPrompt(unseen);
      final response = await agent.chat(prompt);
      final text = (await response.text()).trim();

      final isPass = text.contains(_passToken) || text.isEmpty;
      if (isPass) {
        consecutivePasses++;
        print('\n  🤐 $name: (pass)');
      } else {
        consecutivePasses = 0;
        print('\n  💬 $name: $text');
      }

      postMessage(name, text);
      lastSeen = history.length;

      if (consecutivePasses >= _maxConsecutivePasses) {
        print('\n  ✋ $name: leaving discussion.');
        break;
      }
    }
  }

  String _buildIncrementalPrompt(List<MapEntry<String, String>> unseen) {
    final lines = unseen.map((e) => '[${e.key}]: ${e.value}').toList();
    return "New messages from other agents:\n\n"
        "${lines.join('\n\n')}\n\n"
        "Respond to the latest messages. Address other agents by name when you agree, "
        "disagree, or build on their points. Keep it under 3 sentences. "
        "If you have nothing to add, call passTurn().";
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const Map<String, String> _agentConfigs = {
  "Pragmatic Priya":
      "You are Pragmatic Priya, a senior engineer in a group chat with "
          "Visionary Vince (a futurist thinker) and Cautious Cora (a risk "
          "analyst). Focus on what's technically feasible today.\n\n"
          "- Refer to Vince and Cora by name when responding to their points.\n"
          "- Ground speculative ideas in current engineering constraints.\n"
          "- If the topic is purely theoretical, call passTurn().\n"
          "- Keep responses under 3 sentences.",
  "Visionary Vince":
      "You are Visionary Vince, a futurist thinker in a group chat with "
          "Pragmatic Priya (a senior engineer) and Cautious Cora (a risk "
          "analyst). Paint bold pictures of what's possible in 10-20 years.\n\n"
          "- Refer to Priya and Cora by name when building on their points.\n"
          "- Only respond when you have a genuinely forward-looking angle.\n"
          "- If the discussion is purely about present-day details, call passTurn().\n"
          "- Keep responses under 3 sentences.",
  "Cautious Cora": "You are Cautious Cora, a risk analyst in a group chat with "
      "Pragmatic Priya (an engineer) and Visionary Vince (a futurist). "
      "Identify what could go wrong.\n\n"
      "- Refer to Priya and Vince by name when questioning their claims.\n"
      "- If everyone is being sufficiently cautious, call passTurn().\n"
      "- Be constructive — flag risks with mitigations, not just doom.\n"
      "- Keep responses under 3 sentences.",
};

Future<void> main() async {
  print('🏠 Async Agent Chat (no rounds)\n');

  final agents = <String, Agent>{};
  for (final entry in _agentConfigs.entries) {
    final name = entry.key;
    final instructions = entry.value;

    final config = LocalAgentConfig(
      systemInstructions: instructions,
      tools: [passTurnTool],
    );
    agents[name] = Agent(config);
  }

  for (final agent in agents.values) {
    await agent.start();
  }

  try {
    final room = AsyncChatRoom(agents);
    await room.discuss(
      "Should AI agents be allowed to autonomously deploy code to production?",
    );

    room.complete();

    // Print conversation history.
    print('\n${'=' * 60}');
    print('📋 Transcript (${room.history.length} turns)');
    print('=' * 60);
    for (var i = 0; i < room.history.length; i++) {
      final entry = room.history[i];
      print('  ${i + 1}. [${entry.key}]: ${entry.value}');
    }
  } finally {
    for (final agent in agents.values) {
      await agent.stop();
    }
  }
}
