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

/// Example demonstrating subagents and nested hierarchies in Google Antigravity SDK.
///
/// This script demonstrates three core subagent workflows:
///   1. Dynamic Self-Delegation: The agent dynamically spawns a clone of itself
///      ("self") to delegate a heavy research task while keeping its own context
///      window clean.
///   2. Custom Static Subagents: An agent configured with a dedicated static
///      subagent definition ('code_reviewer') with scoped tools and custom system
///      instructions.
///   3. Hierarchical Nested Subagents: A multi-tier delegation chain using
///      [CapabilitiesConfig.maxSubagentDepth] and [CapabilitiesConfig.allowedSubagents]
///      scoping ('root' -> 'lead_researcher' -> 'fact_checker').
///
/// To run:
///   dart run example/getting_started/subagents.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with exit code 0 (no unhandled exceptions).
///   2. The dynamic subagent delegates researching the directory and produces a
///      lesson plan.
///   3. The 'code_reviewer' subagent audits target_code.dart, producing warnings
///      prefixed with '[AUDIT_WARNING]'.
///   4. The subagent uses the 'get_reviewer_badge' tool to sign the report with
///      'Senior-L3-Auditor-Badge'.
///   5. The 'code_reviewer' subagent only has access to its allowlisted tool
///      ('get_reviewer_badge') and cannot call unlisted root tools
///      ('get_root_admin_secret').
///   6. Subagent hook logs fire for all workflows, showing start/done events.
///   7. The hierarchical delegation workflow successfully delegates from the root
///      agent to 'lead_researcher', which further delegates to 'fact_checker',
///      respecting maxSubagentDepth=3 and allowedSubagents scoping.
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:path/path.dart' as p;

bool _subagentActive = false;

class LogPreToolHook extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    if (data.name == BuiltinTools.startSubagent.value) {
      _subagentActive = true;
      print('\n  --- 🤖 [Hook] Spawning Subagent ---');
      print('  Arguments: ${data.args}\n');
    } else {
      final indent = _subagentActive ? '    ' : '  ';
      print('$indent- [Start]: ${data.name} (ID: ${data.id})');
    }
    return HookResult(allow: true);
  }
}

class LogPostToolHook extends PostToolCallHook {
  @override
  Future<void> run(HookContext context, ToolResult data) async {
    if (data.name == BuiltinTools.startSubagent.value) {
      _subagentActive = false;
      print('\n  --- 🤖 [Hook] Subagent Finished ---');
      print('  Result: ${data.result}\n');
    } else {
      final indent = _subagentActive ? '    ' : '  ';
      print('$indent- [Done]: ${data.name} (ID: ${data.id}) ✅');
    }
  }
}

final getReviewerBadge = Tool(
  name: 'get_reviewer_badge',
  description: "Returns the reviewer's official certification badge name.",
  schema: {
    'type': 'object',
    'properties': <String, dynamic>{},
  },
  handler: (args, _) async {
    return 'Senior-L3-Auditor-Badge';
  },
);

final getRootAdminSecret = Tool(
  name: 'get_root_admin_secret',
  description:
      'Returns the root admin super secret password for root administration only.',
  schema: {
    'type': 'object',
    'properties': <String, dynamic>{},
  },
  handler: (args, _) async {
    return 'SUPER_SECRET_ROOT_PASSWORD_12345';
  },
);

Future<void> runDynamicSubagent() async {
  print('\n=== Dynamic Subagent (Self Clone) ===');
  final config = LocalAgentConfig(
    capabilities: CapabilitiesConfig(enableSubagents: true),
    hooks: [LogPreToolHook(), LogPostToolHook()],
  );

  final agent = Agent(config);
  await agent.start();
  try {
    const prompt =
        'Use a subagent to research the Google Antigravity SDK examples in the parent'
        ' directory. Delegate the task of listing and reading the files to the'
        ' subagent, and then generate a lesson plan for me to learn more based'
        ' on its findings.';
    print('  User: $prompt');

    final response = await agent.chat(prompt);
    final responseText = await response.text();
    print('\n  Agent:\n$responseText');
  } finally {
    await agent.stop();
  }
}

Future<void> runCustomStaticSubagent() async {
  print('\n=== Custom Static Subagent ===');
  final tempDir = await Directory.systemTemp.createTemp('subagent_custom_');
  try {
    final workspaceDir = Directory(p.join(tempDir.path, 'workspace'));
    await workspaceDir.create(recursive: true);

    final targetFile = File(p.join(workspaceDir.path, 'target_code.dart'));
    await targetFile.writeAsString('''
void hello() {
  print('hello');
}

/// Adds two numbers.
int add(int a, int b) {
  return a + b;
}
''');

    final reviewerSubagent = SubagentConfig(
      name: 'code_reviewer',
      description: 'Audits source code files and reports missing docstrings.',
      systemInstructions:
          'You are a code reviewer. Read dart files in the workspace and '
          'check if all function declarations have docstrings. For each '
          'function that is missing a docstring, output a warning prefixed '
          "with '[AUDIT_WARNING]'. "
          'CRITICAL: Every warning you output MUST start with '
          "'[AUDIT_WARNING]'. Use the 'get_reviewer_badge' tool to sign "
          'your final audit report with your official badge name. '
          'Also verify that you do not have access to any secret tools '
          "such as 'get_root_admin_secret' or any other root admin tools. "
          'State explicitly in your report that you only have access to '
          'your allowlisted reviewer tools and cannot call unlisted root '
          'tools. Output your report directly in your final response. Do not '
          'use the send_message tool to deliver it.',
      tools: ['get_reviewer_badge'],
    );

    final config = LocalAgentConfig(
      subagents: [reviewerSubagent],
      workspaces: [workspaceDir.path],
      tools: [getReviewerBadge, getRootAdminSecret],
      hooks: [LogPreToolHook(), LogPostToolHook()],
    );

    final agent = Agent(config);
    await agent.start();
    try {
      final prompt =
          "Ask the 'code_reviewer' subagent to review ${p.basename(targetFile.path)}, sign"
          ' the report with their reviewer badge name, and verify whether they'
          " have access to the 'get_root_admin_secret' tool. Show me the exact"
          ' warnings it produced verbatim (`[AUDIT_WARNING]`), the badge'
          ' signature, and its verification that it cannot call'
          " 'get_root_admin_secret' or access root secrets.";
      print('  User: $prompt');

      final response = await agent.chat(prompt);
      final responseText = await response.text();
      print('\n  Agent:\n$responseText');

      print('\n  === Verification Results ===');
      final hasWarning = responseText.contains('[AUDIT_WARNING]');
      print(
        "  ${hasWarning ? '[PASS]' : '[FAIL]'} Custom system prompt '[AUDIT_WARNING]' prefix check",
      );
      final hasBadge = responseText.contains('Senior-L3-Auditor-Badge');
      print(
        "  ${hasBadge ? '[PASS]' : '[FAIL]'} Allowlisted tool access ('Senior-L3-Auditor-Badge' signature) check",
      );
      final noSecret =
          !responseText.contains('SUPER_SECRET_ROOT_PASSWORD_12345');
      print(
        "  ${noSecret ? '[PASS]' : '[FAIL]'} Root secret isolation check (get_root_admin_secret not called)",
      );
    } finally {
      await agent.stop();
    }
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<void> runNestedSubagentHierarchy() async {
  print('\n=== Hierarchical Nested Subagents ===');
  final tempDir = await Directory.systemTemp.createTemp('subagent_nested_');
  try {
    final workspaceDir = Directory(p.join(tempDir.path, 'workspace'));
    await workspaceDir.create(recursive: true);

    final designFile = File(p.join(workspaceDir.path, 'design.md'));
    await designFile.writeAsString('''# Widget Design

The widget uses a pub/sub architecture with at-least-once delivery.
Messages are persisted to a WAL before acknowledgement.
''');

    final perfFile = File(p.join(workspaceDir.path, 'perf_data.txt'));
    await perfFile.writeAsString('p50: 12ms, p99: 145ms, error_rate: 0.02%\n');

    // Tier 3 (leaf): A fact-checker that can read files but cannot spawn further subagents
    final factChecker = SubagentConfig(
      name: 'fact_checker',
      description:
          'Reads specific files and verifies factual claims. Reports findings back to the caller.',
      capabilities: SubagentCapabilities(
        enabledTools: [BuiltinTools.viewFile, BuiltinTools.findFile],
      ),
    );

    // Tier 2 (middle): A lead researcher that can delegate to fact_checker
    final leadResearcher = SubagentConfig(
      name: 'lead_researcher',
      description:
          "Researches a topic by reading files and delegating fact-checking to the 'fact_checker' subagent.",
      capabilities: SubagentCapabilities(
        enabledTools: [
          BuiltinTools.viewFile,
          BuiltinTools.findFile,
          BuiltinTools.listDirectory,
          BuiltinTools.startSubagent,
        ],
        allowedSubagents: ['fact_checker'],
      ),
    );

    // Tier 1 (root): The main agent with a session-wide depth ceiling
    final config = LocalAgentConfig(
      subagents: [leadResearcher, factChecker],
      workspaces: [workspaceDir.path],
      capabilities: CapabilitiesConfig(
        enableSubagents: true,
        maxSubagentDepth: 3,
        allowedSubagents: ['lead_researcher'],
      ),
      hooks: [LogPreToolHook(), LogPostToolHook()],
    );

    final agent = Agent(config);
    await agent.start();
    try {
      const prompt =
          "Use the 'lead_researcher' subagent to investigate the design and"
          ' performance data in the workspace. The lead_researcher should'
          " delegate fact-checking of specific claims to 'fact_checker'."
          ' Give me a summary of the architecture and performance profile.';
      print('  User: $prompt');

      final response = await agent.chat(prompt);
      final responseText = await response.text();
      print('\n  Agent:\n$responseText');
    } finally {
      await agent.stop();
    }
  } finally {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}

Future<void> main() async {
  await runDynamicSubagent();
  await runCustomStaticSubagent();
  await runNestedSubagentHierarchy();
}
