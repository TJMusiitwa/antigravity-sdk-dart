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

import 'dart:convert';
import 'dart:io';

const interactiveExamples = [
  {
    'name': 'Human-in-the-Loop',
    'path': 'example/getting_started/human_in_the_loop.dart',
    'desc':
        'Demonstrates policy.ask() requiring manual approval for tool calls.',
  },
  {
    'name': 'Autonomous Shell',
    'path': 'example/getting_started/autonomous_shell.dart',
    'desc': 'Spawns an agent that asks to run terminal commands autonomously.',
  },
  {
    'name': 'Interactive CLI REPL',
    'path': 'example/deep_dives/interactive_cli.dart',
    'desc': 'A full-blown chat REPL console with the agent.',
  },
  {
    'name': 'Doc Maintenance Agent',
    'path': 'example/deep_dives/doc_maintenance_agent.dart',
    'desc': 'Agent that scans and maintains documentation files autonomously.',
  },
  {
    'name': 'Docstring Maintenance Agent',
    'path': 'example/deep_dives/docstring_maintenance_agent.dart',
    'desc': 'Agent that updates and aligns codebase class/method docstrings.',
  },
  {
    'name': 'MCP Tools Client',
    'path': 'example/getting_started/mcp_tools.dart',
    'desc':
        'Demonstrates connecting to and invoking external MCP server tools (requires running MCP server).',
  },
];

Future<void> main() async {
  print(
    '======================================================================',
  );
  print('🔮 Antigravity SDK - Interactive Example Runner');
  print(
    '======================================================================\n',
  );

  final env = Map<String, String>.from(Platform.environment);

  // 1. Try loading GEMINI_API_KEY from .env
  final envFile = File('.env');
  if (envFile.existsSync()) {
    for (final line in envFile.readAsLinesSync()) {
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        var val = parts.sublist(1).join('=').trim();
        if (val.startsWith('"') && val.endsWith('"')) {
          val = val.substring(1, val.length - 1);
        }
        if (env[key] == null) {
          env[key] = val;
        }
      }
    }
  }

  // 2. If not found, prompt user for API key and optionally save it
  if (env['GEMINI_API_KEY'] == null || env['GEMINI_API_KEY']!.isEmpty) {
    stdout.write('🔑 GEMINI_API_KEY not found. Please enter your API Key: ');
    final keyInput = stdin.readLineSync(encoding: utf8)?.trim();
    if (keyInput == null || keyInput.isEmpty) {
      print('❌ Error: GEMINI_API_KEY is required to run examples.');
      exit(1);
    }
    env['GEMINI_API_KEY'] = keyInput;

    stdout.write('💾 Would you like to save this key to a .env file? (y/n): ');
    final saveInput = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase();
    if (saveInput == 'y' || saveInput == 'yes') {
      envFile.writeAsStringSync(
        'GEMINI_API_KEY=$keyInput\n',
        mode: FileMode.append,
      );
      print('✅ API Key saved to .env file.');
    }
  }

  // 3. Display menu
  print('\nSelect an interactive example to run:');
  for (var i = 0; i < interactiveExamples.length; i++) {
    final ex = interactiveExamples[i];
    print('  [${i + 1}] ${ex['name']}');
    print('      Path: ${ex['path']}');
    print('      Desc: ${ex['desc']}\n');
  }

  stdout.write(
    'Enter option (1-${interactiveExamples.length}) or "q" to quit: ',
  );
  final choice = stdin.readLineSync(encoding: utf8)?.trim().toLowerCase();
  if (choice == null || choice == 'q' || choice == 'quit') {
    print('👋 Exiting.');
    return;
  }

  final idx = int.tryParse(choice);
  if (idx == null || idx < 1 || idx > interactiveExamples.length) {
    print('❌ Invalid selection.');
    return;
  }

  final selected = interactiveExamples[idx - 1];
  print(
    '\n----------------------------------------------------------------------',
  );
  print('🚀 Spawning ${selected['name']}...');
  print(
    '----------------------------------------------------------------------\n',
  );

  // 4. Run the process in fully interactive mode inheriting stdio
  final process = await Process.start(
    'dart',
    ['run', selected['path']!],
    environment: env,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  print(
    '\n----------------------------------------------------------------------',
  );
  print('⏹ Process exited with code $exitCode');
  print(
    '----------------------------------------------------------------------',
  );
}
