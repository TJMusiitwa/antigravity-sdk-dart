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

/// Agent example that maintains docstrings in Dart files.
///
/// Demonstrates how to write custom PreToolCallDecideHooks, disable specific
/// agent capabilities (e.g. createFile, runCommand, generateImage, startSubagent,
/// askQuestion, finish), and enforce conditional policy checks to restrict
/// tool execution (e.g., allowing edit_file only for .dart files inside a
/// target directory).
///
/// Run with:
///   dart run example/deep_dives/docstring_maintenance_agent.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';

import 'package:antigravity/antigravity.dart';

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
      print('$plainName: $pathArg');
    } else {
      print('$plainName with arguments: ${data.args}');
    }

    return HookResult(allow: true);
  }
}

Future<void> main(List<String> args) async {
  String targetDir = Directory.current.absolute.path;
  String prompt =
      'Audit all Dart files in the target directory and ensure all public '
      'symbols have high-quality Dart doc comments (///). Add or update '
      'doc comments as needed.';

  if (args.isNotEmpty) {
    if (args[0] == '--help' || args[0] == '-h') {
      print(
        'Usage: dart run example/deep_dives/docstring_maintenance_agent.dart [directory] [--prompt "custom prompt"]',
      );
      return;
    }
    // Simple custom parsing
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--prompt' && i + 1 < args.length) {
        prompt = args[i + 1];
        i++;
      } else if (!args[i].startsWith('--')) {
        targetDir = Directory(args[i]).absolute.path;
      }
    }
  }

  print('Target directory: $targetDir');

  bool isAllowedDartFile(ToolCall toolCall) {
    var path =
        toolCall.canonicalPath ??
        toolCall.args['path'] ??
        toolCall.args['file_path'] ??
        '';
    if (path.isEmpty) {
      return false;
    }
    if (path.startsWith('file://')) {
      path = path.substring('file://'.length);
    }
    final absPath = File(path).absolute.path;
    return absPath.endsWith('.dart') && isPathInWorkspace(absPath, targetDir);
  }

  final policies = [
    allow('view_file'),
    allow('list_directory'),
    allow('search_directory'),
    allow('find_file'),
    allow(
      'edit_file',
      when: isAllowedDartFile,
      name: 'allow-edit-dart-only-in-target',
    ),
    deny('*', name: 'deny-all-else'),
  ];

  final systemInstructions =
      'You are an expert Technical Writer and Docstring Maintenance Agent for '
      'the Google Antigravity SDK. Your goal is to ensure that 100% of the '
      'public Dart code (classes, functions, public methods) is covered by '
      'high-quality doc comments (using /// syntax) following standard Dart guidelines.\n\n'
      'Guidelines:\n1. **Focus**: Audit all Dart files in the '
      'target directory. Identify public symbols lacking doc comments or having '
      'incomplete/outdated doc comments.\n2. **Style**: Use Dart doc comment style. '
      'Write clear, concise single-line summaries, followed by detailed '
      'paragraphs if necessary. Describe parameters, return values, and exceptions.\n3. '
      '**Safety**: You are ONLY allowed to add or update doc comments. Do NOT '
      'modify any implementation code, logic, or variable definitions. Your edits '
      'must be strictly limited to comment blocks.\n4. **Action**: Apply fixes '
      'directly to .dart files within the target directory. You are ONLY allowed '
      'to edit .dart files within the target directory. The target directory is: $targetDir\n5. '
      '**Branding**: Always use "Google Antigravity SDK" instead of '
      '"Antigravity SDK" when referring to the SDK.';

  print('Creating Docstring Maintenance Agent...');
  final capabilities = CapabilitiesConfig(
    disabledTools: [
      BuiltinTools.createFile,
      BuiltinTools.runCommand,
      BuiltinTools.askQuestion,
      BuiltinTools.startSubagent,
      BuiltinTools.generateImage,
      BuiltinTools.finish,
    ],
  );

  final config = LocalAgentConfig(
    systemInstructions: systemInstructions,
    policies: policies,
    hooks: [PrintToolCallHook()],
    capabilities: capabilities,
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
