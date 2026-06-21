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

/// Synchronized parallel agent chat room with opt-out.
///
/// Three agents (Rational Rita, Creative Cal, Skeptical Sam) discuss topics
/// as equals. All agents process in parallel each round. Each can call
/// passTurn() to stay silent.
///
/// Run with:
///   dart run example/deep_dives/round_based_chat.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';

import 'package:antigravity/antigravity.dart';

const String _passToken = "[PASS]";
const int _maxRounds = 4;

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
  handler: (args, ctx) => passTurn(),
);

// ---------------------------------------------------------------------------
// Trigger: moderator nudge after a delay
// ---------------------------------------------------------------------------

Future<void> moderatorNudge(TriggerContext ctx) async {
  await ctx.send(
    "The discussion is wrapping up. Make your final point concisely.",
  );
}

// ---------------------------------------------------------------------------
// Chat room
// ---------------------------------------------------------------------------

class ChatRoom {
  final List<MapEntry<String, String>> history = [];
  final Map<String, Agent> _agents;
  final Map<String, int> _lastSeen = {};

  ChatRoom(this._agents) {
    for (final name in _agents.keys) {
      _lastSeen[name] = 0;
    }
  }

  Future<void> discuss(String topic) async {
    print('\n${'=' * 60}');
    print('💬 Topic: $topic');
    print('=' * 60);

    history.add(MapEntry("User", topic));

    for (var round = 0; round < _maxRounds; round++) {
      final responses = await _parallelRound();

      if (responses.isEmpty) {
        print('\n  ⏹  All agents passed — discussion complete.');
        break;
      }

      for (final resp in responses) {
        history.add(resp);
      }
    }

    if (history.length >= _maxRounds * 3 + 1) {
      print('\n  ⏹  Max rounds reached ($_maxRounds).');
    }
  }

  Future<List<MapEntry<String, String>>> _parallelRound() async {
    Future<MapEntry<String, String>> ask(String name, Agent ag) async {
      // Build a per-agent prompt with only messages it hasn't seen,
      // excluding its own (already in the stateful Agent's context).
      final unseen = <MapEntry<String, String>>[];
      final startIdx = _lastSeen[name] ?? 0;
      for (var i = startIdx; i < history.length; i++) {
        final entry = history[i];
        if (entry.key != name) {
          unseen.add(entry);
        }
      }

      _lastSeen[name] = history.length;
      if (unseen.isEmpty) {
        return MapEntry(name, "");
      }

      final prompt = _buildIncrementalPrompt(unseen);
      final response = await ag.chat(prompt);
      final text = await response.text();
      return MapEntry(name, text.trim());
    }

    final futures = _agents.entries.map((e) => ask(e.key, e.value)).toList();
    final results = await Future.wait(futures);

    final responses = <MapEntry<String, String>>[];
    for (final res in results) {
      final name = res.key;
      final text = res.value;
      if (text.contains(_passToken) || text.isEmpty) {
        print('\n  🤐 $name: (pass)');
      } else {
        print('\n  💬 $name: $text');
        responses.add(res);
      }
    }

    return responses;
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
  "Rational Rita":
      "You are Rational Rita, a research specialist in a group chat with "
          "Creative Cal (an imaginative thinker) and Skeptical Sam (a devil's "
          "advocate). Give concise, factual answers grounded in evidence.\n\n"
          "- Refer to Cal and Sam by name when responding to their points.\n"
          "- Correct inaccuracies from other agents.\n"
          "- If the topic is purely creative/opinion, call passTurn().\n"
          "- Keep responses under 3 sentences.",
  "Creative Cal":
      "You are Creative Cal, a creative thinker in a group chat with "
          "Rational Rita (a fact-driven researcher) and Skeptical Sam (a "
          "devil's advocate). Offer imaginative perspectives and metaphors.\n\n"
          "- Refer to Rita and Sam by name when building on their points.\n"
          "- Only respond when you have a genuinely fresh angle.\n"
          "- If the discussion is purely factual, call passTurn().\n"
          "- Keep responses under 3 sentences.",
  "Skeptical Sam":
      "You are Skeptical Sam, a devil's advocate in a group chat with "
          "Rational Rita (a researcher) and Creative Cal (a creative "
          "thinker). Challenge assumptions and poke holes.\n\n"
          "- Refer to Rita and Cal by name when questioning their claims.\n"
          "- If everyone is being balanced, call passTurn().\n"
          "- Be constructive, not contrarian for its own sake.\n"
          "- Keep responses under 3 sentences.",
};

Future<void> main() async {
  print('🏠 Agent Chat Room\n');

  final agents = <String, Agent>{};
  for (final entry in _agentConfigs.entries) {
    final name = entry.key;
    final instructions = entry.value;

    final config = LocalAgentConfig(
      systemInstructions: instructions,
      tools: [passTurnTool],
      triggers: [every(const Duration(seconds: 60), moderatorNudge)],
    );
    agents[name] = Agent(config);
  }

  // Start all agents.
  for (final agent in agents.values) {
    await agent.start();
  }

  try {
    final room = ChatRoom(agents);

    final topics = [
      "Should we colonize Mars, or focus on fixing Earth first?",
      "What's the most overrated programming language?",
    ];

    for (final topic in topics) {
      await room.discuss(topic);
    }

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
