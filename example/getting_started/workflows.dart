import 'dart:convert';
import 'dart:io';

import 'package:antigravity/antigravity.dart';

/// Runs a Python workflow script in the local harness's workflow runtime.
///
/// With no arguments, it writes two vulnerable source files to a temporary
/// workspace and runs the bundled `example/resources/security_audit_workflow.py`
/// with `args: {'paths': [...]}`. The script reads each file with `call_tool`,
/// audits them in parallel with a `file_auditor` subagent, and then holds a
/// two-turn conversation with a `lead_synthesizer` subagent.
///
/// With `--audit-lib`, it instead uses this repository as the workspace and
/// audits the hand-written Dart files under `lib/` (generated `*.mapper.dart`
/// files are skipped). `--audit-lib=<subdir>` limits the audit to a folder
/// under `lib/`, for example `--audit-lib=src/connections/local`. The bundled
/// script starts one subagent per file in parallel, so the whole of `lib/`
/// means dozens of concurrent model calls; narrow it if you hit rate limits.
/// The agent can only read files, so the audit never changes the repository.
///
/// To run your own script instead, pass its path and, optionally, a JSON object
/// that the script receives as `args`:
///
/// ```bash
/// dart run example/getting_started/workflows.dart
/// dart run example/getting_started/workflows.dart --audit-lib
/// dart run example/getting_started/workflows.dart --audit-lib=src/tools
/// dart run example/getting_started/workflows.dart my_workflow.py '{"key": 1}'
/// ```
Future<void> main(List<String> arguments) async {
  final args = [...arguments];
  final auditFlagIndex = args.indexWhere(
    (a) => a == '--audit-lib' || a.startsWith('--audit-lib='),
  );
  final String? auditSubdir;
  if (auditFlagIndex == -1) {
    auditSubdir = null;
  } else {
    final flag = args.removeAt(auditFlagIndex);
    auditSubdir = flag.contains('=')
        ? flag.substring(flag.indexOf('=') + 1)
        : '';
  }
  if (args.length > 2 || (auditSubdir != null && args.isNotEmpty)) {
    stderr.writeln(
      'Usage: dart run example/getting_started/workflows.dart '
      '[--audit-lib[=<subdir>] | <workflow.py> [\'{"key": "value"}\']]',
    );
    exitCode = 64;
    return;
  }

  final temp = await Directory.systemTemp.createTemp('agy_workflow_');
  try {
    final Directory workspace;
    final String scriptPath;
    final Map<String, Object?>? workflowArgs;
    if (auditSubdir != null) {
      // The repository is the workspace so `read_file` can reach lib/, and
      // the bundled script sits inside it.
      workspace = _repoRoot();
      scriptPath = _bundledScriptPath();
      final paths = await _libSources(workspace, auditSubdir);
      if (paths.isEmpty) {
        stderr.writeln('No Dart sources found under lib/$auditSubdir.');
        exitCode = 66;
        return;
      }
      stdout.writeln('Auditing ${paths.length} files under lib/$auditSubdir');
      workflowArgs = {'paths': paths};
    } else if (args.isEmpty) {
      workspace = temp;
      scriptPath = _bundledScriptPath();
      workflowArgs = {'paths': await _writeAuditTargets(temp)};
    } else {
      workspace = temp;
      scriptPath = File(args.first).absolute.path;
      workflowArgs = args.length == 2
          ? (jsonDecode(args[1]) as Map).cast<String, Object?>()
          : null;
    }

    final agent = Agent(
      LocalAgentConfig(
        workspaces: [workspace.path],
        capabilities: CapabilitiesConfig(
          // `call_tool("read_file", ...)` inside the workflow needs viewFile.
          enabledTools: [BuiltinTools.runWorkflow, BuiltinTools.viewFile],
        ),
        subagents: [
          SubagentConfig(
            name: 'file_auditor',
            description: 'Audits a code snippet for security vulnerabilities.',
            systemInstructions:
                'You are a concise security auditor. Identify the '
                'vulnerability in the provided snippet in one sentence.',
            capabilities: SubagentCapabilities(enabledTools: []),
          ),
          SubagentConfig(
            name: 'lead_synthesizer',
            description: 'Synthesizes security findings across multiple turns.',
            systemInstructions:
                'You are a security lead. Combine the audit findings and '
                'respond with the requested schema on each turn.',
            capabilities: SubagentCapabilities(enabledTools: []),
          ),
        ],
        policies: [allowAll()],
      ),
    );
    await agent.start();
    try {
      final result = await agent.beta.runWorkflow(
        scriptPath: scriptPath,
        args: workflowArgs,
      );
      stdout.writeln('Script path: ${result.scriptPath}');
      stdout.writeln('Description: ${result.description}');
      stdout.writeln('Workflow output:\n${result.output.trim()}');
      if (result.responseText.trim().isNotEmpty) {
        stdout.writeln('Response: ${result.responseText.trim()}');
      }
    } finally {
      await agent.stop();
    }
  } finally {
    // Only the temporary folder is deleted, never the repository.
    await temp.delete(recursive: true);
  }
}

/// The repository root, resolved relative to this example file.
Directory _repoRoot() =>
    File(Platform.script.toFilePath()).parent.parent.parent;

/// The bundled workflow script, resolved relative to this example file.
String _bundledScriptPath() {
  final exampleDir = File(Platform.script.toFilePath()).parent.parent;
  return [
    exampleDir.path,
    'resources',
    'security_audit_workflow.py',
  ].join(Platform.pathSeparator);
}

/// Hand-written Dart sources under `lib/<subdir>`, skipping generated mappers.
Future<List<String>> _libSources(Directory repoRoot, String subdir) async {
  final root = Directory(
    [
      repoRoot.path,
      'lib',
      if (subdir.isNotEmpty) subdir,
    ].join(Platform.pathSeparator),
  );
  if (!await root.exists()) return [];
  return [
    await for (final entry in root.list(recursive: true))
      if (entry is File &&
          entry.path.endsWith('.dart') &&
          !entry.path.endsWith('.mapper.dart'))
        entry.path,
  ]..sort();
}

/// Writes the two files the bundled workflow audits and returns their paths.
Future<List<String>> _writeAuditTargets(Directory workspace) async {
  final auth = File('${workspace.path}${Platform.pathSeparator}auth.py');
  await auth.writeAsString(
    "jwt.decode(token, options={'verify_signature': False})\n",
  );
  final db = File('${workspace.path}${Platform.pathSeparator}db.py');
  await db.writeAsString(
    "cursor.execute(f'SELECT * FROM users WHERE id = {user_id}')\n",
  );
  return [auth.path, db.path];
}
