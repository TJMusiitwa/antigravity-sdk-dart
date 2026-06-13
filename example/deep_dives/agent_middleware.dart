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

/// Hook middleware: transparent tool interception.
///
/// Demonstrates how stacked hooks create emergent behavior the agent
/// is unaware of. The agent calls tools normally; hooks enforce rate
/// limits, log an audit trail, and recover from errors — all without
/// the agent's knowledge.
///
/// This example utilizes `package:logging` for professional-grade
/// auditing and diagnostic output.
///
/// Hooks stack (executed in order):
/// - PreToolCallDecideHook: enforces per-tool rate limits.
/// - PostToolCallHook: logs every call + result to an audit trail.
/// - OnToolErrorHook: returns a graceful fallback on failure.
///
/// Run with:
///   dart run example/deep_dives/agent_middleware.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// Simulated tools — intentionally simple to highlight hook behavior
// ---------------------------------------------------------------------------

Future<String> lookupUser(String email) async {
  return "User profile for $email: name=Alice, role=engineer, team=infra";
}

final lookupUserTool = Tool(
  name: 'lookupUser',
  description: 'Looks up a user by email address.',
  schema: {
    'type': 'object',
    'properties': {
      'email': {'type': 'string', 'description': 'The user email address.'},
    },
    'required': ['email'],
  },
  handler: (args, _) => lookupUser(args['email'] as String),
);

Future<String> sendNotification(String to, String message) async {
  return "Notification sent to $to: $message";
}

final sendNotificationTool = Tool(
  name: 'sendNotification',
  description: 'Sends a notification to a user.',
  schema: {
    'type': 'object',
    'properties': {
      'to': {'type': 'string', 'description': 'The user email or name.'},
      'message': {'type': 'string', 'description': 'The message to send.'},
    },
    'required': ['to', 'message'],
  },
  handler: (args, _) =>
      sendNotification(args['to'] as String, args['message'] as String),
);

Future<String> sendToUnknown(String name, String message) async {
  throw ArgumentError("Could not resolve '$name' to an email address");
}

final sendToUnknownTool = Tool(
  name: 'sendToUnknown',
  description: 'Sends a message to an unknown recipient.',
  schema: {
    'type': 'object',
    'properties': {
      'name': {'type': 'string'},
      'message': {'type': 'string'},
    },
    'required': ['name', 'message'],
  },
  handler: (args, _) =>
      sendToUnknown(args['name'] as String, args['message'] as String),
);

// ---------------------------------------------------------------------------
// Hook: Rate Limiting (PreToolCallDecideHook)
// ---------------------------------------------------------------------------

class RateLimitHook extends PreToolCallDecideHook {
  static const int maxCallsPerTool = 3;
  static const Duration windowDuration = Duration(minutes: 1);

  final Map<String, List<DateTime>> _calls = {};
  final _logger = Logger('middleware.ratelimit');

  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    final now = DateTime.now();
    final toolName = data.name;
    final history = _calls.putIfAbsent(toolName, () => []);

    // Prune calls outside the sliding window.
    history.removeWhere((t) => now.difference(t) > windowDuration);

    if (history.length >= maxCallsPerTool) {
      _logger.warning(
        'Denied $toolName ($maxCallsPerTool calls in ${windowDuration.inSeconds}s)',
      );
      return HookResult(
        allow: false,
        message:
            'Rate limit exceeded: $toolName called $maxCallsPerTool times in ${windowDuration.inSeconds}s',
      );
    }

    history.add(now);
    return HookResult(allow: true);
  }
}

// ---------------------------------------------------------------------------
// Hook: Audit Log (PostToolCallHook)
// ---------------------------------------------------------------------------

class AuditLogHook extends PostToolCallHook {
  final List<Map<String, dynamic>> log = [];
  final _logger = Logger('middleware.audit');

  @override
  Future<void> run(HookContext context, ToolResult data) async {
    final entry = {
      'tool': data.name,
      'result': data.result.toString(),
      'error': data.error,
    };
    log.add(entry);

    if (data.error != null) {
      _logger.severe('Tool Failed | ${data.name}: ${data.error}');
    } else {
      _logger.info('Tool Success | ${data.name}: ${data.result}');
    }
  }
}

// ---------------------------------------------------------------------------
// Hook: Error Recovery (OnToolErrorHook)
// ---------------------------------------------------------------------------

class FallbackHook extends OnToolErrorHook {
  final _logger = Logger('middleware.fallback');

  @override
  Future<dynamic> run(HookContext context, Exception data) async {
    final errorMsg = data.toString();
    _logger.fine('Attempting recovery from error: $errorMsg');

    if (errorMsg.contains("ArgumentError") || errorMsg.contains("resolve")) {
      _logger.info('Injecting user-steering fallback for resolution error');
      return '[Could not find that user. Use the lookupUser tool with their email address instead of their display name.]';
    }

    return null; // Let the harness handle all other errors
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  // Setup hierarchical logging output
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final time = record.time.toIso8601String().split('T')[1].split('.')[0];
    print(
      '[$time] ${record.level.name.padRight(7)} | ${record.loggerName.padRight(20)} | ${record.message}',
    );
  });

  print('🔌 Hook Middleware Example (Logging Enabled)\n');

  final rateLimitHook = RateLimitHook();
  final auditHook = AuditLogHook();
  final fallbackHook = FallbackHook();

  final config = LocalAgentConfig(
    systemInstructions:
        'You have access to user lookup, notification, and diagnostic tools. Use them as needed. Keep responses under 2 sentences.',
    tools: [lookupUserTool, sendNotificationTool, sendToUnknownTool],
    hooks: [rateLimitHook, auditHook, fallbackHook],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    print('\n${'=' * 80}');
    print('📨 Prompt 1: Normal tool use (audit logged via package:logging)');
    print('=' * 80);
    var r1 = await agent.chat(
      "Send a notification to bob@company.org saying 'Welcome aboard!'.",
    );
    print('\n  💬 Agent: ${(await r1.text()).trim()}');

    print('\n${'=' * 80}');
    print('📨 Prompt 2: Trigger error recovery (intercepted by FallbackHook)');
    print('=' * 80);
    var r2 = await agent.chat(
      "Send a message to 'Charlie' saying 'Hey, are you free tomorrow?'",
    );
    print('\n  💬 Agent: ${(await r2.text()).trim()}');

    print('\n${'=' * 80}');
    print('📨 Prompt 3: Trigger rate limiting (intercepted by RateLimitHook)');
    print('=' * 80);
    var r3 = await agent.chat(
      "Look up user1@test.com, then user2@test.com, then user3@test.com, then user4@test.com. Use the lookupUser tool for each one.",
    );
    print('\n  💬 Agent: ${(await r3.text()).trim()}');

    print('\n${'=' * 80}');
    print('📋 Summary Audit Report');
    print('=' * 80);
    for (var i = 0; i < auditHook.log.length; i++) {
      final entry = auditHook.log[i];
      final status = entry['error'] != null ? 'FAILED ' : 'SUCCESS';
      print(
        '  ${(i + 1).toString().padLeft(2)}. $status | ${entry['tool'].toString().padRight(15)} | ${entry['result']}',
      );
    }
  } finally {
    await agent.stop();
  }
}
