import 'dart:async';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import '../../hooks/hooks.dart';
import '../../hooks/policy.dart';
import '../../tools/tool_runner.dart';
import '../../triggers/triggers.dart';
import '../../types.dart';
import '../connection.dart';
import 'local_connection.dart';

part 'local_connection_config.mapper.dart';

/// Default local app data directory location.
String get defaultAppDataDir {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  return '$home${Platform.pathSeparator}.gemini${Platform.pathSeparator}antigravity';
}

/// Configuration for the local harness backend.
@MappableClass(
  includeCustomMappers: [
    ToolMapper(),
    PolicyMapper(),
    HookMapper(),
    TriggerMapper(),
  ],
)
class LocalAgentConfig extends AgentConfig with LocalAgentConfigMappable {
  /// Shorthand option to set explicit configuration targets for a single model or overrides.
  /// Can be a string model name or a full [ModelTarget].
  final dynamic model; // String or ModelTarget

  /// Shorthand option to supply a list of configurations per model.
  final List<ModelTarget>? models;

  /// Shorthand option to override the Gemini API key.
  final String? apiKey;

  /// Shorthand option to enable Vertex AI.
  final bool vertex;

  /// Shorthand option to set Vertex AI GCP project.
  final String? project;

  /// Shorthand option to set Vertex AI location.
  final String? location;

  /// Shorthand option to override the default localharness binary path.
  final String? binaryPath;

  /// Creates a new [LocalAgentConfig] configuration for the Google Antigravity SDK.
  LocalAgentConfig({
    super.systemInstructions,
    CapabilitiesConfig? capabilities,
    List<Tool>? tools,
    super.policies,
    List<Hook>? hooks,
    List<Trigger>? triggers,
    List<McpServerConfig>? mcpServers,
    List<SubagentConfig>? subagents,
    List<String>? workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    List<String>? skillsPaths,
    this.model,
    this.models,
    this.apiKey,
    this.vertex = false,
    this.project,
    this.location,
    this.binaryPath,
  }) : super(
          capabilities: capabilities ?? CapabilitiesConfig(),
          tools: tools ?? [],
          hooks: hooks ?? [],
          triggers: triggers ?? [],
          mcpServers: mcpServers ?? [],
          subagents: subagents ?? [],
          workspaces: workspaces ?? [Directory.current.absolute.path],
          skillsPaths: skillsPaths ?? [],
        ) {
    _applyWorkspacePolicies();
  }

  ModelEndpoint? _buildShorthandEndpoint() {
    if (vertex) {
      return VertexEndpoint(project: project, location: location);
    }
    return GeminiAPIEndpoint(apiKey: apiKey);
  }

  List<ModelTarget> _buildShorthandModels(ModelEndpoint? endpoint) {
    return switch (model) {
      null => [],
      ModelTarget mt => [
          mt.copyWith(endpoint: mt.endpoint ?? endpoint),
        ],
      String name => [
          ModelTarget(
            name: name,
            types: [ModelType.text],
            endpoint: endpoint,
          ),
        ],
      _ => throw ArgumentError(
          'Expected ModelTarget or String for model, got ${model.runtimeType}',
        ),
    };
  }

  List<ModelTarget> _buildDefaultModels(ModelEndpoint? endpoint) {
    return [
      ModelTarget(
        name: defaultModel,
        types: [ModelType.text],
        endpoint: endpoint,
      ),
      ModelTarget(
        name: defaultImageGenerationModel,
        types: [ModelType.image],
        endpoint: endpoint,
      ),
    ];
  }

  List<ModelTarget> _mergeModelsList() {
    final endpoint = _buildShorthandEndpoint();
    final explicitModels = models ?? <ModelTarget>[];
    final shorthandModels = _buildShorthandModels(endpoint);
    final defaultModels = _buildDefaultModels(endpoint);

    final mergedModels = List<ModelTarget>.from(explicitModels);
    mergedModels.addAll(shorthandModels);

    final existingTypes = <ModelType>{};
    for (final m in mergedModels) {
      existingTypes.addAll(m.types);
    }

    for (final defaultModel in defaultModels) {
      if (!defaultModel.types.any((t) => existingTypes.contains(t))) {
        mergedModels.add(defaultModel);
      }
    }

    return mergedModels;
  }

  void _applyWorkspacePolicies() {
    // Automatically add workspace containment policies for all declared workspaces
    for (final ws in workspaces) {
      policies.add(workspace(ws));
    }
  }

  @override
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) {
    final effectiveSaveDir =
        saveDir != null ? Directory(saveDir!).absolute.path : null;

    return LocalConnectionStrategy(
      binaryPath: binaryPath,
      toolRunner: toolRunner,
      hookRunner: hookRunner,
      models: _mergeModelsList(),
      systemInstructions: systemInstructions,
      capabilitiesConfig: capabilities,
      conversationId: conversationId,
      saveDir: effectiveSaveDir,
      workspaces: workspaces,
      appDataDir: appDataDir ?? defaultAppDataDir,
      skillsPaths: skillsPaths,
      mcpServers: mcpServers,
      subagents: subagents,
    );
  }
}
