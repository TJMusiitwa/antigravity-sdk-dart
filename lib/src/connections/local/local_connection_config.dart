import 'dart:async';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:path/path.dart' as p;

import '../../hooks/hooks.dart';
import '../../hooks/policy.dart';
import '../../tools/tool_runner.dart';
import '../../triggers/triggers.dart';
import '../../types.dart';
import '../connection.dart';
import 'hook_router.dart';
import 'local_connection.dart';

part 'local_connection_config.mapper.dart';

/// Default local app data directory location.
String get defaultAppDataDir {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  return '$home${Platform.pathSeparator}.gemini${Platform.pathSeparator}antigravity';
}

/// Normalizes wire URIs, expands user home ~, and resolves relative paths to clean absolute filesystem paths.
String normalizeWorkspacePath(String path) {
  if (path.isEmpty) return '';
  final normalized = normalizeWirePath(path);
  if (normalized.startsWith('/cns/')) {
    return normalized;
  }
  final isWindowsDrive = RegExp(r'^[a-zA-Z]:').hasMatch(normalized);
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.scheme == 'file' || isWindowsDrive) {
    var rawPath = normalized;
    if (rawPath.startsWith('~')) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '';
      rawPath = rawPath.replaceFirst('~', home);
    }
    return p.normalize(Directory(rawPath).absolute.path);
  }
  return normalized;
}

/// Coerces sequence workspace paths and normalizes each entry.
List<String> normalizeWorkspacePaths(
  dynamic workspaces, {
  bool defaultToCwd = false,
}) {
  if (workspaces == null) {
    return defaultToCwd ? [Directory.current.absolute.path] : [];
  }
  if (workspaces is String) {
    return [normalizeWorkspacePath(workspaces)];
  }
  if (workspaces is Iterable) {
    return workspaces
        .map((ws) => normalizeWorkspacePath(ws.toString()))
        .toList();
  }
  throw ArgumentError(
    'workspaces must be a sequence of paths, got ${workspaces.runtimeType}',
  );
}

/// Creates a unique step identifier from trajectory ID and step index.
///
/// Returns `"<trajectoryId>:<stepIndex>"` when both parts are present, or
/// whichever single part is available. Returns null when neither is usable.
/// Mirrors `make_step_id` in the upstream Python SDK.
String? makeStepId(Object? trajectoryId, Object? stepIndex) {
  final traj = trajectoryId?.toString();
  final idx = stepIndex?.toString();
  if (traj != null && traj.isNotEmpty && idx != null && idx.isNotEmpty) {
    return '$traj:$idx';
  }
  if (idx != null && idx.isNotEmpty) {
    return idx;
  }
  if (traj != null && traj.isNotEmpty) {
    return traj;
  }
  return null;
}

/// Base configuration class for local harness agent configurations.
@MappableClass()
abstract class BaseLocalAgentConfig extends AgentConfig
    with BaseLocalAgentConfigMappable {
  BaseLocalAgentConfig({
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
    super.sessionContinuationMode,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    List<String>? skillsPaths,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
    super.compactionConfig,
  }) : super(
          capabilities: capabilities ?? CapabilitiesConfig(),
          tools: tools ?? const [],
          hooks: hooks ?? const [],
          triggers: triggers ?? const [],
          mcpServers: mcpServers ?? const [],
          subagents: subagents ?? const [],
          workspaces: normalizeWorkspacePaths(workspaces, defaultToCwd: true),
          skillsPaths: skillsPaths ?? const [],
        ) {
    _validateAllowedSubagents();
    _applyWorkspacePolicies();
  }

  void _validateAllowedSubagents() {
    final declaredNames = subagents.map((s) => s.name).toSet();
    _checkUnknownSubagents(
      'CapabilitiesConfig.allowedSubagents',
      capabilities.allowedSubagents,
      declaredNames,
    );
    for (final sub in subagents) {
      _checkUnknownSubagents(
        "SubagentConfig('${sub.name}').capabilities.allowedSubagents",
        sub.capabilities?.allowedSubagents,
        declaredNames,
      );
    }
  }

  void _checkUnknownSubagents(
    String contextName,
    List<String>? allowed,
    Set<String> declared,
  ) {
    if (allowed == null || allowed.isEmpty) return;
    final unknown = allowed.toSet().difference(declared);
    if (unknown.isNotEmpty) {
      final sortedUnknown = unknown.toList()..sort();
      final sortedValid = declared.toList()..sort();
      throw AntigravityValidationException(
        'Unknown subagent name(s) in $contextName: $sortedUnknown. Valid subagents are: $sortedValid',
      );
    }
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
    super.sessionContinuationMode,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
    super.compactionConfig,
    this.model,
    this.models,
    this.apiKey,
    bool? vertex,
    this.project,
    this.location,
    this.binaryPath,
  }) : vertex = vertex ??
            (Platform.environment['GOOGLE_GENAI_USE_VERTEXAI']
                        ?.toLowerCase() ==
                    'true' ||
                Platform.environment['GOOGLE_GENAI_USE_VERTEXAI'] == '1' ||
                Platform.environment['GOOGLE_GENAI_USE_ENTERPRISE']
                        ?.toLowerCase() ==
                    'true' ||
                Platform.environment['GOOGLE_GENAI_USE_ENTERPRISE'] == '1');

  ModelEndpoint? _buildShorthandEndpoint() {
    if (vertex) {
      return VertexEndpoint(
        project: project,
        location: location,
        apiKey: apiKey,
      );
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
  LocalAgentConfig lightweight() => copyWith(
        compactionConfig: lightweightCompactionConfig(),
        capabilities: lightweightCapabilities(),
      );

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
      tools: tools,
      models: _mergeModelsList(),
      systemInstructions: systemInstructions,
      capabilitiesConfig: capabilities,
      conversationId: conversationId,
      sessionContinuationMode: sessionContinuationMode,
      saveDir: effectiveSaveDir,
      workspaces: workspaces,
      appDataDir: appDataDir ?? defaultAppDataDir,
      skillsPaths: skillsPaths,
      mcpServers: mcpServers,
      subagents: subagents,
      debugConfig: debugConfig,
      retryConfig: retryConfig,
      budgetConfig: budgetConfig,
      compactionConfig: effectiveCompactionConfig,
    );
  }
}

/// OpenAI-compatible local completions API configuration.
@MappableClass()
class LocalOpenAIAgentConfig extends BaseLocalAgentConfig
    with LocalOpenAIAgentConfigMappable {
  /// The model target to execute, either as a model name string or a [ModelTarget].
  final dynamic model; // String or ModelTarget

  /// The target OpenAI-compatible base URL (e.g. 'http://localhost:11434/v1').
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
    super.sessionContinuationMode,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
    super.compactionConfig,
  });

  @override
  LocalOpenAIAgentConfig lightweight() => copyWith(
        compactionConfig: lightweightCompactionConfig(),
        capabilities: lightweightCapabilities(),
      );

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
      tools: tools,
      systemInstructions: systemInstructions,
      capabilitiesConfig: capabilities,
      conversationId: conversationId,
      sessionContinuationMode: sessionContinuationMode,
      saveDir: effectiveSaveDir,
      workspaces: workspaces,
      appDataDir: appDataDir ?? defaultAppDataDir,
      skillsPaths: skillsPaths,
      mcpServers: mcpServers,
      subagents: subagents,
      debugConfig: debugConfig,
      retryConfig: retryConfig,
      budgetConfig: budgetConfig,
      compactionConfig: effectiveCompactionConfig,
    );
  }
}

/// Hardware backend options for local LiteRT model execution.
@MappableEnum(caseStyle: CaseStyle.snakeCase)
enum LiteRTBackend {
  cpu,
  gpu,
  npu,
}

/// Agent configuration for executing on-device local models via LiteRT.
@MappableClass()
class LiteRTAgentConfig extends BaseLocalAgentConfig
    with LiteRTAgentConfigMappable {
  /// Path to the LiteRT `.bin`, `.task`, or `.tflite` model file on the local filesystem.
  final String modelPath;

  /// Hardware acceleration backend (`gpu`, `cpu`, or `npu`).
  final LiteRTBackend backend;

  /// Whether to enable speculative decoding for accelerated sampling.
  final bool enableSpeculativeDecoding;

  /// Optional directory cache for model weights/compilation artifacts.
  final String? cacheDir;

  /// Hardware backend for audio preprocessing/inference.
  final LiteRTBackend? audioBackend;

  /// Hardware backend for vision preprocessing/inference.
  final LiteRTBackend? visionBackend;

  /// Port on localhost to bind the internal LiteRT HTTP server to (0 for automatic random port).
  final int port;

  /// Whether to automatically download the model from Kaggle/HuggingFace if missing.
  final bool downloadIfMissing;

  /// Maximum sequence length/context window for the LiteRT runner.
  @Deprecated(
    'Use the LiteRT server context configuration instead. '
    'CompactionConfig now only controls tokenThreshold.',
  )
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
    super.sessionContinuationMode,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    super.skillsPaths,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
    super.compactionConfig,
  });

  /// Returns the shared compaction policy, if one was configured.
  @override
  CompactionConfig? get effectiveCompactionConfig {
    return super.effectiveCompactionConfig;
  }

  /// The context-window ceiling handed to the LiteRT runner.
  int? get effectiveMaxContextTokens => maxContextTokens;

  @override
  LiteRTAgentConfig lightweight() => copyWith(
        compactionConfig: lightweightCompactionConfig(),
        capabilities: lightweightCapabilities(),
      );

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
      maxContextTokens: effectiveMaxContextTokens,
      toolRunner: toolRunner,
      hookRunner: hookRunner,
      tools: tools,
      systemInstructions: systemInstructions,
      capabilitiesConfig: capabilities,
      conversationId: conversationId,
      sessionContinuationMode: sessionContinuationMode,
      saveDir: effectiveSaveDir,
      workspaces: workspaces,
      appDataDir: appDataDir ?? defaultAppDataDir,
      skillsPaths: skillsPaths,
      mcpServers: mcpServers,
      subagents: subagents,
      debugConfig: debugConfig,
      retryConfig: retryConfig,
      budgetConfig: budgetConfig,
      compactionConfig: effectiveCompactionConfig,
    );
  }
}
