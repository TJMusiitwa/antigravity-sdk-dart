import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:web_socket_channel/status.dart' as status;

import '../../hooks/hooks.dart';
import '../../tools/tool_runner.dart';
import '../../types.dart';
import '../../utils/binary_discovery.dart';
import '../../version.dart';
import '../connection.dart';
import 'hook_router.dart';
import 'litert_server_python.dart';
import 'local_connection_config.dart';
import 'localharness_proto.dart';

final _logger = Logger('antigravity.connection.local');

/// Strategy for establishing a LocalConnection to a Go-based localharness binary.
/// Builds the `run_command` harness-side tool proto map.
///
/// [enabled] reflects whether the builtin run_command tool is active. When
/// [cfg] is null the upstream defaults are emitted (daemons disabled and a
/// `max_timeout_ms` of 0, which the harness reads as "use the default
/// timeout"), matching `RunCommandToolConfig` in the Python SDK.
Map<String, dynamic> _runCommandToolProto(bool enabled, RunCommandConfig? cfg) {
  final timeoutSeconds = cfg?.timeoutSeconds;
  return {
    'enabled': enabled,
    'enable_daemon_commands': cfg?.enableDaemons ?? false,
    'max_timeout_ms':
        timeoutSeconds != null ? (timeoutSeconds * 1000).round() : 0,
  };
}

class LocalConnectionStrategy implements ConnectionStrategy {
  final String? _configuredBinaryPath;
  final ToolRunner _toolRunner;
  final HookRunner _hookRunner;
  final List<ModelTarget>? _models;
  final dynamic _systemInstructions;
  final CapabilitiesConfig _capabilitiesConfig;
  final String? _conversationId;
  final SessionContinuationMode? _sessionContinuationMode;
  final String? _saveDir;
  final List<String> _workspaces;
  final String? _appDataDir;
  final List<String> _skillsPaths;
  final List<McpServerConfig> _mcpServers;
  final List<SubagentConfig> _subagents;
  final DebugConfig? _debugConfig;
  final RetryConfig? _retryConfig;
  final BudgetConfig? _budgetConfig;

  Process? _process;
  WebSocket? _ws;
  LocalConnection? _connection;

  /// Creates a new [LocalConnectionStrategy] for the Google Antigravity SDK.
  ///
  /// Specifying [binaryPath] overrides the automatic detection of the localharness binary.
  /// Takes [toolRunner] for execution and [hookRunner] to run interceptors.
  LocalConnectionStrategy({
    String? binaryPath,
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
    List<ModelTarget>? models,
    required dynamic systemInstructions,
    required CapabilitiesConfig capabilitiesConfig,
    String? conversationId,
    SessionContinuationMode? sessionContinuationMode,
    String? saveDir,
    required List<String> workspaces,
    String? appDataDir,
    required List<String> skillsPaths,
    List<McpServerConfig>? mcpServers,
    List<SubagentConfig>? subagents,
    DebugConfig? debugConfig,
    RetryConfig? retryConfig,
    BudgetConfig? budgetConfig,
  })  : _configuredBinaryPath = binaryPath,
        _toolRunner = toolRunner,
        _hookRunner = hookRunner,
        _models = models,
        _systemInstructions = systemInstructions,
        _capabilitiesConfig = capabilitiesConfig,
        _conversationId = conversationId,
        _sessionContinuationMode = sessionContinuationMode,
        _saveDir = saveDir,
        _workspaces = workspaces,
        _appDataDir = appDataDir,
        _skillsPaths = skillsPaths,
        _mcpServers = mcpServers ?? const [],
        _subagents = subagents ?? const [],
        _debugConfig = debugConfig,
        _retryConfig = retryConfig,
        _budgetConfig = budgetConfig;

  @override
  DebugConfig? get debugConfig => _debugConfig;

  @override
  Connection connect() {
    if (_connection == null) {
      throw StateError('Connection not established. Call start() first.');
    }
    return _connection!;
  }

  void _validateConnection() {
    if (_models != null) {
      for (final m in _models!) {
        if (m.endpoint != null) {
          try {
            m.endpoint!.validateEndpoint();
          } catch (e) {
            throw AntigravityValidationException(e.toString());
          }
        } else {
          throw AntigravityValidationException(
            "Model '${m.name}' must have an endpoint configured.",
          );
        }
      }
    }
  }

  @override
  Future<void> start() async {
    _validateConnection();

    final resolvedBinaryPath = await BinaryDiscovery.discover(
      configPath: _configuredBinaryPath,
    );
    _logger.info('Starting localharness binary at: $resolvedBinaryPath');

    _process = await Process.start(resolvedBinaryPath, []);
    await _sendHandshakeInputConfig(_process!);

    final outputConfig = await _readHandshakeOutputConfig(_process!);
    final ws = await _connectWebSocketWithRetry(outputConfig, _process!);
    _ws = ws;
    final sessionData = await _initializeHarnessSession(ws, _process!);

    _connection = LocalConnection(
      process: _process!,
      ws: _ws!,
      messageStream: sessionData.messageStream,
      toolRunner: _toolRunner,
      hookRunner: _hookRunner,
      initialHistory: sessionData.initialHistory,
      conversationId: sessionData.cascadeId,
      cumulativeUsage: sessionData.cumulativeUsage,
      trajectoryUsages: sessionData.trajectoryUsages,
    );
    _connection!._startStderrReader();
    _connection!._startReaderLoop();
  }

  Future<void> _sendHandshakeInputConfig(Process process) async {
    final inputConfigBytes = LocalHarnessProto.encodeInputConfig(
      storageDirectory: _saveDir ?? '',
      clientLanguage: 'dart',
      clientVersion: packageVersion,
      clientLanguageVersion: Platform.version,
    );
    final packedMessage = LocalHarnessProto.packMessage(inputConfigBytes);
    process.stdin.add(packedMessage);
    await process.stdin.flush();
  }

  Future<LocalHarnessProto> _readHandshakeOutputConfig(Process process) async {
    try {
      final reader = HandshakeReader();
      return await reader.read(process.stdout);
    } catch (e) {
      process.kill();
      final stderrText = await process.stderr.transform(utf8.decoder).join();
      _logger.severe('Failed to handshake with localharness. Stderr: $stderrText');
      throw Exception('Failed to handshake with localharness process. Stderr: $stderrText. Error: $e');
    }
  }

  Future<WebSocket> _connectWebSocketWithRetry(LocalHarnessProto outputConfig, Process process) async {
    int attempt = 0;
    const maxRetries = 5;
    Object? lastException;

    while (attempt < maxRetries) {
      for (final host in ['localhost', '127.0.0.1']) {
        try {
          return await WebSocket.connect(
            'ws://$host:${outputConfig.port}/',
            headers: {'x-goog-api-key': outputConfig.apiKey},
          );
        } catch (e) {
          lastException = e;
        }
      }
      attempt++;
      if (attempt >= maxRetries) {
        process.kill();
        final stderrText = await process.stderr.transform(utf8.decoder).join();
        throw Exception(
          'Failed to connect to WebSocket after $maxRetries attempts. Last error: $lastException. Stderr: $stderrText',
        );
      }
      final delay = Duration(milliseconds: 100 * (1 << attempt));
      _logger.warning('WebSocket connection failed. Retrying in ${delay.inMilliseconds}ms...');
      await Future.delayed(delay);
    }
    throw StateError('Unreachable');
  }

  Future<({
    List<Step> initialHistory,
    Stream<dynamic> messageStream,
    String? cascadeId,
    UsageMetadata? cumulativeUsage,
    Map<String, UsageMetadata>? trajectoryUsages,
  })> _initializeHarnessSession(
    WebSocket ws,
    Process process,
  ) async {
    final initCompleter = Completer<({
      List<Step> initialHistory,
      String? cascadeId,
      UsageMetadata? cumulativeUsage,
      Map<String, UsageMetadata>? trajectoryUsages,
    })>();
    final messageController = StreamController<dynamic>();

    ws.listen(
      (message) => _handleInitMessage(message, initCompleter, messageController),
      onError: (err) {
        if (!initCompleter.isCompleted) initCompleter.completeError(err);
        messageController.addError(err);
      },
      onDone: () {
        if (!initCompleter.isCompleted) {
          initCompleter.complete((
            initialHistory: <Step>[],
            cascadeId: null,
            cumulativeUsage: null,
            trajectoryUsages: null,
          ));
        }
        messageController.close();
      },
    );

    final harnessConfig = _buildHarnessConfig();
    ws.add(jsonEncode({'config': harnessConfig}));

    try {
      final sessionData = await initCompleter.future;
      return (
        initialHistory: sessionData.initialHistory,
        messageStream: messageController.stream,
        cascadeId: sessionData.cascadeId,
        cumulativeUsage: sessionData.cumulativeUsage,
        trajectoryUsages: sessionData.trajectoryUsages,
      );
    } catch (e) {
      process.kill();
      final stderrText = await process.stderr.transform(utf8.decoder).join();
      _logger.severe('Failed to initialize conversation with localharness. Stderr: $stderrText');
      throw Exception('Failed to initialize conversation with localharness process. Stderr: $stderrText. Error: $e');
    }
  }

  void _handleInitMessage(
    dynamic message,
    Completer<({
      List<Step> initialHistory,
      String? cascadeId,
      UsageMetadata? cumulativeUsage,
      Map<String, UsageMetadata>? trajectoryUsages,
    })> initCompleter,
    StreamController<dynamic> messageController,
  ) {
    if (!initCompleter.isCompleted && message is String) {
      try {
        final parsed = jsonDecode(message);
        if (parsed is Map) {
          final normalized = LocalConnection._normalizeJsonKeys(Map<String, dynamic>.from(parsed));
          if (normalized.containsKey('initialize_conversation_response')) {
            final initResp = Map<String, dynamic>.from(normalized['initialize_conversation_response'] as Map);
            final initialHistory = _parseInitialHistory(initResp);
            final cascadeId = initResp['cascade_id']?.toString();
            final cum = initResp['cumulative_usage'];
            final cumUsage = cum is Map ? UsageMetadata.fromMap(Map<String, dynamic>.from(cum)) : null;
            final traj = initResp['trajectory_usage'];
            final trajUsages = <String, UsageMetadata>{};
            if (traj is List) {
              for (final entry in traj) {
                if (entry is Map) {
                  final entryMap = Map<String, dynamic>.from(entry);
                  final trajId = entryMap['trajectory_id']?.toString() ?? '';
                  if (trajId.isNotEmpty && entryMap['usage'] is Map) {
                    trajUsages[trajId] = UsageMetadata.fromMap(Map<String, dynamic>.from(entryMap['usage'] as Map));
                  }
                }
              }
            }
            initCompleter.complete((
              initialHistory: initialHistory,
              cascadeId: cascadeId,
              cumulativeUsage: cumUsage,
              trajectoryUsages: trajUsages.isNotEmpty ? trajUsages : null,
            ));
            return;
          }
        }
      } catch (e) {
        initCompleter.completeError(e);
      }
      if (!initCompleter.isCompleted) {
        initCompleter.complete((
          initialHistory: <Step>[],
          cascadeId: null,
          cumulativeUsage: null,
          trajectoryUsages: null,
        ));
      }
    }
    messageController.add(message);
  }

  List<Step> _parseInitialHistory(Map<String, dynamic> initResp) {
    final historyList = initResp['history'];
    if (historyList is! List) return [];
    return historyList
        .whereType<Map>()
        .map((s) => Step.fromMap(Map<String, dynamic>.from(s)))
        .toList();
  }

  @override
  Future<void> stop() async {
    if (_connection != null) {
      await _connection!.disconnect();
      _connection = null;
    }
    _ws = null;
    _process = null;
  }

  Map<String, dynamic> buildHarnessConfigForTest() => _buildHarnessConfig();

  Map<String, dynamic> _buildHarnessConfig() {
    final toolsProtos = _buildToolsProtos();
    final systemInstructionsProto = _buildSystemInstructionsProto(_systemInstructions);
    final modelsProtos = _buildModelsProtos();
    final workspacesProto = _workspaces
        .map((ws) => {'filesystem_workspace': {'directory': ws}})
        .toList();

    final cfg = _capabilitiesConfig;
    final activeTools = _resolveActiveTools(cfg);
    final harnessSideTools = _buildHarnessSideTools(cfg, activeTools);
    final mcpServersProto = _buildMcpServersProto();
    final enabledHooks = _buildEnabledHooks();
    final customAgentsProtos = _buildCustomAgentsProtos(toolsProtos);

    final sessionContinuationModeProto = switch (_sessionContinuationMode) {
      SessionContinuationMode.resume => 'RESUME',
      SessionContinuationMode.createOrResume => 'CREATE_OR_RESUME',
      SessionContinuationMode.createOnly => 'CREATE_ONLY',
      _ => 'SESSION_CONTINUATION_MODE_UNSPECIFIED',
    };

    final retryConfigMap = _retryConfig?.toMap();
    final debugConfigMap = _debugConfig?.toMap();

    return {
      'cascade_id': _conversationId ?? '',
      'session_continuation_mode': sessionContinuationModeProto,
      'agent_behavior': cfg.agentBehavior.protoValue,
      'tools': toolsProtos,
      'system_instructions': systemInstructionsProto,
      'models': modelsProtos,
      'workspaces': workspacesProto,
      'skills_paths': _skillsPaths,
      'harness_side_tools': harnessSideTools,
      'compaction_threshold': cfg.compactionThreshold ?? 0,
      'finish_tool_schema_json': cfg.finishToolSchemaJson ?? '',
      'app_data_dir': _appDataDir ?? '',
      'mcp_servers': mcpServersProto,
      if (_budgetConfig != null) 'budget_config': _budgetConfig!.toMap(),
      if (enabledHooks.isNotEmpty) 'enabled_hooks': enabledHooks,
      if (customAgentsProtos.isNotEmpty) 'custom_subagents': customAgentsProtos,
      if (retryConfigMap != null && retryConfigMap.isNotEmpty)
        'retry_config': retryConfigMap,
      if (debugConfigMap != null && debugConfigMap.isNotEmpty)
        'debug_config': debugConfigMap,
    };
  }

  List<Map<String, dynamic>> _buildToolsProtos() {
    return _toolRunner.tools.values.map((toolFn) {
      return {
        'name': toolFn.name,
        'description': toolFn.description,
        'parameters_json_schema': jsonEncode(toolFn.schema),
      };
    }).toList();
  }

  Map<String, dynamic>? _buildSystemInstructionsProto(dynamic instructions) {
    if (instructions == null) return null;
    if (instructions is String) {
      return {
        'appended': {
          'appended_sections': [
            {'title': 'System', 'content': instructions},
          ],
        },
      };
    }
    if (instructions is CustomSystemInstructions) {
      return {
        'custom': {
          'part': [
            {'text': instructions.text},
          ],
        },
      };
    }
    if (instructions is SystemInstructions) {
      return instructions.toMap();
    }
    return null;
  }

  List<Map<String, dynamic>> _buildModelsProtos() {
    if (_models == null) return <Map<String, dynamic>>[];
    return _models!.map(_buildModelProto).toList();
  }

  Map<String, dynamic> _buildModelProto(dynamic model) {
    final protoMap = <String, dynamic>{};
    if (model.name != null) protoMap['name'] = model.name;
    if (model.types.isNotEmpty) {
      protoMap['types'] = model.types
          .map((t) => 'MODEL_TYPE_${t.value.toUpperCase()}')
          .toList();
    }
    final epMap = _buildEndpointProto(model.endpoint);
    if (epMap != null) protoMap.addAll(epMap);
    return protoMap;
  }

  Map<String, dynamic>? _buildEndpointProto(dynamic endpoint) {
    return switch (endpoint) {
      GeminiAPIEndpoint ep => _buildGeminiEndpointProto(ep),
      VertexEndpoint ep => _buildVertexEndpointProto(ep),
      _ => null,
    };
  }

  Map<String, dynamic> _buildGeminiEndpointProto(GeminiAPIEndpoint ep) {
    final opts = _buildModelOptionsMap(ep.options);
    return {
      'gemini_api_endpoint': {
        if (ep.baseUrl != null) 'base_url': ep.baseUrl,
        if (ep.httpHeaders != null) 'http_headers': ep.httpHeaders,
        if (ep.apiKey != null) 'api_key': ep.apiKey,
        if (opts != null) 'options': opts,
      }
    };
  }

  Map<String, dynamic> _buildVertexEndpointProto(VertexEndpoint ep) {
    final opts = _buildModelOptionsMap(ep.options);
    return {
      'vertex_endpoint': {
        if (ep.baseUrl != null) 'base_url': ep.baseUrl,
        if (ep.httpHeaders != null) 'http_headers': ep.httpHeaders,
        if (ep.project != null) 'project': ep.project,
        if (ep.location != null) 'location': ep.location,
        if (ep.apiKey != null && ep.apiKey!.isNotEmpty) 'api_key': ep.apiKey,
        if (opts != null) 'options': opts,
      }
    };
  }

  Set<BuiltinTools> _resolveActiveTools(CapabilitiesConfig cfg) {
    final allTools = BuiltinTools.values.toSet();
    if (cfg.enabledTools != null) return cfg.enabledTools!.toSet();
    if (cfg.disabledTools != null) return allTools.difference(cfg.disabledTools!.toSet());
    return allTools;
  }

  Map<String, dynamic> _buildHarnessSideTools(
    CapabilitiesConfig cfg,
    Set<BuiltinTools> activeTools,
  ) {
    final subagentsEnabled = cfg.enableSubagents && activeTools.contains(BuiltinTools.startSubagent);
    return {
      'subagents': {
        'enabled': subagentsEnabled,
        if (cfg.maxSubagentDepth != null) 'max_nesting_depth': cfg.maxSubagentDepth,
        if (cfg.allowedSubagents != null && cfg.allowedSubagents!.isNotEmpty)
          'allowed_subagents': cfg.allowedSubagents,
      },
      'find': {'enabled': activeTools.contains(BuiltinTools.findFile)},
      'user_questions': {'enabled': activeTools.contains(BuiltinTools.askQuestion)},
      'run_command': _runCommandToolProto(
        activeTools.contains(BuiltinTools.runCommand),
        cfg.runCommandConfig,
      ),
      'file_edit': {'enabled': activeTools.contains(BuiltinTools.editFile)},
      'view_file': {'enabled': activeTools.contains(BuiltinTools.viewFile)},
      'write_to_file': {'enabled': activeTools.contains(BuiltinTools.createFile)},
      'grep_search': {'enabled': activeTools.contains(BuiltinTools.searchDirectory)},
      'list_dir': {'enabled': activeTools.contains(BuiltinTools.listDirectory)},
      'generate_image': {'enabled': activeTools.contains(BuiltinTools.generateImage)},
      'search_web': {'enabled': activeTools.contains(BuiltinTools.searchWeb)},
      'read_url_content': {'enabled': activeTools.contains(BuiltinTools.readUrlContent)},
    };
  }

  List<Map<String, dynamic>> _buildMcpServersProto() {
    return _mcpServers.map((s) {
      final item = <String, dynamic>{
        'name': s.name,
        'enabled_tools': s.enabledTools ?? const [],
        'disabled_tools': s.disabledTools ?? const [],
        'timeout_seconds': s.timeoutSeconds ?? 0,
      };
      if (s is McpStdioServer) {
        item['stdio'] = {
          'command': s.command,
          'args': s.args,
          if (s.env != null) 'env': s.env,
        };
      } else if (s is McpStreamableHttpServer) {
        item['http'] = {'url': s.url, 'headers': s.headers ?? const {}};
      }
      return item;
    }).toList();
  }

  List<String> _buildEnabledHooks() {
    final enabled = <String>[];
    if (_hookRunner.onSessionStartHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_ON_SESSION_START');
    if (_hookRunner.onSessionEndHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_ON_SESSION_END');
    if (_hookRunner.preTurnHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_PRE_TURN');
    if (_hookRunner.postTurnHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_POST_TURN');
    if (_hookRunner.preToolCallDecideHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_PRE_TOOL');
    if (_hookRunner.postToolCallHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_POST_TOOL');
    if (_hookRunner.onToolErrorHooks.isNotEmpty) enabled.add('LIFECYCLE_HOOK_ON_TOOL_ERROR');
    return enabled;
  }

  List<Map<String, dynamic>> _buildCustomAgentsProtos(List<Map<String, dynamic>> toolsProtos) {
    return _subagents.map((subagent) {
      final subCap = subagent.capabilities;
      final activeSubTools = subCap?.enabledTools?.toSet() ?? BuiltinTools.readOnly().toSet();
      final subagentCanSpawn = activeSubTools.contains(BuiltinTools.startSubagent);

      final resolvedSubTools = <Map<String, dynamic>>[];
      for (final toolName in subagent.tools) {
        if (!toolsProtos.any((t) => t['name'] == toolName)) {
          throw ArgumentError(
            "Subagent tool '$toolName' is not registered on the main agent config. Any custom tools used by subagents must also be added to the main agent's tools list.",
          );
        }
        resolvedSubTools.add(toolsProtos.firstWhere((t) => t['name'] == toolName));
      }

      final subagentInstructionsProto = _buildSubagentSystemInstructions(subagent.systemInstructions);

      return {
        'name': subagent.name,
        'description': subagent.description,
        if (subagentInstructionsProto != null) 'system_instructions': subagentInstructionsProto,
        'harness_side_tools': {
          'subagents': {
            'enabled': subagentCanSpawn,
            if (subCap?.allowedSubagents != null && subCap!.allowedSubagents!.isNotEmpty)
              'allowed_subagents': subCap.allowedSubagents,
          },
          'find': {'enabled': activeSubTools.contains(BuiltinTools.findFile)},
          'run_command': _runCommandToolProto(
            activeSubTools.contains(BuiltinTools.runCommand),
            subCap?.runCommandConfig,
          ),
          'file_edit': {'enabled': activeSubTools.contains(BuiltinTools.editFile)},
          'view_file': {'enabled': activeSubTools.contains(BuiltinTools.viewFile)},
          'write_to_file': {'enabled': activeSubTools.contains(BuiltinTools.createFile)},
          'grep_search': {'enabled': activeSubTools.contains(BuiltinTools.searchDirectory)},
          'list_dir': {'enabled': activeSubTools.contains(BuiltinTools.listDirectory)},
          'generate_image': {'enabled': activeSubTools.contains(BuiltinTools.generateImage)},
          'search_web': {'enabled': activeSubTools.contains(BuiltinTools.searchWeb)},
          'read_url_content': {'enabled': activeSubTools.contains(BuiltinTools.readUrlContent)},
        },
        'tools': resolvedSubTools,
        'agent_behavior': (subCap?.agentBehavior ?? AgentBehavior.autonomous).protoValue,
      };
    }).toList();
  }

  Map<String, dynamic>? _buildSubagentSystemInstructions(dynamic instructions) {
    if (instructions == null) return null;
    if (instructions is String) {
      return {
        'appended': {
          'appended_sections': [
            {'title': 'System', 'content': instructions},
          ],
        },
      };
    }
    if (instructions is List<SystemInstructionSection>) {
      return {
        'appended': {
          'appended_sections': instructions.map((s) => {'title': s.title, 'content': s.content}).toList(),
        },
      };
    }
    if (instructions is CustomSystemInstructions) {
      return {
        'custom': {
          'part': [
            {'text': instructions.text},
          ],
        },
      };
    }
    if (instructions is TemplatedSystemInstructions) {
      return {
        'appended': {
          if (instructions.identity != null) 'custom_identity': instructions.identity,
          'appended_sections': instructions.sections.map((s) => {'title': s.title, 'content': s.content}).toList(),
        },
      };
    }
    if (instructions is SystemInstructions) {
      return instructions.toMap();
    }
    return null;
  }

  Map<String, dynamic>? _buildModelOptionsMap(GeminiModelOptions? options) {
    if (options == null) return null;
    if (options.thinkingLevel == null && options.serviceTier == null) {
      return null;
    }
    return {
      if (options.thinkingLevel != null)
        'thinking_level': options.thinkingLevel!.value,
      if (options.serviceTier != null)
        'service_tier': options.serviceTier!.value,
    };
  }
}

/// Helper class to read handshake payload statefully.
class HandshakeReader {
  final List<int> _buffer = [];
  final Completer<LocalHarnessProto> _completer =
      Completer<LocalHarnessProto>();
  late StreamSubscription<List<int>> _subscription;
  int? _targetLength;

  /// Reads and parses the handshake configuration from the provided stdout [stream].
  Future<LocalHarnessProto> read(Stream<List<int>> stream) {
    _subscription = stream.listen(
      (data) {
        _buffer.addAll(data);
        _process();
      },
      onError: (err) {
        _subscription.cancel();
        _completer.completeError(err);
      },
      onDone: () {
        if (!_completer.isCompleted) {
          _completer.completeError(
            StateError('Stream closed prematurely during handshake'),
          );
        }
      },
    );
    return _completer.future;
  }

  void _process() {
    if (_targetLength == null) {
      if (_buffer.length >= 4) {
        final lengthBytes = Uint8List.fromList(_buffer.sublist(0, 4));
        _targetLength = ByteData.sublistView(
          lengthBytes,
        ).getUint32(0, Endian.little);
        _buffer.removeRange(0, 4);
      }
    }
    if (_targetLength != null) {
      if (_buffer.length >= _targetLength!) {
        final payload = _buffer.sublist(0, _targetLength!);
        _subscription.cancel();
        try {
          final result = LocalHarnessProto.decodeOutputConfig(payload);
          _completer.complete(result);
        } catch (e) {
          _completer.completeError(e);
        }
      }
    }
  }
}

/// Live session connection to the local harness.
class LocalConnection implements Connection {
  final Process _process;
  final WebSocket _ws;
  final Stream<dynamic> _messageStream;
  final ToolRunner _toolRunner;
  final HookRunner _hookRunner;
  HookRouter? _hookRouter;
  final Map<String, _StepTracker> _stepTrackers = {};

  final StreamController<Step> _stepController =
      StreamController<Step>.broadcast();
  final List<String> _stderrLines = [];
  bool _disconnecting = false;
  bool _idleState = true;
  String _convId = '';

  /// The root/main agent trajectory ID.
  String? mainTrajectoryId;
  final List<Step> _initialHistory = [];
  UsageMetadata _cumulativeUsage = UsageMetadata();
  final Map<String, UsageMetadata> _trajectoryUsages = {};
  StopReason _turnStopReason = StopReason.unspecified;

  @override
  bool get isIdle => _idleState;

  @override
  String get conversationId => _convId;

  @override
  List<Step> get initialHistory => List.unmodifiable(_initialHistory);

  @override
  UsageMetadata get cumulativeUsage => _cumulativeUsage;

  @override
  Map<String, UsageMetadata> get trajectoryUsages =>
      Map.unmodifiable(_trajectoryUsages);

  @override
  StopReason get lastTurnStopReason => _turnStopReason;

  /// Creates a new [LocalConnection] session.
  ///
  /// Takes [process] (for managing the localharness process), [ws] (the WebSocket connection),
  /// [messageStream] to receive WebSocket events, [toolRunner] to process incoming tool executions,
  /// and [hookRunner] to dispatch lifecycle events.
  LocalConnection({
    required Process process,
    required WebSocket ws,
    required Stream<dynamic> messageStream,
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
    List<Step>? initialHistory,
    String? conversationId,
    this.mainTrajectoryId,
    UsageMetadata? cumulativeUsage,
    Map<String, UsageMetadata>? trajectoryUsages,
  })  : _process = process,
        _ws = ws,
        _messageStream = messageStream,
        _toolRunner = toolRunner,
        _hookRunner = hookRunner,
        _convId = conversationId ?? '' {
    if (initialHistory != null) {
      _initialHistory.addAll(initialHistory);
    }
    if (cumulativeUsage != null) {
      _cumulativeUsage = cumulativeUsage;
    }
    if (trajectoryUsages != null) {
      _trajectoryUsages.addAll(trajectoryUsages);
    }
    if (hookRunner.hasHooks) {
      _hookRouter = HookRouter(
        hookRunner,
        (evt) async {
          if (!_disconnecting) {
            _ws.add(jsonEncode(evt));
          }
        },
        resultExtractor: extractToolResult,
      );
    }
  }

  void _safeAdd(Step step) {
    if (_disconnecting || _stepController.isClosed) return;
    _stepController.add(step);
  }

  void _safeAddError(Object error) {
    if (_disconnecting || _stepController.isClosed) return;
    _stepController.addError(error);
  }

  void _startStderrReader() {
    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stderrLines.add(line);
      if (_stderrLines.length > 50) {
        _stderrLines.removeAt(0);
      }
      _logger.fine('[Harness Stderr] $line');
    }, cancelOnError: false);
  }

  /// Starts the reader loop. Exposed for unit testing.
  void startReaderLoop() => _startReaderLoop();

  void _startReaderLoop() {
    _messageStream.listen(
      (message) async {
        if (_disconnecting) return;
        try {
          if (message is String) {
            _logger.finest('<<< Received WebSocket message: $message');
            final Map<String, dynamic> event = jsonDecode(message);
            await _handleEvent(event);
          }
        } catch (e) {
          _logger.severe('Error in connection reader loop: $e');
          _safeAddError(
            AntigravityConnectionException(
              'Error in connection reader loop: $e',
            ),
          );
        }
      },
      onError: (err) {
        if (!_disconnecting) {
          final stderrTail = _stderrLines.join('\n');
          _logger.severe('WebSocket closed with error: $err');
          _safeAddError(
            AntigravityConnectionException(
              'WebSocket closed with error: $err.\nStderr tail:\n$stderrTail',
            ),
          );
        }
      },
      onDone: () {
        if (!_disconnecting) {
          final stderrTail = _stderrLines.join('\n');
          _logger.warning('WebSocket connection closed prematurely');
          _safeAddError(
            AntigravityConnectionException(
              'WebSocket connection closed prematurely.\nStderr tail:\n$stderrTail',
            ),
          );
        }
      },
      cancelOnError: true,
    );
  }

  Future<void> _handleEvent(Map<String, dynamic> event) async {
    if (_disconnecting) return;
    final normalizedEvent = _normalizeJsonKeys(event);

    if (normalizedEvent.containsKey('call_hook_request')) {
      _handleCallHookRequest(normalizedEvent['call_hook_request']);
      return;
    }

    if (normalizedEvent.containsKey('usage_update')) {
      _handleUsageUpdate(normalizedEvent['usage_update']);
      return;
    }

    if (normalizedEvent.containsKey('step_update')) {
      await _handleStepUpdate(normalizedEvent['step_update']);
      return;
    }

    if (normalizedEvent.containsKey('trajectory_state_update')) {
      _handleTrajectoryStateUpdate(normalizedEvent['trajectory_state_update']);
      return;
    }

    if (normalizedEvent.containsKey('tool_call')) {
      final tc = ToolCall.fromMap(Map<String, dynamic>.from(normalizedEvent['tool_call'] as Map));
      _logger.info('Tool call requested: ${tc.name}');
      await _handleToolCall(tc);
    }
  }

  void _handleCallHookRequest(dynamic rawReq) {
    if (rawReq is! Map) return;
    final req = Map<String, dynamic>.from(rawReq);
    if (_hookRouter != null) {
      unawaited(_hookRouter!.handle(req));
    } else {
      final requestId = req['request_id']?.toString() ?? '';
      _ws.add(jsonEncode({
        'call_hook_response': {
          'request_id': requestId,
          'empty_result': {},
        }
      }));
    }
  }

  void _handleUsageUpdate(dynamic rawUpdate) {
    if (rawUpdate is! Map) return;
    final usageUpdate = Map<String, dynamic>.from(rawUpdate);
    if (usageUpdate['total'] is Map) {
      _cumulativeUsage = UsageMetadata.fromMap(Map<String, dynamic>.from(usageUpdate['total'] as Map));
    }
    if (usageUpdate['agents'] is List) {
      _parseTrajectoryUsages(usageUpdate['agents'] as List);
    }
  }

  Future<void> _handleStepUpdate(dynamic rawStepJson) async {
    if (rawStepJson is! Map) return;
    final stepJson = Map<String, dynamic>.from(rawStepJson);
    final step = Step.fromMap(stepJson);

    final stepTrajectoryId = stepJson['trajectory_id']?.toString() ?? step.trajectoryId;
    if (mainTrajectoryId == null && stepTrajectoryId.isNotEmpty) {
      mainTrajectoryId = stepTrajectoryId;
    }

    if (_convId.isEmpty && step.cascadeId.isNotEmpty) {
      _convId = step.cascadeId;
    }

    final stepForQueue = _filterHostHandledToolCalls(step);
    _safeAdd(stepForQueue);

    if (step.type == StepType.compaction) {
      final turnCtx = _hookRouter?.currentTurnContext ?? _hookRunner.currentTurnContext;
      unawaited(_hookRunner.dispatchCompaction(turnCtx, step));
    }

    _trackStepTransitions(stepJson, step);

    if (step.status == StepStatus.waitingForUser) {
      if (stepJson.containsKey('questions_request')) {
        await _handleQuestionRequest(stepJson);
      }
      if (stepJson.containsKey('tool_confirmation_request')) {
        await _handleToolConfirmationRequest(stepJson);
      }
    }
  }

  Step _filterHostHandledToolCalls(Step step) {
    if (step.toolCalls.isEmpty) return step;
    final registeredTools = _toolRunner.tools;
    final filteredCalls = step.toolCalls
        .where((tc) => !registeredTools.containsKey(tc.name))
        .toList();
    return filteredCalls.length != step.toolCalls.length
        ? step.copyWith(toolCalls: filteredCalls)
        : step;
  }

  void _trackStepTransitions(Map<String, dynamic> stepJson, Step step) {
    final trajectoryId = stepJson['trajectory_id']?.toString() ?? '';
    final stepIndex = int.tryParse((stepJson['step_index'] ?? '0').toString()) ?? 0;
    final stepKey = '$trajectoryId:$stepIndex';
    final tracker = _stepTrackers.putIfAbsent(stepKey, () => _StepTracker());
    final stateStr = (stepJson['state'] ?? 'STATE_UNSPECIFIED').toString();
    tracker.updateState(stateStr);

    if (!tracker.preStepDispatched && stateStr != 'STATE_UNSPECIFIED') {
      tracker.preStepDispatched = true;
      unawaited(_hookRunner.dispatchPreStep(step));
    }

    final isTerminal = stateStr == 'STATE_DONE' ||
        stateStr == 'DONE' ||
        stateStr == 'STATE_ERROR' ||
        stateStr == 'ERROR';
    if (isTerminal && !tracker.postStepDispatched) {
      tracker.postStepDispatched = true;
      unawaited(_hookRunner.dispatchPostStep(step));
    }
  }

  void _handleTrajectoryStateUpdate(dynamic rawUpdate) {
    if (rawUpdate is! Map) return;
    final update = Map<String, dynamic>.from(rawUpdate);
    final state = update['state']?.toString();
    final trajectoryId = update['trajectory_id']?.toString() ?? '';
    if (mainTrajectoryId == null && trajectoryId.isNotEmpty) {
      mainTrajectoryId = trajectoryId;
    }
    final isSubagent = mainTrajectoryId != null &&
        trajectoryId.isNotEmpty &&
        trajectoryId != mainTrajectoryId;

    if (update['stop_reason'] != null && update['stop_reason'].toString().isNotEmpty) {
      _turnStopReason = StopReason.fromString(update['stop_reason'].toString());
    }

    if (isSubagent) {
      if (update['error'] != null && update['error'].toString().isNotEmpty) {
        _logger.info('Subagent trajectory failed with error: ${update['error']}');
      }
      return;
    }

    _applyTrajectoryState(state, update['error']?.toString());
    _logger.fine('Trajectory state updated: $state for $trajectoryId');
  }

  void _applyTrajectoryState(String? state, String? error) {
    if (state == 'STATE_RUNNING' || state == 'RUNNING') {
      _idleState = false;
      return;
    }
    if (state == 'STATE_FULLY_IDLE' ||
        state == 'FULLY_IDLE' ||
        state == 'STATE_IDLE' ||
        state == 'IDLE') {
      if (error != null && error.isNotEmpty) {
        _safeAddError(AntigravityExecutionException(error));
      }
      _idleState = true;
      _safeAdd(_createIdleSentinelStep());
      return;
    }
    if (state == 'STATE_CANCELLED' || state == 'CANCELLED') {
      final errMsg = (error != null && error.isNotEmpty) ? error : 'Turn cancelled';
      _safeAddError(AntigravityExecutionException(errMsg));
      _idleState = true;
      _safeAdd(_createIdleSentinelStep());
    }
  }

  static Step _createIdleSentinelStep() {
    return Step(
      id: 'idle_sentinel',
      stepIndex: -1,
      type: StepType.finish,
      source: StepSource.system,
      target: StepTarget.environment,
      status: StepStatus.done,
    );
  }

  void _parseTrajectoryUsages(List trajList) {
    for (final entry in trajList) {
      if (entry is Map) {
        final entryMap = Map<String, dynamic>.from(entry);
        final trajId = entryMap['trajectory_id']?.toString() ?? '';
        if (trajId.isNotEmpty &&
            entryMap.containsKey('usage') &&
            entryMap['usage'] is Map) {
          _trajectoryUsages[trajId] = UsageMetadata.fromMap(
            Map<String, dynamic>.from(entryMap['usage'] as Map),
          );
        }
      }
    }
  }

  Future<void> _handleQuestionRequest(Map<String, dynamic> stepJson) async {
    // Porting human interaction hook flow if needed
    // In L3, we can bypass or send a mock/cancelled/empty answer to avoid deadlock
    // We send an empty answers array if no hooks handle it
    final List<Map<String, dynamic>> answers = [];
    final questions = stepJson['questions_request']['questions'] as List;
    for (var i = 0; i < questions.length; i++) {
      answers.add({'unanswered': true});
    }

    final responseEvent = {
      'question_response': {
        'trajectory_id': stepJson['trajectory_id'],
        'step_index': stepJson['step_index'],
        'response': {'answers': answers},
      },
    };
    _logger.fine('>>> Sending empty question response');
    _ws.add(jsonEncode(responseEvent));
  }

  Future<void> _handleToolConfirmationRequest(
    Map<String, dynamic> stepJson,
  ) async {
    // Send immediate accepted confirmation
    final responseEvent = {
      'tool_confirmation': {
        'trajectory_id': stepJson['trajectory_id'],
        'step_index': stepJson['step_index'],
        'accepted': true,
      },
    };
    _logger.fine('>>> Auto-confirming tool execution');
    _ws.add(jsonEncode(responseEvent));
  }

  Future<void> _handleToolCall(ToolCall toolCall) async {
    try {
      final step = Step(
        id: toolCall.id ?? '',
        stepIndex: 1,
        type: StepType.toolCall,
        source: StepSource.model,
        target: StepTarget.environment,
        status: StepStatus.active,
        content: '',
        contentDelta: '',
        thinking: '',
        thinkingDelta: '',
        toolCalls: [toolCall],
        error: '',
      );
      _safeAdd(step);

      // Pre-tool-call check policy
      bool allowed = true;
      final ctx = _hookRunner.createTurnContext();
      final res = await _hookRunner.dispatchPreToolCall(ctx, toolCall);
      allowed = res.allow;
      if (!allowed) {
        final errReason = res.message.isNotEmpty
            ? res.message
            : 'Tool execution denied by policy';
        _logger.warning('Tool execution denied: $errReason');
        await sendToolResults([
          ToolResult(
            id: toolCall.id,
            callId: toolCall.callId,
            stepId: toolCall.stepId,
            name: toolCall.name,
            error: errReason,
          ),
        ]);
        return;
      }

      var effectiveToolCall = toolCall;
      if (res.modifiedArgs != null) {
        final mergedArgs = Map<String, dynamic>.from(effectiveToolCall.args);
        mergedArgs.addAll(res.modifiedArgs!);
        effectiveToolCall = ToolCall(
          name: effectiveToolCall.name,
          args: mergedArgs,
          id: effectiveToolCall.id,
          callId: effectiveToolCall.callId,
          stepId: effectiveToolCall.stepId,
          canonicalPath: effectiveToolCall.canonicalPath,
          serverName: effectiveToolCall.serverName,
        );
      }

      ToolResult result;
      try {
        final results = await _toolRunner.processToolCalls([effectiveToolCall]);
        result = results[0];
      } catch (e) {
        result = ToolResult(
          id: effectiveToolCall.id,
          callId: effectiveToolCall.callId,
          stepId: effectiveToolCall.stepId,
          name: effectiveToolCall.name,
          error: e.toString(),
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }

      // Post-tool-call hook or error hook execution
      if (result.error == null) {
        final ctx = _hookRunner.createTurnContext();
        await _hookRunner.dispatchPostToolCall(ctx, result);
      } else {
        final ctx = _hookRunner.createTurnContext();
        final exception = result.exception ?? Exception(result.error);
        final recoveryVal =
            await _hookRunner.dispatchOnToolError(ctx, exception);
        if (recoveryVal != null) {
          result = ToolResult(
            id: toolCall.id,
            name: toolCall.name,
            result: recoveryVal,
          );
        }
      }

      await sendToolResults([result]);
    } catch (e) {
      _logger.severe('Internal SDK tool call processing error: $e');
      await sendToolResults([
        ToolResult(
          id: toolCall.id,
          name: toolCall.name,
          error: 'Internal SDK tool call processing error: $e',
        ),
      ]);
    }
  }

  static final _controlCharRegExp =
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]');

  /// Strips null bytes and dangerous control characters from user text prompts at the wire boundary.
  ///
  /// Empty strings return `''`. If a non-empty input is stripped down to whitespace/control characters only,
  /// it collapses to a single space `' '` to avoid triggering HTTP 400 empty-payload errors on the backend wire ingress.
  static String _sanitizePrompt(String text) {
    if (text.isEmpty) return '';
    final sanitized = text.replaceAll(_controlCharRegExp, ' ');
    if (sanitized.trim().isEmpty) return ' ';
    return sanitized;
  }

  /// Exposed for testing.
  static String sanitizePromptForTest(String text) => _sanitizePrompt(text);

  @override
  Future<void> send(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    _idleState = false;
    final List<Map<String, dynamic>> parts = [];

    if (prompt is String) {
      parts.add({'text': _sanitizePrompt(prompt)});
    } else if (prompt is SlashCommand) {
      parts.add({
        'slash_command': {'name': prompt.name.value},
      });
    } else if (prompt is MediaContent) {
      parts.add({
        'media': {
          'mime_type': prompt.mimeType,
          'description': prompt.description,
          'data': base64Encode(prompt.data),
        },
      });
    } else if (prompt is List) {
      for (final p in prompt) {
        if (p is String) {
          parts.add({'text': _sanitizePrompt(p)});
        } else if (p is SlashCommand) {
          parts.add({
            'slash_command': {'name': p.name.value},
          });
        } else if (p is MediaContent) {
          parts.add({
            'media': {
              'mime_type': p.mimeType,
              'description': p.description,
              'data': base64Encode(p.data),
            },
          });
        }
      }
    }

    final inputEvent = {
      'user_input': {'parts': parts},
    };

    _logger.finest('>>> Sending user_input over WebSocket');
    _ws.add(jsonEncode(inputEvent));
  }

  @override
  Stream<Step> receiveSteps() {
    return _stepController.stream;
  }

  @override
  Future<void> sendToolResults(List<ToolResult> results) async {
    for (final result in results) {
      dynamic responseJson;
      List<Map<String, dynamic>>? supplementalMedia;

      if (result.error != null) {
        responseJson = {'error': result.error};
      } else {
        final extracted = extractMediaFromResult(result.result);
        var cleanedValue = extracted.cleanedValue;
        if (extracted.media.isNotEmpty && cleanedValue == null) {
          cleanedValue =
              'Returned ${extracted.media.length} media attachment(s).';
        }
        responseJson = {'result': cleanedValue};
        if (extracted.media.isNotEmpty) {
          supplementalMedia = extracted.media.map((item) {
            return {
              'mime_type': item.mimeType,
              'data': base64Encode(item.data),
              'description': item.description,
            };
          }).toList();
        }
      }

      final response = {
        'tool_response': {
          'id': result.id ?? '',
          'response_json': jsonEncode(responseJson),
          if (supplementalMedia != null)
            'supplemental_media': supplementalMedia,
        },
      };

      _logger.fine('>>> Sending tool_response for ${result.name}');
      _ws.add(jsonEncode(response));
    }
  }

  @override
  Future<void> sendTriggerNotification(String content) async {
    final event = {'automated_trigger': content};
    _logger.fine('>>> Sending automated_trigger');
    _ws.add(jsonEncode(event));
  }

  @override
  Future<void> disconnect() async {
    _disconnecting = true;
    _logger.info('Disconnecting from localharness');
    try {
      await _ws.close(status.goingAway);
    } catch (_) {}
    _process.kill();
    await _stepController.close();
  }

  @override
  Future<void> cancel() async {
    final event = {'halt_request': true};
    _logger.info('>>> Sending halt_request');
    _ws.add(jsonEncode(event));
  }

  @override
  Future<void> delete() async {
    // Optional implementation for session cleanup
  }

  @override
  void signalIdle() {
    _idleState = true;
  }

  @override
  Future<void> waitForIdle() async {
    while (!_idleState) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  Future<bool> waitForWakeup({double timeout = 300.0}) async {
    final sw = Stopwatch()..start();
    while (_idleState) {
      if (sw.elapsedMilliseconds > timeout * 1000) return false;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    return true;
  }

  static Map<String, dynamic> _normalizeJsonKeys(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, val) {
      final snakeKey = _toSnakeCase(key);
      if (val is Map<String, dynamic>) {
        result[snakeKey] = _normalizeJsonKeys(val);
      } else if (val is Map) {
        result[snakeKey] = _normalizeJsonKeys(Map<String, dynamic>.from(val));
      } else if (val is List) {
        result[snakeKey] = val.map((item) {
          if (item is Map<String, dynamic>) {
            return _normalizeJsonKeys(item);
          } else if (item is Map) {
            return _normalizeJsonKeys(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[snakeKey] = val;
      }
    });
    return result;
  }

  static String _toSnakeCase(String camel) {
    final exp = RegExp('(?<=[a-z0-9])[A-Z]');
    return camel.replaceAllMapped(exp, (m) => '_${m.group(0)}').toLowerCase();
  }
}

class _StepTracker {
  String state = 'STATE_UNSPECIFIED';
  final Set<String> handledRequests = {};
  bool preStepDispatched = false;
  bool postStepDispatched = false;

  void updateState(String newState) {
    if (state == 'STATE_WAITING_FOR_USER' &&
        newState != 'STATE_WAITING_FOR_USER') {
      handledRequests.clear();
    }
    state = newState;
  }
}

dynamic extractToolResult(Map<String, dynamic> stepUpdate) {
  if (stepUpdate.containsKey('run_command')) {
    return _extractRunCommandResult(stepUpdate['run_command']);
  }
  if (stepUpdate.containsKey('list_directory')) {
    return _extractListDirectoryResult(stepUpdate['list_directory']);
  }
  if (stepUpdate.containsKey('find_file')) {
    return _extractFindFileResult(stepUpdate['find_file']);
  }
  if (stepUpdate.containsKey('search_directory')) {
    return _extractSearchDirectoryResult(stepUpdate['search_directory']);
  }
  if (stepUpdate.containsKey('edit_file')) {
    return _extractEditFileResult(stepUpdate['edit_file'], stepUpdate['text']);
  }
  if (stepUpdate.containsKey('generate_image') && stepUpdate['generate_image'] is Map) {
    return GenerateImageResult.fromMap(Map<String, dynamic>.from(stepUpdate['generate_image'] as Map));
  }
  if (stepUpdate.containsKey('search_web') && stepUpdate['search_web'] is Map) {
    return SearchWebResult.fromMap(Map<String, dynamic>.from(stepUpdate['search_web'] as Map));
  }
  if (stepUpdate.containsKey('read_url_content') && stepUpdate['read_url_content'] is Map) {
    return ReadUrlContentResult.fromMap(Map<String, dynamic>.from(stepUpdate['read_url_content'] as Map));
  }
  return null;
}

RunCommandResult? _extractRunCommandResult(dynamic rc) {
  return (rc is Map && rc.containsKey('combined_output'))
      ? RunCommandResult(output: rc['combined_output'].toString())
      : null;
}

ListDirectoryResult? _extractListDirectoryResult(dynamic ld) {
  if (ld is! Map || ld['results'] is! List) return null;
  final results = ld['results'] as List;
  final entries = results.map((r) {
    if (r is Map) {
      return ListDirectoryEntry(
        name: (r['name'] ?? '').toString(),
        isDirectory: r['is_directory'] == true || r['isDirectory'] == true,
        fileSize: int.tryParse((r['file_size'] ?? r['fileSize'] ?? '0').toString()) ?? 0,
      );
    }
    return const ListDirectoryEntry();
  }).toList();
  return ListDirectoryResult(entries: entries);
}

FindFileResult? _extractFindFileResult(dynamic ff) {
  return (ff is Map && ff.containsKey('output'))
      ? FindFileResult(output: ff['output'].toString())
      : null;
}

SearchDirectoryResult? _extractSearchDirectoryResult(dynamic sd) {
  return (sd is Map && sd.containsKey('num_results'))
      ? SearchDirectoryResult(
          numResults: int.tryParse((sd['num_results'] ?? sd['numResults'] ?? '0').toString()) ?? 0,
        )
      : null;
}

EditFileResult? _extractEditFileResult(dynamic ef, dynamic text) {
  return (ef is Map && ef.containsKey('diff_block'))
      ? EditFileResult(summary: (text ?? '').toString())
      : null;
}

class ExtractedMedia {
  final dynamic cleanedValue;
  final List<MediaContent> media;
  ExtractedMedia(this.cleanedValue, this.media);
}

ExtractedMedia extractMediaFromResult(dynamic value) {
  if (value is MediaContent) {
    return ExtractedMedia(null, [value]);
  }
  if (value is List) {
    return _extractMediaFromList(value);
  }
  if (value is Map) {
    return _extractMediaFromMap(value);
  }
  return ExtractedMedia(value, const []);
}

ExtractedMedia _extractMediaFromList(List value) {
  final cleanedList = [];
  final listMedia = <MediaContent>[];
  for (final item in value) {
    final res = extractMediaFromResult(item);
    listMedia.addAll(res.media);
    if (res.cleanedValue != null) {
      cleanedList.add(res.cleanedValue);
    }
  }
  return ExtractedMedia(cleanedList.isEmpty ? null : cleanedList, listMedia);
}

ExtractedMedia _extractMediaFromMap(Map value) {
  final cleanedMap = <dynamic, dynamic>{};
  final mapMedia = <MediaContent>[];
  for (final entry in value.entries) {
    final res = extractMediaFromResult(entry.value);
    mapMedia.addAll(res.media);
    if (res.cleanedValue != null) {
      cleanedMap[entry.key] = res.cleanedValue;
    }
  }
  return ExtractedMedia(cleanedMap.isEmpty ? null : cleanedMap, mapMedia);
}

/// Strategy for establishing connection to an external local OpenAI completions API (Ollama/LM Studio).
class LocalOpenAIConnectionStrategy extends LocalConnectionStrategy {
  String baseUrl;
  final String modelName;

  LocalOpenAIConnectionStrategy({
    required this.baseUrl,
    required this.modelName,
    super.binaryPath,
    required super.toolRunner,
    required super.hookRunner,
    super.systemInstructions,
    required super.capabilitiesConfig,
    super.conversationId,
    super.sessionContinuationMode,
    super.saveDir,
    required super.workspaces,
    super.appDataDir,
    required super.skillsPaths,
    super.mcpServers,
    super.subagents,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
  });

  @override
  void _validateConnection() {
    if (baseUrl.isEmpty) {
      throw AntigravityValidationException(
        "LocalOpenAIConnectionStrategy requires a non-empty 'baseUrl'.",
      );
    }
  }

  @override
  Map<String, dynamic> _buildHarnessConfig() {
    final harnessConfig = super._buildHarnessConfig();
    final modelCfg = {
      'name': modelName,
      'types': ['MODEL_TYPE_TEXT'],
      'gemma_endpoint': {
        'base_url': baseUrl,
      },
    };
    final models = List<dynamic>.from(harnessConfig['models'] as List? ?? []);
    models.add(modelCfg);
    harnessConfig['models'] = models;
    return harnessConfig;
  }
}

/// Strategy for establishing connection to a local LiteRT loopback API server.
class LiteRTConnectionStrategy extends LocalOpenAIConnectionStrategy {
  final String modelPath;
  final LiteRTBackend backend;
  final bool enableSpeculativeDecoding;
  final String? cacheDir;
  final LiteRTBackend? audioBackend;
  final LiteRTBackend? visionBackend;
  final int port;
  final bool downloadIfMissing;
  final int? maxContextTokens;
  Process? _serverProcess;

  LiteRTConnectionStrategy({
    required this.modelPath,
    this.backend = LiteRTBackend.gpu,
    this.enableSpeculativeDecoding = false,
    this.cacheDir,
    this.audioBackend,
    this.visionBackend,
    this.port = 0,
    this.downloadIfMissing = false,
    this.maxContextTokens,
    super.binaryPath,
    required super.toolRunner,
    required super.hookRunner,
    super.systemInstructions,
    required super.capabilitiesConfig,
    super.conversationId,
    super.sessionContinuationMode,
    super.saveDir,
    required super.workspaces,
    super.appDataDir,
    required super.skillsPaths,
    super.mcpServers,
    super.subagents,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
  }) : super(
          baseUrl: '',
          modelName: p.basename(modelPath),
        );

  @override
  void _validateConnection() {
    if (!File(modelPath).existsSync()) {
      throw AntigravityValidationException(
        "LiteRT model path does not exist: $modelPath",
      );
    }
  }

  @override
  Future<void> start() async {
    _validateConnection();

    final scriptFile = _writeLiteRTServerScript();
    _serverProcess = await _launchLiteRTServer(scriptFile);

    final actualPort = await _readLiteRTPort(_serverProcess!);
    final litertBaseUrl = 'http://127.0.0.1:$actualPort';
    _logger.info('LiteRT Server started on port $actualPort. URL: $litertBaseUrl');

    final client = HttpClient();
    try {
      await _waitForLiteRTHealth(client, litertBaseUrl);
      await _warmupLiteRT(client, litertBaseUrl);
    } finally {
      client.close();
    }

    baseUrl = litertBaseUrl;
    await super.start();
  }

  File _writeLiteRTServerScript() {
    final dir = Directory(_appDataDir ?? defaultAppDataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final scriptFile = File('${dir.path}${Platform.pathSeparator}litert_server.py');
    scriptFile.writeAsStringSync(litertServerPythonScript);
    return scriptFile;
  }

  Future<Process> _launchLiteRTServer(File scriptFile) async {
    final args = [
      scriptFile.path,
      '--model_path',
      modelPath,
      '--backend',
      backend.name,
      if (enableSpeculativeDecoding) '--enable_speculative_decoding',
      if (cacheDir != null) ...['--cache_dir', cacheDir!],
      if (audioBackend != null) ...['--audio_backend', audioBackend!.name],
      if (visionBackend != null) ...['--vision_backend', visionBackend!.name],
      '--port',
      port.toString(),
      if (maxContextTokens != null) ...['--max_context_tokens', maxContextTokens!.toString()],
    ];

    _logger.info('Starting LiteRT OpenAI server: python3 ${args.join(' ')}');
    return Process.start('python3', args);
  }

  Future<int> _readLiteRTPort(Process process) async {
    final portCompleter = Completer<int>();
    final portRegex = RegExp(r'^LITERT_SERVER_PORT:(\d+)$');

    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      _logger.fine('[LiteRT Server Stdout] $line');
      final match = portRegex.firstMatch(line);
      if (match != null && !portCompleter.isCompleted) {
        portCompleter.complete(int.parse(match.group(1)!));
      }
    });

    process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      _logger.warning('[LiteRT Server Stderr] $line');
    });

    try {
      return await portCompleter.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      process.kill();
      throw Exception('Failed to receive port from LiteRT server process. Error: $e');
    }
  }

  Future<void> _waitForLiteRTHealth(HttpClient client, String litertBaseUrl) async {
    for (var i = 0; i < 60; i++) {
      try {
        final request = await client.getUrl(Uri.parse('$litertBaseUrl/v1/models'));
        final response = await request.close();
        if (response.statusCode == 200) return;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _serverProcess?.kill();
    throw Exception('LiteRT loopback HTTP endpoint failed to respond.');
  }

  Future<void> _warmupLiteRT(HttpClient client, String litertBaseUrl) async {
    try {
      var warmupTimeoutSeconds = 120.0;
      if (maxContextTokens != null && maxContextTokens! > 0) {
        final scaled = maxContextTokens! / 250.0;
        if (scaled > warmupTimeoutSeconds) {
          warmupTimeoutSeconds = scaled;
        }
      }
      final request = await client.postUrl(Uri.parse('$litertBaseUrl/v1/chat/completions'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': 'Hello'}
        ],
        'stream': false,
      }));
      final response = await request.close().timeout(Duration(milliseconds: (warmupTimeoutSeconds * 1000).round()));
      await response.drain();
    } catch (e) {
      _logger.warning('LiteRT warm-up request timed out or failed: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await super.stop();
    } finally {
      _logger.info('Stopping LiteRT server process...');
      _serverProcess?.kill();
      _serverProcess = null;
    }
  }
}
