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

/// Base configuration class for local harness agent configurations.
@MappableClass()
abstract class BaseLocalAgentConfig extends AgentConfig
    with BaseLocalAgentConfigMappable {
  BaseLocalAgentConfig({
    super.systemInstructions,
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.mcpServers,
    super.subagents,
    super.workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
  }) {
    _applyWorkspacePolicies();
  }

  void _applyWorkspacePolicies() {
    // Automatically add workspace containment policies for all declared workspaces
    for (final ws in workspaces) {
      policies.add(workspace(ws));
    }
  }
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
class LocalAgentConfig extends BaseLocalAgentConfig
    with LocalAgentConfigMappable {
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
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.mcpServers,
    super.subagents,
    super.workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
    this.model,
    this.models,
    this.apiKey,
    this.vertex = false,
    this.project,
    this.location,
    this.binaryPath,
  });

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

/// OpenAI-compatible local completions API configuration.
@MappableClass()
class LocalOpenAIAgentConfig extends BaseLocalAgentConfig
    with LocalOpenAIAgentConfigMappable {
  final dynamic model; // String or ModelTarget
  final String? baseUrl;

  LocalOpenAIAgentConfig({
    this.model,
    this.baseUrl,
    super.systemInstructions,
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.mcpServers,
    super.subagents,
    super.workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
  });

  @override
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) {
    final effectiveSaveDir =
        saveDir != null ? Directory(saveDir!).absolute.path : null;

    String modelName = '';
    String? resolvedBaseUrl = baseUrl;
    if (model is ModelTarget) {
      final mt = model as ModelTarget;
      modelName = mt.name ?? '';
      if (resolvedBaseUrl == null || resolvedBaseUrl.isEmpty) {
        if (mt.endpoint != null) {
          resolvedBaseUrl = mt.endpoint!.baseUrl;
        }
      }
    } else if (model is String) {
      modelName = model as String;
    }

    return LocalOpenAIConnectionStrategy(
      baseUrl: resolvedBaseUrl ?? '',
      modelName: modelName,
      toolRunner: toolRunner,
      hookRunner: hookRunner,
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

/// Hardware backend options for local LiteRT model execution.
@MappableEnum(caseStyle: CaseStyle.lowerCase)
enum LiteRTBackend {
  cpu('cpu'),
  gpu('gpu'),
  npu('npu');

  final String value;
  const LiteRTBackend(this.value);
}

/// Configuration for local Gemma models using a managed LiteRT-LM backend.
@MappableClass()
class LiteRTAgentConfig extends BaseLocalAgentConfig
    with LiteRTAgentConfigMappable {
  final String modelPath;
  final LiteRTBackend backend;
  final bool enableSpeculativeDecoding;
  final String? cacheDir;
  final LiteRTBackend? audioBackend;
  final LiteRTBackend? visionBackend;
  final int port;
  final bool downloadIfMissing;
  final int? maxContextTokens;

  LiteRTAgentConfig({
    required this.modelPath,
    this.backend = LiteRTBackend.gpu,
    this.enableSpeculativeDecoding = false,
    this.cacheDir,
    this.audioBackend,
    this.visionBackend,
    this.port = 0,
    this.downloadIfMissing = false,
    this.maxContextTokens,
    super.systemInstructions,
    super.capabilities,
    super.tools,
    super.policies,
    super.hooks,
    super.triggers,
    super.mcpServers,
    super.subagents,
    super.workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
  });

  @override
  ConnectionStrategy createStrategy({
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) {
    final effectiveSaveDir =
        saveDir != null ? Directory(saveDir!).absolute.path : null;

    return LiteRTConnectionStrategy(
      modelPath: modelPath,
      backend: backend,
      enableSpeculativeDecoding: enableSpeculativeDecoding,
      cacheDir: cacheDir,
      audioBackend: audioBackend,
      visionBackend: visionBackend,
      port: port,
      downloadIfMissing: downloadIfMissing,
      maxContextTokens: maxContextTokens,
      toolRunner: toolRunner,
      hookRunner: hookRunner,
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
