import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../../types.dart';
import '../../utils/binary_discovery.dart';
import '../connection.dart';
import 'localharness_proto.dart';
import '../../hooks/hooks.dart';
import '../../tools/tool_runner.dart';

final _logger = Logger('antigravity.connection.local');

/// Strategy for establishing a LocalConnection to a Go-based localharness binary.
class LocalConnectionStrategy extends ConnectionStrategy {
  final String? _configuredBinaryPath;
  final ToolRunner _toolRunner;
  final HookRunner _hookRunner;
  final GeminiConfig _geminiConfig;
  final dynamic _systemInstructions;
  final CapabilitiesConfig _capabilitiesConfig;
  final String? _conversationId;
  final String? _saveDir;
  final List<String> _workspaces;
  final String? _appDataDir;
  final List<String> _skillsPaths;

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
    required GeminiConfig geminiConfig,
    required dynamic systemInstructions,
    required CapabilitiesConfig capabilitiesConfig,
    String? conversationId,
    String? saveDir,
    required List<String> workspaces,
    String? appDataDir,
    required List<String> skillsPaths,
    List<McpServerConfig>? mcpServers,
  }) : _configuredBinaryPath = binaryPath,
       _toolRunner = toolRunner,
       _hookRunner = hookRunner,
       _geminiConfig = geminiConfig,
       _systemInstructions = systemInstructions,
       _capabilitiesConfig = capabilitiesConfig,
       _conversationId = conversationId,
       _saveDir = saveDir,
       _workspaces = workspaces,
       _appDataDir = appDataDir,
       _skillsPaths = skillsPaths;

  @override
  Connection connect() {
    if (_connection == null) {
      throw StateError('Connection not established. Call start() first.');
    }
    return _connection!;
  }

  @override
  Future<void> start() async {
    // 1. Fail fast if no API key is available
    final apiKey =
        _geminiConfig.apiKey ?? Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw AntigravityValidationException(
        'A Gemini API key is required. Set it via GeminiConfig(apiKey: ...) '
        'or the GEMINI_API_KEY environment variable.',
      );
    }

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

    final wsUrl = 'ws://localhost:${outputConfig.port}/';
    _logger.fine('Handshake successful. Connecting to WebSocket at $wsUrl');

    // 6. Connect to local WebSocket server with retry backoff
    WebSocket? ws;
    int attempt = 0;
    const maxRetries = 5;
    while (attempt < maxRetries) {
      try {
        ws = await WebSocket.connect(
          wsUrl,
          headers: {'x-goog-api-key': outputConfig.apiKey},
        );
        break;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          _process!.kill();
          final stderrText = await _process!.stderr
              .transform(utf8.decoder)
              .join();
          throw Exception(
            'Failed to connect to WebSocket at $wsUrl after $maxRetries attempts. Stderr: $stderrText. Error: $e',
          );
        }
        final delay = Duration(milliseconds: 100 * (1 << attempt));
        _logger.warning(
          'WebSocket connection failed. Retrying in ${delay.inMilliseconds}ms...',
        );
        await Future.delayed(delay);
      }
    }

    _ws = ws;

    // 7. Send InitializeConversationEvent JSON over WebSocket
    final harnessConfig = _buildHarnessConfig(apiKey);
    final initEvent = {'config': harnessConfig};
    _ws!.add(jsonEncode(initEvent));

    _connection = LocalConnection(
      process: _process!,
      ws: _ws!,
      toolRunner: _toolRunner,
      hookRunner: _hookRunner,
    );
    _connection!._startStderrReader();
    _connection!._startReaderLoop();

    // Dispatch session-start hook if runner is set up
    await _hookRunner.dispatchSessionStart();
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

  Map<String, dynamic> _buildHarnessConfig(String apiKey) {
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
          'custom': {
            'part': [
              {'text': _systemInstructions},
            ],
          },
        };
      } else {
        systemInstructionsProto = _systemInstructions.toMap();
      }
    }

    final geminiConfigProto = {
      'model_name': _geminiConfig.models.defaultModelEntry.name,
      'api_key': apiKey,
      if (_geminiConfig.models.defaultModelEntry.generation.thinkingLevel !=
          null)
        'thinking_level': _geminiConfig
            .models
            .defaultModelEntry
            .generation
            .thinkingLevel!
            .value,
    };

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
        'model_name': cfg.imageModel,
      },
    };

    return {
      'cascade_id': _conversationId ?? '',
      'tools': toolsProtos,
      'system_instructions': systemInstructionsProto,
      'gemini_config': geminiConfigProto,
      'workspaces': workspacesProto,
      'skills_paths': _skillsPaths,
      'harness_side_tools': harnessSideTools,
      'compaction_threshold': cfg.compactionThreshold ?? 0,
      'finish_tool_schema_json': cfg.finishToolSchemaJson ?? '',
      'app_data_dir': _appDataDir ?? '',
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
class LocalConnection extends Connection {
  final Process _process;
  final WebSocket _ws;
  final ToolRunner _toolRunner;
  final HookRunner _hookRunner;

  final StreamController<Step> _stepController =
      StreamController<Step>.broadcast();
  final List<String> _stderrLines = [];
  bool _disconnecting = false;
  bool _idleState = true;
  bool _parentIdle = true;
  final Set<String> _activeSubagentIds = {};
  String _convId = '';

  @override
  bool get isIdle => _idleState;

  @override
  String get conversationId => _convId;

  /// Creates a new [LocalConnection] session.
  ///
  /// Takes [process] (for managing the localharness process), [ws] (the WebSocket connection),
  /// [toolRunner] to process incoming tool executions, and [hookRunner] to dispatch lifecycle events.
  LocalConnection({
    required Process process,
    required WebSocket ws,
    required ToolRunner toolRunner,
    required HookRunner hookRunner,
  }) : _process = process,
       _ws = ws,
       _toolRunner = toolRunner,
       _hookRunner = hookRunner;

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
    _ws.listen(
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

    // 1. Process step update
    if (normalizedEvent.containsKey('step_update')) {
      final stepJson = Map<String, dynamic>.from(
        normalizedEvent['step_update'],
      );
      final step = Step.fromMap(stepJson);

      if (step.cascadeId.isNotEmpty) {
        _convId = step.cascadeId;
      }

      // Add step to stream
      _safeAdd(step);

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

    // 2. Process trajectory state updates
    if (normalizedEvent.containsKey('trajectory_state_update')) {
      final update = normalizedEvent['trajectory_state_update'] as Map;
      final state = update['state']?.toString();
      final trajectoryId = update['trajectory_id']?.toString() ?? '';
      if (_convId.isEmpty && trajectoryId.isNotEmpty) {
        _convId = trajectoryId;
      }
      final isSubagent = trajectoryId.isNotEmpty && trajectoryId != _convId;

      if (state == 'STATE_RUNNING' || state == 'RUNNING') {
        if (isSubagent) {
          _activeSubagentIds.add(trajectoryId);
        }
        _idleState = false;
      } else if (state == 'STATE_IDLE' || state == 'IDLE') {
        if (isSubagent) {
          _activeSubagentIds.remove(trajectoryId);
        } else {
          _parentIdle = true;
        }

        if (_parentIdle && _activeSubagentIds.isEmpty) {
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
      }
      _logger.fine('Trajectory state updated: $state for $trajectoryId');
    }

    // 3. Process tool call execution requested by model
    if (normalizedEvent.containsKey('tool_call')) {
      final tcJson = Map<String, dynamic>.from(normalizedEvent['tool_call']);
      final tc = ToolCall.fromMap(tcJson);
      _logger.info('Tool call requested: ${tc.name}');
      await _handleToolCall(tc);
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

      // Post-tool-call hook
      if (result.error == null) {
        final ctx = _hookRunner.createTurnContext();
        await _hookRunner.dispatchPostToolCall(ctx, result);
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

  @override
  Future<void> send(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    _idleState = false;
    _parentIdle = false;
    final List<Map<String, dynamic>> parts = [];

    if (prompt is String) {
      parts.add({'text': prompt});
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
          parts.add({'text': p});
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
      final responseJson = result.error != null
          ? {'error': result.error}
          : {'result': result.result};

      final response = {
        'tool_response': {
          'id': result.id ?? '',
          'response_json': jsonEncode(responseJson),
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

  Map<String, dynamic> _normalizeJsonKeys(Map<String, dynamic> map) {
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

  String _toSnakeCase(String camel) {
    final exp = RegExp('(?<=[a-z0-9])[A-Z]');
    return camel.replaceAllMapped(exp, (m) => '_${m.group(0)}').toLowerCase();
  }
}
