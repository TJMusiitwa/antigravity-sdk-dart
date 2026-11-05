import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'agent.dart';
import 'connections/connection.dart';
import 'connections/local/local_connection_config.dart';
import 'types.dart';
import 'workflows.dart';

/// Experimental operations, available through `agent.beta`.
class AgentBeta {
  final Agent _agent;
  final AgentConfig _config;

  /// Creates the beta operations for the given [Agent] and its
  /// [AgentConfig].
  AgentBeta(this._agent, this._config);

  /// Executes a Python workflow script through the harness's sandbox.
  ///
  /// `~` is expanded, and a relative [scriptPath] is resolved against the
  /// first workspace that contains it, otherwise against the current
  /// directory. The script is checked with [validateWorkflowSource] before the
  /// model is asked to run it.
  ///
  /// [args] are input arguments exposed to the script as `workflows.args`
  /// (`args`). They must be JSON-encodable; an empty or null map sends no
  /// arguments.
  ///
  /// Throws an [ArgumentError] if [scriptPath] is empty,
  /// [BuiltinTools.runWorkflow] is not enabled, or [args] is not
  /// JSON-encodable; a [FileSystemException] if the script does not exist; a
  /// [WorkflowException] if it fails validation; and a
  /// [ToolExecutionException] if the model does not run the workflow or the
  /// workflow fails.
  Future<WorkflowResult> runWorkflow({
    required String scriptPath,
    String description = '',
    Map<String, Object?>? args,
  }) async {
    final conversation = _agent.conversation;
    final capabilities = _config.capabilities;
    final active =
        capabilities.enabledTools?.toSet() ??
        BuiltinTools.defaultTools().toSet().difference(
          capabilities.disabledTools?.toSet() ?? {},
        );
    if (!capabilities.enableSubagents ||
        !active.contains(BuiltinTools.runWorkflow)) {
      throw ArgumentError(
        'BuiltinTools.runWorkflow is not enabled on this agent.',
      );
    }
    if (scriptPath.trim().isEmpty) {
      throw ArgumentError('scriptPath must not be empty.');
    }
    String? argsJson;
    if (args != null && args.isNotEmpty) {
      try {
        argsJson = _encodePythonJson(args);
      } on Object catch (e) {
        throw ArgumentError.value(
          args,
          'args',
          'runWorkflow() `args` must be JSON-serializable: $e',
        );
      }
    }
    var file = File(normalizeWorkspacePath(scriptPath));
    final isRelative = !p.isAbsolute(scriptPath) && !scriptPath.startsWith('~');
    if (isRelative) {
      for (final workspace in _config.workspaces) {
        final candidate = File(
          p.join(normalizeWorkspacePath(workspace), scriptPath),
        );
        if (await candidate.exists()) {
          file = candidate;
          break;
        }
      }
    }
    if (!await file.exists()) {
      throw FileSystemException('Workflow script not found', file.path);
    }
    validateWorkflowSource(utf8.decode(await file.readAsBytes()));
    final resolvedPath = await file.resolveSymbolicLinks();
    final effectiveDescription = description.isEmpty
        ? 'Run workflow ${file.uri.pathSegments.last}'
        : description;
    final historyStart = conversation.history.length;
    final argsClause = argsJson == null ? '' : ' with Args `$argsJson`';
    final response = await _agent.chat(
      'Run the workflow script at `$resolvedPath` ($effectiveDescription)'
      '$argsClause using the `run_workflow` tool.',
    );
    final responseText = await response.text();
    Step? workflowStep;
    for (final step
        in conversation.history.skip(historyStart).toList().reversed) {
      if (step.depth != 0 || step.parentTrajectoryId.isNotEmpty) continue;
      if (step.workflowProgress != null ||
          step.toolCalls.any((t) => t.name == 'run_workflow')) {
        workflowStep = step;
        break;
      }
    }
    if (workflowStep == null) {
      throw ToolExecutionException(
        'The model did not invoke the run_workflow tool.',
        toolName: 'run_workflow',
      );
    }
    if (workflowStep.status == StepStatus.error) {
      throw ToolExecutionException(
        workflowStep.error.isEmpty
            ? 'Workflow execution failed.'
            : workflowStep.error,
        toolName: 'run_workflow',
      );
    }
    final progress = workflowStep.workflowProgress;
    return WorkflowResult(
      response.chunks,
      conversation: conversation,
      scriptPath: progress == null || progress.scriptPath.isEmpty
          ? resolvedPath
          : progress.scriptPath,
      script: progress?.script ?? '',
      description: progress == null || progress.description.isEmpty
          ? effectiveDescription
          : progress.description,
      output: progress?.output ?? '',
      responseText: responseText,
    );
  }
}

/// Encodes [value] as JSON the way Python's `json.dumps(value, allow_nan=False)`
/// does: `", "` and `": "` separators and non-ASCII characters escaped as
/// `\uXXXX`. Objects that are not JSON primitives are converted through their
/// `toJson()` method.
///
/// Throws a [JsonUnsupportedObjectError] for values that cannot be encoded,
/// including NaN and infinite numbers.
String _encodePythonJson(Object? value) {
  final buffer = StringBuffer();
  _writePythonJson(buffer, value);
  return buffer.toString();
}

void _writePythonJson(StringBuffer out, Object? value) {
  switch (value) {
    case null:
      out.write('null');
    case bool():
      out.write(value ? 'true' : 'false');
    case int():
      out.write(value);
    case double():
      if (!value.isFinite) {
        throw JsonUnsupportedObjectError(
          value,
          cause: 'Out of range float values are not JSON compliant',
        );
      }
      out.write(value);
    case String():
      _writePythonJsonString(out, value);
    case List():
      out.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) out.write(', ');
        _writePythonJson(out, value[i]);
      }
      out.write(']');
    case Map():
      out.write('{');
      var first = true;
      for (final MapEntry(:key, value: entry) in value.entries) {
        if (key is! String) {
          throw JsonUnsupportedObjectError(
            key,
            cause: 'keys must be str, int, float, bool or None',
          );
        }
        if (!first) out.write(', ');
        first = false;
        _writePythonJsonString(out, key);
        out.write(': ');
        _writePythonJson(out, entry);
      }
      out.write('}');
    default:
      // Mirror jsonEncode: fall back to the object's toJson() method.
      final Object? encodable;
      try {
        encodable = (value as dynamic).toJson();
      } on NoSuchMethodError {
        throw JsonUnsupportedObjectError(value);
      }
      _writePythonJson(out, encodable);
  }
}

void _writePythonJsonString(StringBuffer out, String value) {
  out.write('"');
  for (final unit in value.codeUnits) {
    switch (unit) {
      case 0x22:
        out.write(r'\"');
      case 0x5c:
        out.write(r'\\');
      case 0x0a:
        out.write(r'\n');
      case 0x0d:
        out.write(r'\r');
      case 0x09:
        out.write(r'\t');
      case 0x08:
        out.write(r'\b');
      case 0x0c:
        out.write(r'\f');
      case >= 0x20 && <= 0x7e:
        out.writeCharCode(unit);
      default:
        out.write(r'\u');
        out.write(unit.toRadixString(16).padLeft(4, '0'));
    }
  }
  out.write('"');
}
