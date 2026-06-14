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

/// Agent example that maintains documentation.
///
/// Demonstrates how to write custom PreToolCallDecideHooks and use conditional
/// policy checks to restrict tool execution (e.g., allowing edit_file only
/// for .md files inside a target directory).
///
/// This example utilizes `package:path` for robust cross-platform path handling.
///
/// Run with:
///   dart run example/deep_dives/doc_maintenance_agent.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:path/path.dart' as p;

const Map<String, String> _toolNameMapping = {
  'view_file': 'Viewing Files',
  'list_directory': 'Listing Directory',
  'search_directory': 'Searching Directory',
  'find_file': 'Finding Files',
  'edit_file': 'Editing Files',
};

class PrintToolCallHook extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async {
    final plainName = _toolNameMapping[data.name] ?? data.name;

    // Try to find a path-like argument
    String pathArg = '';
    for (final key in ['file_path', 'path', 'directory_path']) {
      if (data.args.containsKey(key)) {
        pathArg = data.args[key]?.toString() ?? '';
        break;
      }
    }

    if (pathArg.isNotEmpty) {
      if (pathArg.startsWith('file://')) {
        pathArg = pathArg.substring('file://'.length);
      }
      // Use package:path to normalize for display
      final displayPath = p.prettyUri(pathArg);
      print('$plainName: $displayPath');
    } else {
      print('$plainName with arguments: ${data.args}');
    }

    return HookResult(allow: true);
  }
}

Future<void> main(List<String> args) async {
  String targetDir = p.current;
  String prompt =
      'Check all documentation in the target directory and ensure it matches the code. Fix any discrepancies you find.';

  if (args.isNotEmpty) {
    if (args[0] == '--help' || args[0] == '-h') {
      print(
        'Usage: dart run example/deep_dives/doc_maintenance_agent.dart [directory] [--prompt "custom prompt"]',
      );
      return;
    }
    // Simple custom parsing
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--prompt' && i + 1 < args.length) {
        prompt = args[i + 1];
        i++;
      } else if (!args[i].startsWith('--')) {
        targetDir = p.absolute(args[i]);
      }
    }
  }

  print('Target directory: ${p.relative(targetDir)}');

  bool isAllowedMdFile(ToolCall toolCall) {
    var pathStr = toolCall.canonicalPath ??
        toolCall.args['path'] ??
        toolCall.args['file_path'] ??
        '';
    if (pathStr.isEmpty) {
      return false;
    }

    // Normalize path using package:path
    if (pathStr.startsWith('file://')) {
      pathStr = Uri.parse(pathStr).toFilePath();
    }

    final absPath = p.absolute(pathStr);

    // Check if it's a markdown file and within the allowed target directory
    final isMd = p.extension(absPath) == '.md';
    final isInTarget =
        p.isWithin(targetDir, absPath) || p.equals(targetDir, absPath);

    return isMd && isInTarget;
  }

  final policies = [
    allow('view_file'),
    allow('list_directory'),
    allow('search_directory'),
    allow('find_file'),
    allow(
      'edit_file',
      when: isAllowedMdFile,
      name: 'allow-edit-md-only-in-target',
    ),
    deny('*', name: 'deny-all-else'),
  ];

  final systemInstructions =
      'You are an expert Technical Writer and Documentation Agent for the '
      'Google Antigravity SDK. Your goal is to create and maintain '
      'high-quality documentation surfaced to third-party '
      'developers.\n\nGuidelines:\n1. **Audience**: Write for external '
      'developers. Assume they know nothing about Google-internal '
      'infrastructure. Use clear, professional, and accessible language. '
      'Avoid internal jargon.\n2. **Focus & Coverage**: Prioritize the public '
      'API surface. You must ensure that 100% of the public Dart code '
      '(classes, functions, public methods) is covered by high-quality '
      'documentation. This includes detailed docstrings (Google style) and '
      'inclusion in relevant markdown guides.\n3. **Examples**: Create and '
      'maintain realistic "Hello World" and usage examples for all featured '
      'capabilities. All code snippets in documentation MUST be complete, '
      'copy-pasteable, and verified against the actual code or unit tests. Do '
      'not use trivial System Instructions like "You are a helpful '
      'assistant." in examples.\n4. **Verification**: When adding or updating '
      'documentation containing code snippets, verify that the snippets '
      'accurately reflect the current API usage by cross-referencing with '
      'source code and unit tests.\n5. **Terminology**: Always use "Layer" '
      'instead of "Tier" to refer to SDK architecture layers, and always use '
      '"Google Antigravity SDK" instead of "Antigravity SDK" to refer to the '
      'SDK.\n6. **Action**: Read the source code in the project directory and '
      'ensure the corresponding README.md and guide files are accurate and '
      'up-to-date. Apply fixes directly to .md files within the target '
      'directory. You are ONLY allowed to edit .md files within the target '
      'directory. The target directory is: $targetDir';

  print('Creating Doc Maintenance Agent...');
  final config = LocalAgentConfig(
    systemInstructions: systemInstructions,
    policies: policies,
    hooks: [PrintToolCallHook()],
    capabilities: CapabilitiesConfig(),
    workspaces: [targetDir],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    print('\nStreaming agent output:');
    final response = await agent.chat(prompt);
    await for (final chunk in response.textStream) {
      stdout.write(chunk);
    }
    print('');
  } finally {
    await agent.stop();
  }
}
