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
import '../connection.dart';
import 'hook_router.dart';
import 'litert_server_python.dart';
import 'local_connection_config.dart';
import 'localharness_proto.dart';

final _logger = Logger('antigravity.connection.local');

/// Strategy for establishing a LocalConnection to a Go-based localharness binary.
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
        _retryConfig = retryConfig;

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
    // 1. Validate all model endpoints
    _validateConnection();

    // 2. Discover the binary path dynamically
    final resolvedBinaryPath = await BinaryDiscovery.discover(
      configPath: _configuredBinaryPath,
    );

    _logger.info('Starting localharness binary at: $resolvedBinaryPath');

    // 3. Start the process
    _process = await Process.start(resolvedBinaryPath, []);

    // 4. Send standard input handshake payload
    final inputConfigBytes = LocalHarnessProto.encodeInputConfig(
      storageDirectory: _saveDir ?? '',
      clientLanguage: 'dart',
      clientVersion: '0.6.0',
      clientLanguageVersion: Platform.version,
    );
    final packedMessage = LocalHarnessProto.packMessage(inputConfigBytes);
    _process!.stdin.add(packedMessage);
    await _process!.stdin.flush();

    // 5. Read output config from stdout using our stateful HandshakeReader
    late LocalHarnessProto outputConfig;
    try {
      final reader = HandshakeReader();
      outputConfig = await reader.read(_process!.stdout);
    } catch (e) {
      _process!.kill();
      // Read stderr to see if it crashed
      final stderrText = await _process!.stderr.transform(utf8.decoder).join();
      _logger.severe(
        'Failed to handshake with localharness. Stderr: $stderrText',
      );
      throw Exception(
        'Failed to handshake with localharness process. Stderr: $stderrText. Error: $e',
      );
    }

    // 6. Connect to local WebSocket server with retry backoff (trying both localhost and 127.0.0.1)
    WebSocket? ws;
    String? connectedWsUrl;
    int attempt = 0;
    const maxRetries = 5;
    Object? lastException;
    while (attempt < maxRetries) {
      for (final host in ['localhost', '127.0.0.1']) {
        final url = 'ws://$host:${outputConfig.port}/';
        try {
          ws = await WebSocket.connect(
            url,
            headers: {'x-goog-api-key': outputConfig.apiKey},
          );
          connectedWsUrl = url;
          break;
        } catch (e) {
          lastException = e;
        }
      }
      if (ws != null) {
        break;
      }
      attempt++;
      if (attempt >= maxRetries) {
        _process!.kill();
        final stderrText =
            await _process!.stderr.transform(utf8.decoder).join();
        throw Exception(
          'Failed to connect to WebSocket after $maxRetries attempts. Last error: $lastException. Stderr: $stderrText',
        );
      }
      final delay = Duration(milliseconds: 100 * (1 << attempt));
      _logger.warning(
        'WebSocket connection failed. Retrying in ${delay.inMilliseconds}ms...',
      );
      await Future.delayed(delay);
    }

    _ws = ws;
    _logger.fine(
        'Handshake successful. Connected to WebSocket at $connectedWsUrl');

    try {
      final initCompleter = Completer<List<Step>>();
      final messageController = StreamController<dynamic>();

      // Listen to the WebSocket immediately to capture the first handshake message.
      ws!.listen(
        (message) {
          if (!initCompleter.isCompleted) {
            try {
              if (message is String) {
                final Map<String, dynamic> parsed = jsonDecode(message);
                final normalized = LocalConnection._normalizeJsonKeys(parsed);
                if (normalized
                    .containsKey('initialize_conversation_response')) {
                  final initResp = Map<String, dynamic>.from(
                    normalized['initialize_conversation_response'] as Map,
                  );
                  final List<Step> initialHistory = [];
                  if (initResp.containsKey('history')) {
                    final historyList = initResp['history'] as List;
                    for (final stepJson in historyList) {
                      initialHistory.add(
                        Step.fromMap(
                            Map<String, dynamic>.from(stepJson as Map)),
                      );
                    }
                  }
                  if (initResp.containsKey('cumulative_usage') &&
                      initResp['cumulative_usage'] is Map) {
                    _connection?._cumulativeUsage = UsageMetadata.fromMap(
                      Map<String, dynamic>.from(
                        initResp['cumulative_usage'] as Map,
                      ),
                    );
                  }
                  if (initResp.containsKey('trajectory_usage') &&
                      initResp['trajectory_usage'] is List) {
                    _connection?._parseTrajectoryUsages(
                      initResp['trajectory_usage'] as List,
                    );
                  }
                  initCompleter.complete(initialHistory);
                  return; // Discard from forwarding as it's the startup handshake response.
                }
              }
            } catch (e) {
              initCompleter.completeError(e);
            }
            if (!initCompleter.isCompleted) {
              initCompleter.complete([]);
            }
          }
          messageController.add(message);
        },
        onError: (err) {
          if (!initCompleter.isCompleted) {
            initCompleter.completeError(err);
          }
          messageController.addError(err);
        },
        onDone: () {
          if (!initCompleter.isCompleted) {
            initCompleter.complete([]);
          }
          messageController.close();
        },
      );

      // 7. Send InitializeConversationEvent JSON over WebSocket
      final harnessConfig = _buildHarnessConfig();
      final initEvent = {'config': harnessConfig};
      _ws!.add(jsonEncode(initEvent));

      // Wait for the initialization response to resolve.
      final List<Step> initialHistory = await initCompleter.future;

      _connection = LocalConnection(
        process: _process!,
        ws: _ws!,
        messageStream: messageController.stream,
        toolRunner: _toolRunner,
        hookRunner: _hookRunner,
        initialHistory: initialHistory,
      );
    } catch (e) {
      _process!.kill();
      final stderrText = await _process!.stderr.transform(utf8.decoder).join();
      _logger.severe(
        'Failed to initialize conversation with localharness. Stderr: $stderrText',
      );
      throw Exception(
        'Failed to initialize conversation with localharness process. Stderr: $stderrText. Error: $e',
      );
    }
    _connection!._startStderrReader();
    _connection!._startReaderLoop();
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
    // Generate tool schemas from dynamic functions registered in L2
    final List<Map<String, dynamic>> toolsProtos = [];
    for (final name in _toolRunner.tools.keys) {
      final toolFn = _toolRunner.tools[name]!;
      toolsProtos.add({
        'name': toolFn.name,
        'description': toolFn.description,
        'parameters_json_schema': jsonEncode(toolFn.schema),
      });
    }

    Map<String, dynamic>? systemInstructionsProto;
    if (_systemInstructions != null) {
      if (_systemInstructions is String) {
        systemInstructionsProto = {
          'appended': {
            'appended_sections': [
              {'title': 'System', 'content': _systemInstructions},
            ],
          },
        };
      } else if (_systemInstructions is CustomSystemInstructions) {
        final c = _systemInstructions as CustomSystemInstructions;
        systemInstructionsProto = {
          'custom': {
            'part': [
              {'text': c.text},
            ],
          },
        };
      } else {
        systemInstructionsProto = _systemInstructions.toMap();
      }
    }

    final modelsProtos = <Map<String, dynamic>>[];
    if (_models != null) {
      for (final model in _models!) {
        final protoMap = <String, dynamic>{};
        if (model.name != null) {
          protoMap['name'] = model.name;
        }
        if (model.types.isNotEmpty) {
          protoMap['types'] = model.types
              .map((t) => 'MODEL_TYPE_${t.value.toUpperCase()}')
              .toList();
        }
        if (model.endpoint != null) {
          if (model.endpoint is GeminiAPIEndpoint) {
            final ep = model.endpoint as GeminiAPIEndpoint;
            final opts = _buildModelOptionsMap(ep.options);
            protoMap['gemini_api_endpoint'] = {
              if (ep.baseUrl != null) 'base_url': ep.baseUrl,
              if (ep.httpHeaders != null) 'http_headers': ep.httpHeaders,
              if (ep.apiKey != null) 'api_key': ep.apiKey,
              if (opts != null) 'options': opts,
            };
          } else if (model.endpoint is VertexEndpoint) {
            final ep = model.endpoint as VertexEndpoint;
            final opts = _buildModelOptionsMap(ep.options);
            protoMap['vertex_endpoint'] = {
              if (ep.baseUrl != null) 'base_url': ep.baseUrl,
              if (ep.httpHeaders != null) 'http_headers': ep.httpHeaders,
              if (ep.project != null) 'project': ep.project,
              if (ep.location != null) 'location': ep.location,
              if (opts != null) 'options': opts,
            };
          }
        }
        modelsProtos.add(protoMap);
      }
    }

    final workspacesProto = _workspaces
        .map(
          (ws) => {
            'filesystem_workspace': {'directory': ws},
          },
        )
        .toList();

    final cfg = _capabilitiesConfig;

    // Determine enabled tools allowlist
    final allTools = BuiltinTools.values.toSet();
    Set<BuiltinTools> activeTools;
    if (cfg.enabledTools != null) {
      activeTools = cfg.enabledTools!.toSet();
    } else if (cfg.disabledTools != null) {
      activeTools = allTools.difference(cfg.disabledTools!.toSet());
    } else {
      activeTools = allTools;
    }

    final subagentsEnabled =
        cfg.enableSubagents && activeTools.contains(BuiltinTools.startSubagent);

    final harnessSideTools = {
      'subagents': {'enabled': subagentsEnabled},
      'find': {'enabled': activeTools.contains(BuiltinTools.findFile)},
      'user_questions': {
        'enabled': activeTools.contains(BuiltinTools.askQuestion),
      },
      'run_command': {'enabled': activeTools.contains(BuiltinTools.runCommand)},
      'file_edit': {'enabled': activeTools.contains(BuiltinTools.editFile)},
      'view_file': {'enabled': activeTools.contains(BuiltinTools.viewFile)},
      'write_to_file': {
        'enabled': activeTools.contains(BuiltinTools.createFile),
      },
      'grep_search': {
        'enabled': activeTools.contains(BuiltinTools.searchDirectory),
      },
      'list_dir': {'enabled': activeTools.contains(BuiltinTools.listDirectory)},
      'generate_image': {
        'enabled': activeTools.contains(BuiltinTools.generateImage),
      },
      'search_web': {'enabled': activeTools.contains(BuiltinTools.searchWeb)},
      'read_url_content': {
        'enabled': activeTools.contains(BuiltinTools.readUrlContent),
      },
    };

    final List<Map<String, dynamic>> mcpServersProto = [];
    for (final s in _mcpServers) {
      final Map<String, dynamic> item = {
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
      mcpServersProto.add(item);
    }

    final enabledHooks = <String>[];
    if (_hookRunner.onSessionStartHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_ON_SESSION_START');
    }
    if (_hookRunner.onSessionEndHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_ON_SESSION_END');
    }
    if (_hookRunner.preTurnHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_PRE_TURN');
    }
    if (_hookRunner.postTurnHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_POST_TURN');
    }
    if (_hookRunner.preToolCallDecideHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_PRE_TOOL');
    }
    if (_hookRunner.postToolCallHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_POST_TOOL');
    }
    if (_hookRunner.onToolErrorHooks.isNotEmpty) {
      enabledHooks.add('LIFECYCLE_HOOK_ON_TOOL_ERROR');
    }

    final customAgentsProtos = <Map<String, dynamic>>[];
    for (final subagent in _subagents) {
      final activeSubTools = subagent.capabilities?.enabledTools?.toSet() ??
          BuiltinTools.readOnly().toSet();

      final resolvedSubagentTools = <Map<String, dynamic>>[];
      for (final toolName in subagent.tools) {
        if (!toolsProtos.any((t) => t['name'] == toolName)) {
          throw ArgumentError(
            "Subagent tool '$toolName' is not registered on the main agent "
            "config. Any custom tools used by subagents must also be added "
            "to the main agent's tools list.",
          );
        }
        resolvedSubagentTools.add(
          toolsProtos.firstWhere((t) => t['name'] == toolName),
        );
      }

      final subagentSystemInstructionsProto = <String, dynamic>{};
      if (subagent.systemInstructions != null) {
        if (subagent.systemInstructions is String) {
          subagentSystemInstructionsProto['appended'] = {
            'appended_sections': [
              {'title': 'System', 'content': subagent.systemInstructions},
            ],
          };
        } else if (subagent.systemInstructions
            is List<SystemInstructionSection>) {
          subagentSystemInstructionsProto['appended'] = {
            'appended_sections':
                (subagent.systemInstructions as List<SystemInstructionSection>)
                    .map((s) => {'title': s.title, 'content': s.content})
                    .toList(),
          };
        } else if (subagent.systemInstructions is CustomSystemInstructions) {
          final c = subagent.systemInstructions as CustomSystemInstructions;
          subagentSystemInstructionsProto['custom'] = {
            'part': [
              {'text': c.text},
            ],
          };
        } else if (subagent.systemInstructions is TemplatedSystemInstructions) {
          final t = subagent.systemInstructions as TemplatedSystemInstructions;
          subagentSystemInstructionsProto['appended'] = {
            if (t.identity != null) 'custom_identity': t.identity,
            'appended_sections': t.sections
                .map((s) => {'title': s.title, 'content': s.content})
                .toList(),
          };
        } else if (subagent.systemInstructions is SystemInstructions) {
          subagentSystemInstructionsProto.addAll(
            (subagent.systemInstructions as SystemInstructions).toMap(),
          );
        }
      }

      customAgentsProtos.add({
        'name': subagent.name,
        'description': subagent.description,
        if (subagentSystemInstructionsProto.isNotEmpty)
          'system_instructions': subagentSystemInstructionsProto,
        'harness_side_tools': {
          'subagents': {'enabled': false},
          'find': {'enabled': activeSubTools.contains(BuiltinTools.findFile)},
          'run_command': {
            'enabled': activeSubTools.contains(BuiltinTools.runCommand),
          },
          'edit_file': {
            'enabled': activeSubTools.contains(BuiltinTools.editFile),
          },
          'view_file': {
            'enabled': activeSubTools.contains(BuiltinTools.viewFile),
          },
          'create_file': {
            'enabled': activeSubTools.contains(BuiltinTools.createFile),
          },
          'grep_search': {
            'enabled': activeSubTools.contains(BuiltinTools.searchDirectory),
          },
          'list_dir': {
            'enabled': activeSubTools.contains(BuiltinTools.listDirectory),
          },
          'generate_image': {
            'enabled': activeSubTools.contains(BuiltinTools.generateImage),
          },
          'search_web': {
            'enabled': activeSubTools.contains(BuiltinTools.searchWeb),
          },
        },
        'tools': resolvedSubagentTools,
        'agent_mode': (subagent.capabilities?.agentMode ?? AgentMode.autonomous)
            .protoValue,
      });
    }

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
      'agent_mode': cfg.agentMode.protoValue,
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
      if (enabledHooks.isNotEmpty) 'enabled_hooks': enabledHooks,
      if (customAgentsProtos.isNotEmpty) 'custom_subagents': customAgentsProtos,
      if (retryConfigMap != null && retryConfigMap.isNotEmpty)
        'retry_config': retryConfigMap,
      if (debugConfigMap != null && debugConfigMap.isNotEmpty)
        'debug_config': debugConfigMap,
    };
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
  final List<Step> _initialHistory = [];
  UsageMetadata _cumulativeUsage = UsageMetadata();
  final Map<String, UsageMetadata> _trajectoryUsages = {};

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
  })  : _process = process,
        _ws = ws,
        _messageStream = messageStream,
        _toolRunner = toolRunner,
        _hookRunner = hookRunner {
    if (initialHistory != null) {
      _initialHistory.addAll(initialHistory);
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

    // 1. Process call hook requests
    if (normalizedEvent.containsKey('call_hook_request')) {
      final req = Map<String, dynamic>.from(
          normalizedEvent['call_hook_request'] as Map);
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
      return;
    }

    // Process usage update
    if (normalizedEvent.containsKey('usage_update')) {
      final usageUpdate = Map<String, dynamic>.from(
        normalizedEvent['usage_update'] as Map,
      );
      if (usageUpdate.containsKey('total') && usageUpdate['total'] is Map) {
        _cumulativeUsage = UsageMetadata.fromMap(
          Map<String, dynamic>.from(usageUpdate['total'] as Map),
        );
      }
      if (usageUpdate.containsKey('agents') && usageUpdate['agents'] is List) {
        _parseTrajectoryUsages(usageUpdate['agents'] as List);
      }
      return;
    }

    // 2. Process step update
    if (normalizedEvent.containsKey('step_update')) {
      final stepJson = Map<String, dynamic>.from(
        normalizedEvent['step_update'],
      );
      final step = Step.fromMap(stepJson);

      if (step.cascadeId.isNotEmpty) {
        _convId = step.cascadeId;
      }

      Step stepForQueue = step;
      if (step.toolCalls.isNotEmpty) {
        final registeredTools = _toolRunner.tools;
        final filteredCalls = step.toolCalls
            .where((tc) => !registeredTools.containsKey(tc.name))
            .toList();
        if (filteredCalls.length != step.toolCalls.length) {
          stepForQueue = step.copyWith(toolCalls: filteredCalls);
        }
      }

      // Add step to stream
      _safeAdd(stepForQueue);

      // Dispatch OnCompactionHook if step is compaction
      if (step.type == StepType.compaction) {
        final turnCtx =
            _hookRouter?.currentTurnContext ?? _hookRunner.currentTurnContext;
        unawaited(_hookRunner.dispatchCompaction(turnCtx, step));
      }

      // Track step state transitions and dispatch pre/post step hooks
      final trajectoryId = stepJson['trajectory_id']?.toString() ?? '';
      final stepIndex =
          int.tryParse((stepJson['step_index'] ?? '0').toString()) ?? 0;
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

      // Handle interactive requests if in WAITING_FOR_USER status
      if (step.status == StepStatus.waitingForUser) {
        if (stepJson.containsKey('questions_request')) {
          await _handleQuestionRequest(stepJson);
        }
        if (stepJson.containsKey('tool_confirmation_request')) {
          await _handleToolConfirmationRequest(stepJson);
        }
      }
    }

    // 3. Process trajectory state updates
    if (normalizedEvent.containsKey('trajectory_state_update')) {
      final update = normalizedEvent['trajectory_state_update'] as Map;
      final state = update['state']?.toString();
      final trajectoryId = update['trajectory_id']?.toString() ?? '';
      if (_convId.isEmpty && trajectoryId.isNotEmpty) {
        _convId = trajectoryId;
      }
      final isSubagent = trajectoryId.isNotEmpty && trajectoryId != _convId;

      if (isSubagent) {
        if (update.containsKey('error') &&
            update['error'].toString().isNotEmpty) {
          final errMsg = update['error'].toString();
          _logger.info('Subagent trajectory failed with error: $errMsg');
        }
        return;
      }

      if (state == 'STATE_RUNNING' || state == 'RUNNING') {
        _idleState = false;
      } else if (state == 'STATE_IDLE' || state == 'IDLE') {
        if (update.containsKey('error') &&
            update['error'].toString().isNotEmpty) {
          final errMsg = update['error'].toString();
          _safeAddError(AntigravityExecutionException(errMsg));
        }
        if (!_idleState) {
          _idleState = true;
          _safeAdd(
            Step(
              id: 'idle_sentinel',
              stepIndex: -1,
              type: StepType.finish,
              source: StepSource.system,
              target: StepTarget.environment,
              status: StepStatus.done,
            ),
          );
        }
      } else if (state == 'STATE_CANCELLED' || state == 'CANCELLED') {
        final errMsg =
            update.containsKey('error') && update['error'].toString().isNotEmpty
                ? update['error'].toString()
                : 'Turn cancelled';
        _safeAddError(AntigravityExecutionException(errMsg));
        _idleState = true;
        _safeAdd(
          Step(
            id: 'idle_sentinel',
            stepIndex: -1,
            type: StepType.finish,
            source: StepSource.system,
            target: StepTarget.environment,
            status: StepStatus.done,
          ),
        );
      }
      _logger.fine('Trajectory state updated: $state for $trajectoryId');
    }

    // 4. Process tool call execution requested by model
    if (normalizedEvent.containsKey('tool_call')) {
      final tcJson = Map<String, dynamic>.from(normalizedEvent['tool_call']);
      final tc = ToolCall.fromMap(tcJson);
      _logger.info('Tool call requested: ${tc.name}');
      await _handleToolCall(tc);
    }
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
          ToolResult(id: toolCall.id, name: toolCall.name, error: errReason),
        ]);
        return;
      }

      ToolResult result;
      try {
        final results = await _toolRunner.processToolCalls([toolCall]);
        result = results[0];
      } catch (e) {
        result = ToolResult(
          id: toolCall.id,
          name: toolCall.name,
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
      'complex_user_input': {'parts': parts},
    };

    _logger.finest('>>> Sending complex_user_input over WebSocket');
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
    final rc = stepUpdate['run_command'];
    if (rc is Map && rc.containsKey('combined_output')) {
      return RunCommandResult(output: rc['combined_output'].toString());
    }
  } else if (stepUpdate.containsKey('list_directory')) {
    final ld = stepUpdate['list_directory'];
    if (ld is Map && ld.containsKey('results')) {
      final results = ld['results'] as List;
      final entries = results.map((r) {
        if (r is Map) {
          return ListDirectoryEntry(
            name: (r['name'] ?? '').toString(),
            isDirectory: r['is_directory'] == true || r['isDirectory'] == true,
            fileSize: int.tryParse(
                    (r['file_size'] ?? r['fileSize'] ?? '0').toString()) ??
                0,
          );
        }
        return const ListDirectoryEntry();
      }).toList();
      return ListDirectoryResult(entries: entries);
    }
  } else if (stepUpdate.containsKey('find_file')) {
    final ff = stepUpdate['find_file'];
    if (ff is Map && ff.containsKey('output')) {
      return FindFileResult(output: ff['output'].toString());
    }
  } else if (stepUpdate.containsKey('search_directory')) {
    final sd = stepUpdate['search_directory'];
    if (sd is Map && sd.containsKey('num_results')) {
      return SearchDirectoryResult(
        numResults: int.tryParse(
                (sd['num_results'] ?? sd['numResults'] ?? '0').toString()) ??
            0,
      );
    }
  } else if (stepUpdate.containsKey('edit_file')) {
    final ef = stepUpdate['edit_file'];
    if (ef is Map && ef.containsKey('diff_block')) {
      return EditFileResult(summary: (stepUpdate['text'] ?? '').toString());
    }
  } else if (stepUpdate.containsKey('generate_image')) {
    final gi = stepUpdate['generate_image'];
    if (gi is Map) {
      return GenerateImageResult.fromMap(Map<String, dynamic>.from(gi));
    }
  } else if (stepUpdate.containsKey('search_web')) {
    final sw = stepUpdate['search_web'];
    if (sw is Map) {
      return SearchWebResult.fromMap(Map<String, dynamic>.from(sw));
    }
  } else if (stepUpdate.containsKey('read_url_content')) {
    final ruc = stepUpdate['read_url_content'];
    if (ruc is Map) {
      return ReadUrlContentResult.fromMap(Map<String, dynamic>.from(ruc));
    }
  }
  return null;
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
    final cleanedList = [];
    final List<MediaContent> listMedia = [];
    for (final item in value) {
      final res = extractMediaFromResult(item);
      listMedia.addAll(res.media);
      if (res.cleanedValue != null) {
        cleanedList.add(res.cleanedValue);
      }
    }
    return ExtractedMedia(cleanedList.isEmpty ? null : cleanedList, listMedia);
  }
  if (value is Map) {
    final cleanedMap = <dynamic, dynamic>{};
    final List<MediaContent> mapMedia = [];
    for (final entry in value.entries) {
      final res = extractMediaFromResult(entry.value);
      mapMedia.addAll(res.media);
      if (res.cleanedValue != null) {
        cleanedMap[entry.key] = res.cleanedValue;
      }
    }
    return ExtractedMedia(cleanedMap.isEmpty ? null : cleanedMap, mapMedia);
  }
  return ExtractedMedia(value, const []);
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
    final models = harnessConfig['models'] as List<dynamic>? ?? [];
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

    // 1. Prepare App Data Dir and write the LiteRT loopback server script
    final dir = Directory(_appDataDir ?? defaultAppDataDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final scriptFile =
        File('${dir.path}${Platform.pathSeparator}litert_server.py');
    scriptFile.writeAsStringSync(litertServerPythonScript);

    // 2. Start the LiteRT OpenAI HTTP server
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
      if (maxContextTokens != null) ...[
        '--max_context_tokens',
        maxContextTokens!.toString()
      ],
    ];

    _logger.info('Starting LiteRT OpenAI server: python3 ${args.join(' ')}');
    _serverProcess = await Process.start('python3', args);

    final portCompleter = Completer<int>();
    final portRegex = RegExp(r'^LITERT_SERVER_PORT:(\d+)$');

    _serverProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _logger.fine('[LiteRT Server Stdout] $line');
      final match = portRegex.firstMatch(line);
      if (match != null && !portCompleter.isCompleted) {
        portCompleter.complete(int.parse(match.group(1)!));
      }
    });

    _serverProcess!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _logger.warning('[LiteRT Server Stderr] $line');
    });

    int actualPort;
    try {
      actualPort =
          await portCompleter.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      _serverProcess?.kill();
      throw Exception(
          'Failed to receive port from LiteRT server process. Error: $e');
    }

    final litertBaseUrl = 'http://127.0.0.1:$actualPort';
    _logger
        .info('LiteRT Server started on port $actualPort. URL: $litertBaseUrl');

    // 3. Health Check loop
    final client = HttpClient();
    bool healthOk = false;
    for (var i = 0; i < 60; i++) {
      try {
        final request =
            await client.getUrl(Uri.parse('$litertBaseUrl/v1/models'));
        final response = await request.close();
        if (response.statusCode == 200) {
          healthOk = true;
          break;
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!healthOk) {
      _serverProcess?.kill();
      throw Exception('LiteRT loopback HTTP endpoint failed to respond.');
    }

    // 4. Warm-up request
    try {
      var warmupTimeoutSeconds = 120.0;
      if (maxContextTokens != null && maxContextTokens! > 0) {
        final scaled = maxContextTokens! / 250.0;
        if (scaled > warmupTimeoutSeconds) {
          warmupTimeoutSeconds = scaled;
        }
      }
      final request =
          await client.postUrl(Uri.parse('$litertBaseUrl/v1/chat/completions'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'model': modelName,
        'messages': [
          {'role': 'user', 'content': 'Hello'}
        ],
        'stream': false,
      }));
      final response = await request.close().timeout(
          Duration(milliseconds: (warmupTimeoutSeconds * 1000).round()));
      await response.drain();
    } catch (e) {
      _logger.warning('LiteRT warm-up request timed out or failed: $e');
    }
    client.close();

    baseUrl = litertBaseUrl;

    // 5. Connect to local Go localharness subprocess
    await super.start();
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
