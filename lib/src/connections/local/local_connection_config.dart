import 'dart:io';
import 'package:dart_mappable/dart_mappable.dart';
import '../../hooks/policy.dart';
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
@MappableClass()
class LocalAgentConfig extends AgentConfig with LocalAgentConfigMappable {
  final GeminiConfig geminiConfig;
  final String? model;
  final String? apiKey;
  final String? binaryPath;

  LocalAgentConfig({
    super.systemInstructions,
    CapabilitiesConfig? capabilities,
    List<dynamic>? tools,
    List<dynamic>? policies,
    List<dynamic>? hooks,
    List<dynamic>? triggers,
    List<McpServerConfig>? mcpServers,
    List<String>? workspaces,
    super.conversationId,
    super.saveDir,
    super.appDataDir,
    super.responseSchema,
    List<String>? skillsPaths,
    GeminiConfig? geminiConfig,
    this.model,
    this.apiKey,
    this.binaryPath,
  }) : geminiConfig = geminiConfig ?? GeminiConfig(),
       super(
         capabilities: capabilities ?? CapabilitiesConfig(),
         tools: tools ?? [],
         policies: policies ?? [],
         hooks: hooks ?? [],
         triggers: triggers ?? [],
         mcpServers: mcpServers ?? [],
         workspaces: workspaces ?? [Directory.current.absolute.path],
         skillsPaths: skillsPaths ?? [],
       ) {
    _validateAndApplyShorthands();
    _applyWorkspacePolicies();
  }

  void _validateAndApplyShorthands() {
    // Top-level shorthand fields flow into geminiConfig
    if (model != null) {
      if (geminiConfig.models.defaultModelEntry.name != defaultModel) {
        throw AntigravityValidationException(
          "Cannot set both 'model' shorthand and 'geminiConfig.models.default'. Use one or the other.",
        );
      }
    }
    if (apiKey != null) {
      if (geminiConfig.apiKey != null) {
        throw AntigravityValidationException(
          "Cannot set both 'apiKey' shorthand and 'geminiConfig.apiKey'. Use one or the other.",
        );
      }
    }
  }

  void _applyWorkspacePolicies() {
    // Automatically add workspace containment policies for all declared workspaces
    for (final ws in workspaces) {
      policies.add(workspace(ws));
    }
  }

  @override
  ConnectionStrategy createStrategy({
    required dynamic toolRunner,
    required dynamic hookRunner,
  }) {
    // Merge shorthand into effective config for the strategy
    final effectiveApiKey = apiKey ?? geminiConfig.apiKey;
    final effectiveModel = model != null
        ? ModelEntry(name: model!)
        : geminiConfig.models.defaultModelEntry;

    final effectiveGeminiConfig = geminiConfig.copyWith(
      apiKey: effectiveApiKey,
      models: geminiConfig.models.copyWith(defaultModelEntry: effectiveModel),
    );

    final effectiveSaveDir = saveDir != null
        ? Directory(saveDir!).absolute.path
        : null;

    return LocalConnectionStrategy(
      binaryPath: binaryPath,
      toolRunner: toolRunner,
      hookRunner: hookRunner,
      geminiConfig: effectiveGeminiConfig,
      systemInstructions: systemInstructions,
      capabilitiesConfig: capabilities,
      conversationId: conversationId,
      saveDir: effectiveSaveDir,
      workspaces: workspaces,
      appDataDir: appDataDir ?? defaultAppDataDir,
      skillsPaths: skillsPaths,
      mcpServers: mcpServers,
    );
  }
}
