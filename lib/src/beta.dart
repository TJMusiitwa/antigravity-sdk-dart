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
  AgentBeta(this._agent, this._config);

  /// Executes a Python workflow script through the harness's sandbox.
  ///
  /// `~` is expanded, and a relative [scriptPath] is resolved against the
  /// first workspace when the script exists there, otherwise against the
  /// current directory. The script is checked with [validateWorkflowSource]
  /// before the model is asked to run it.
  ///
  /// Throws an [ArgumentError] if [scriptPath] is empty or
  /// [BuiltinTools.runWorkflow] is not enabled, a [FileSystemException] if the
  /// script does not exist, a [WorkflowException] if it fails validation, and
  /// a [ToolExecutionException] if the model does not run the workflow or the
  /// workflow fails.
  Future<WorkflowResult> runWorkflow({
    required String scriptPath,
    String description = '',
  }) async {
    final conversation = _agent.conversation;
    final capabilities = _config.capabilities;
    final active = capabilities.enabledTools?.toSet() ??
        BuiltinTools.defaultTools().toSet().difference(
              capabilities.disabledTools?.toSet() ?? {},
            );
    if (!capabilities.enableSubagents ||
        !active.contains(BuiltinTools.runWorkflow)) {
      throw ArgumentError(
          'BuiltinTools.runWorkflow is not enabled on this agent.');
    }
    if (scriptPath.trim().isEmpty) {
      throw ArgumentError('scriptPath must not be empty.');
    }
    var file = File(normalizeWorkspacePath(scriptPath));
    final isRelative = !p.isAbsolute(scriptPath) && !scriptPath.startsWith('~');
    if (isRelative && _config.workspaces.isNotEmpty) {
      final candidate = File(
          p.join(normalizeWorkspacePath(_config.workspaces.first), scriptPath));
      if (await candidate.exists()) file = candidate;
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
    final response = await _agent.chat(
      'Run the workflow script at `$resolvedPath` ($effectiveDescription) using the `run_workflow` tool.',
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
          toolName: 'run_workflow');
    }
    if (workflowStep.status == StepStatus.error) {
      throw ToolExecutionException(
          workflowStep.error.isEmpty
              ? 'Workflow execution failed.'
              : workflowStep.error,
          toolName: 'run_workflow');
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
