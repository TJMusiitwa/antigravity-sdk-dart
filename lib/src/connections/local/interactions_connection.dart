// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of 'local_connection.dart';

const _interactionsStopReasons = {
  'max_model_calls_exceeded': StopReason.maxModelCallsExceeded,
  'max_tool_calls_exceeded': StopReason.maxToolCallsExceeded,
  'max_input_tokens_exceeded': StopReason.maxInputTokensExceeded,
  'max_output_tokens_exceeded': StopReason.maxOutputTokensExceeded,
  'max_total_tokens_exceeded': StopReason.maxTotalTokensExceeded,
  'quota_exhausted': StopReason.quotaExhausted,
};

/// Converts a GAOS `UserInputStep` map into SDK prompt content.
ContentPrimitive _userInputStepToContent(Map<String, dynamic> userInput) {
  final content = userInput['content'];
  if (content is String) return content;
  if (content is Map) {
    if (content.containsKey('name') && !content.containsKey('type')) {
      final name = BuiltinSlashCommandName.values
          .where((n) => n.value == content['name'].toString())
          .firstOrNull;
      return name == null ? '' : SlashCommand(name: name);
    }
    return content['type'] == 'text' ? '${content['text'] ?? ''}' : '';
  }
  if (content is List) {
    final items = <dynamic>[];
    for (final item in content) {
      if (item is! Map) continue;
      final type = item['type'];
      if (type == 'text') {
        items.add('${item['text'] ?? ''}');
      } else if (const {'image', 'audio', 'video', 'document'}.contains(type)) {
        final data = item['data'];
        try {
          items.add(MediaContent.fromBytes(
            data is String ? base64Decode(data) : const <int>[],
            '${item['mime_type'] ?? ''}',
          ));
        } on AntigravityValidationException {
          // Unsupported MIME types are dropped, matching the harness contract.
        }
      }
    }
    if (items.isEmpty) return '';
    return items.length == 1 ? items.single : items;
  }
  return '';
}

/// Parses a built-in tool's JSON result string into its typed result.
dynamic _extractInteractionsToolResult(String toolName, String raw) {
  if (raw.isEmpty) return null;
  final parsers = <String, dynamic Function(Map<String, dynamic>)>{
    BuiltinTools.runCommand.value: RunCommandResult.fromMap,
    BuiltinTools.listDirectory.value: ListDirectoryResult.fromMap,
    BuiltinTools.findFile.value: FindFileResult.fromMap,
    BuiltinTools.searchDirectory.value: SearchDirectoryResult.fromMap,
    BuiltinTools.editFile.value: EditFileResult.fromMap,
    BuiltinTools.generateImage.value: GenerateImageResult.fromMap,
    BuiltinTools.searchWeb.value: SearchWebResult.fromMap,
    BuiltinTools.readUrlContent.value: ReadUrlContentResult.fromMap,
  };
  final parser = parsers[toolName];
  if (parser == null) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return parser(Map<String, dynamic>.from(decoded));
  } catch (_) {
    // Fall through to the plain-text fallbacks below.
  }
  if (toolName == BuiltinTools.editFile.value) {
    return EditFileResult(summary: raw);
  }
  if (toolName == BuiltinTools.findFile.value) {
    return FindFileResult(output: raw);
  }
  return null;
}

/// Converts a tool result value into JSON-compatible data.
dynamic _toJsonValue(dynamic value) {
  return jsonDecode(jsonEncode(value, toEncodable: (Object? o) {
    try {
      return (o as dynamic).toMap();
    } catch (_) {
      return o.toString();
    }
  }));
}

/// Connection to localharness over the GAOS Interactions JSON protocol.
///
/// Created by [InteractionsConnectionStrategy]; use [InteractionsAgentConfig]
/// rather than constructing it directly.
class InteractionsConnection extends LocalConnection {
  final InteractionsStepAssembler _assembler;
  final Map<String, List<ParsedElicitation>> _pendingElicitations = {};
  final Completer<void> _sessionEndDone = Completer<void>();

  /// How long [disconnect] waits for `interaction.completed` after asking the
  /// harness to run session-end hooks.
  static const sessionEndTimeout = Duration(seconds: 30);

  InteractionsConnection({
    required super.process,
    required super.ws,
    required super.messageStream,
    required super.toolRunner,
    required super.hookRunner,
    String rootInteractionId = '',
  })  : _assembler =
            InteractionsStepAssembler(rootInteractionId: rootInteractionId),
        super(
          mainTrajectoryId:
              rootInteractionId.isEmpty ? null : rootInteractionId,
        );

  /// The root interaction ID, used as the conversation identifier.
  @override
  String get conversationId => mainTrajectoryId ?? '';

  void _sendJsonEvent(Map<String, dynamic> event) {
    if (_disconnecting) return;
    _ws.add(jsonEncode(event));
  }

  void _runInBackground(Future<void> Function() task) {
    unawaited(task().catchError((Object e) {
      _logger.severe('Interactions background task failed: $e');
    }));
  }

  @override
  Future<void> _handleEvent(Map<String, dynamic> event) async {
    if (_disconnecting) return;
    switch (event['event_type']?.toString() ?? '') {
      case 'interaction.created':
        final id = event['interaction_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _assembler.setRootInteractionId(id);
          mainTrajectoryId ??= id;
        }
      case 'interaction.completed':
        if (!_sessionEndDone.isCompleted) _sessionEndDone.complete();
      case 'call_hook_request':
        await _handleInteractionsHookRequest(event);
      case 'function_invocation':
        _runInBackground(() => _handleFunctionInvocation(event));
      case 'step.start':
        final result = _assembler.handleStepStart(event);
        if (result.step != null) await _emitAssembled(result);
        if (result.elicitation != null) {
          _enqueueElicitation(result.elicitation!);
        }
      case 'step.delta':
        final result = _assembler.handleStepDelta(event);
        if (result.step != null) await _emitAssembled(result);
      case 'step.stop':
        final result = _assembler.handleStepStop(event);
        final usage = result.stepUsage;
        if (usage != null) {
          _cumulativeUsage = _cumulativeUsage + usage;
          final trajectoryId = [
            result.trajectoryId,
            _assembler.rootInteractionId,
            mainTrajectoryId ?? '',
          ].firstWhere((id) => id.isNotEmpty, orElse: () => '');
          if (trajectoryId.isNotEmpty) {
            final previous = _trajectoryUsages[trajectoryId];
            _trajectoryUsages[trajectoryId] =
                previous == null ? usage : previous + usage;
          }
        }
        if (result.step != null) await _emitAssembled(result);
      case 'state_update':
        _handleInteractionsStateUpdate(event);
    }
  }

  Future<void> _emitAssembled(StepAssemblyResult result) => _emitStep(
        result.step!,
        dispatchPre: result.dispatchPre,
        dispatchPost: result.dispatchPost,
      );

  /// Enqueues [step], suppressing calls to client tools (which arrive
  /// separately as `function_invocation`), and fires step hooks.
  Future<void> _emitStep(
    Step step, {
    bool dispatchPre = false,
    bool dispatchPost = false,
  }) async {
    _safeAdd(_filterHostHandledToolCalls(step));
    if (mainTrajectoryId == null && step.trajectoryId.isNotEmpty) {
      mainTrajectoryId = step.trajectoryId;
    }
    if (dispatchPre) await _hookRunner.dispatchPreStep(step);
    if (dispatchPost) await _hookRunner.dispatchPostStep(step);
  }

  void _handleInteractionsStateUpdate(Map<String, dynamic> event) {
    final subId = event['sub_interaction_id']?.toString() ?? '';
    final parentId = event['parent_interaction_id']?.toString() ?? '';
    if (subId.isNotEmpty && parentId.isNotEmpty) {
      _assembler.recordParentTrajectory(subId, parentId);
    }
    final rootId = _assembler.rootInteractionId.isNotEmpty
        ? _assembler.rootInteractionId
        : mainTrajectoryId ?? '';
    final isSubagent = subId.isNotEmpty &&
        ((rootId.isNotEmpty && subId != rootId) ||
            (rootId.isEmpty && parentId.isNotEmpty));
    final error = event['error']?.toString() ?? '';
    if (isSubagent) {
      if (error.isNotEmpty) {
        _logger.info('Subagent trajectory failed with error: $error');
      }
      return;
    }

    final reason = _interactionsStopReasons[event['reason']?.toString()];
    if (reason != null) _turnStopReason = reason;

    switch (event['state']?.toString() ?? '') {
      case 'running' || 'waiting_for_tasks':
        _idleState = false;
      case 'fully_idle':
        if (error.isNotEmpty) {
          _safeAddError(AntigravityExecutionException(error));
        }
        _idleState = true;
        _safeAdd(LocalConnection._createIdleSentinelStep());
      case 'cancelled':
        _safeAddError(AntigravityExecutionException(
            error.isNotEmpty ? error : 'Turn cancelled'));
        _idleState = true;
        _safeAdd(LocalConnection._createIdleSentinelStep());
    }
  }

  Step _buildCompactionStep(Map<String, dynamic> event) {
    final args = event['on_compaction_args'] is Map
        ? Map<String, dynamic>.from(event['on_compaction_args'] as Map)
        : <String, dynamic>{};
    final trajectoryId =
        _firstNonEmpty(args, 'interaction_id', 'trajectory_id');
    final index = int.tryParse('${args['step_index'] ?? 0}') ?? 0;
    final summary = args['summary']?.toString() ?? '';
    return Step(
      id: interactionsStepId(trajectoryId, index),
      stepIndex: index,
      trajectoryId: trajectoryId,
      type: StepType.compaction,
      source: StepSource.system,
      target: StepTarget.user,
      status: StepStatus.done,
      content: summary.isNotEmpty ? summary : 'Context compaction',
    );
  }

  Future<void> _handleInteractionsHookRequest(
      Map<String, dynamic> event) async {
    if (event['type'] == 'on_compaction') {
      await _emitStep(_buildCompactionStep(event),
          dispatchPre: true, dispatchPost: true);
    }
    _runInBackground(() => _dispatchHookRequest(event));
  }

  Future<void> _dispatchHookRequest(Map<String, dynamic> event) async {
    final hookType = event['type']?.toString() ?? '';
    final response = <String, dynamic>{
      'event_type': 'call_hook_response',
      'request_id': event['request_id']?.toString() ?? '',
    };
    final hooks = _hookRunner;
    try {
      switch (hookType) {
        case 'on_session_start':
          await hooks.dispatchSessionStart();
          response['empty_result'] = <String, dynamic>{};
        case 'on_session_end':
          await hooks.dispatchSessionEnd();
          response['empty_result'] = <String, dynamic>{};
        case 'pre_turn':
          ContentPrimitive userInput = '';
          final args = event['pre_turn_args'];
          if (args is Map && args['user_input'] is Map) {
            userInput = _userInputStepToContent(
                Map<String, dynamic>.from(args['user_input'] as Map));
          }
          final result = await hooks.dispatchPreTurn(userInput);
          response['pre_turn_result'] = result.allow
              ? {'decision': 'allow'}
              : {
                  'decision': 'deny',
                  if (result.message.isNotEmpty) 'reason': result.message,
                };
        case 'post_turn':
          final args = event['post_turn_args'];
          final text = args is Map ? '${args['response_text'] ?? ''}' : '';
          await hooks.dispatchPostTurn(hooks.currentTurnContext, text);
          response['empty_result'] = <String, dynamic>{};
        case 'pre_tool':
          response['pre_tool_result'] = await _dispatchPreToolHook(event);
        case 'post_tool':
          await _dispatchPostToolHook(event);
          response['empty_result'] = <String, dynamic>{};
        case 'on_tool_error':
          final custom = await _dispatchToolErrorHook(event);
          if (custom != null) {
            response['on_tool_error_result'] = {'custom_error_message': custom};
          } else {
            response['empty_result'] = <String, dynamic>{};
          }
        case 'on_compaction':
          await hooks.dispatchCompaction(
              hooks.currentTurnContext, _buildCompactionStep(event));
          response['empty_result'] = <String, dynamic>{};
        case 'stop':
          response['stop_result'] = await _dispatchStopHook(event);
        default:
          _logger.warning('Unknown or unhandled hook received -> type: '
              '$hookType, name: ${event['name']}');
          response['empty_result'] = <String, dynamic>{};
      }
    } catch (e) {
      _logger.severe('Hook ${event['name']} failed: $e');
      response['error_message'] = 'Hook failed: $e';
    }
    _sendJsonEvent(response);
  }

  static String _firstNonEmpty(Map<dynamic, dynamic> map, String a, String b) {
    final first = map[a]?.toString() ?? '';
    return first.isNotEmpty ? first : map[b]?.toString() ?? '';
  }

  /// Returns the tool name, server, call ID, and step ID shared by tool hooks.
  static ({String name, String? server, String? callId, String? stepId})
      _toolHookIdentity(Map<dynamic, dynamic> args) {
    final rawName = args['tool_name']?.toString() ?? '';
    final server = args['server_name']?.toString() ?? '';
    final callId = args['call_id']?.toString() ?? '';
    final trajectoryId =
        _firstNonEmpty(args, 'interaction_id', 'trajectory_id');
    final hasStep = trajectoryId.isNotEmpty || args.containsKey('step_index');
    return (
      name: protoFieldToSdkName[rawName] ?? rawName,
      server: server.isEmpty ? null : server,
      callId: callId.isEmpty ? null : callId,
      stepId: hasStep
          ? interactionsStepId(
              trajectoryId, int.tryParse('${args['step_index'] ?? 0}') ?? 0)
          : null,
    );
  }

  Future<Map<String, dynamic>> _dispatchPreToolHook(
      Map<String, dynamic> event) async {
    final rawArgs = event['pre_tool_args'];
    final hookArgs = rawArgs is Map ? rawArgs : const {};
    final identity = _toolHookIdentity(hookArgs);
    var args = <String, dynamic>{};
    final argsJson = hookArgs['arguments_json'];
    if (argsJson is String && argsJson.isNotEmpty) {
      args = Map<String, dynamic>.from(jsonDecode(argsJson) as Map);
    }
    String? canonicalPath;
    for (final key in wirePathArgumentKeys) {
      final value = args[key];
      if (value is String && value.isNotEmpty) {
        args[key] = normalizeWirePath(value);
        canonicalPath ??= args[key] as String;
      }
    }
    final result = await _hookRunner.dispatchPreToolCall(
      _hookRunner.currentTurnContext,
      ToolCall(
        name: identity.name,
        args: args,
        id: identity.callId,
        stepId: identity.stepId,
        serverName: identity.server,
        canonicalPath: canonicalPath,
      ),
    );
    if (result.allow) {
      return {
        'decision': 'allow',
        if (result.modifiedArgs != null) 'modified_args': result.modifiedArgs,
      };
    }
    return {
      'decision': 'deny',
      if (result.message.isNotEmpty) 'reason': result.message,
    };
  }

  Future<void> _dispatchPostToolHook(Map<String, dynamic> event) async {
    final rawArgs = event['post_tool_args'];
    final hookArgs = rawArgs is Map ? rawArgs : const {};
    final identity = _toolHookIdentity(hookArgs);
    final raw = hookArgs['result']?.toString() ?? '';
    final error = hookArgs['error']?.toString() ?? '';
    dynamic value;
    if (error.isEmpty) {
      value = _extractInteractionsToolResult(identity.name, raw) ?? raw;
    }
    await _hookRunner.dispatchPostToolCall(
      _hookRunner.currentTurnContext,
      ToolResult(
        name: identity.name,
        id: identity.callId,
        stepId: identity.stepId,
        serverName: identity.server,
        result: value,
        error: error.isEmpty ? null : error,
      ),
    );
  }

  Future<String?> _dispatchToolErrorHook(Map<String, dynamic> event) async {
    final rawArgs = event['on_tool_error_args'];
    final hookArgs = rawArgs is Map ? rawArgs : const {};
    final identity = _toolHookIdentity(hookArgs);
    final message = hookArgs['error_message']?.toString() ?? '';
    final recovery = await _hookRunner.dispatchOnToolError(
      _hookRunner.currentTurnContext,
      ToolExecutionException(
        message.isNotEmpty ? message : 'Tool failed',
        toolName: identity.name,
        serverName: identity.server,
        callId: identity.callId,
        stepId: identity.stepId,
      ),
    );
    return recovery is String && recovery.trim().isNotEmpty
        ? recovery.trim()
        : null;
  }

  Future<Map<String, dynamic>> _dispatchStopHook(
      Map<String, dynamic> event) async {
    final rawArgs = event['stop_args'];
    final args = rawArgs is Map ? rawArgs : const {};
    final result = await _hookRunner.dispatchStop(
      _hookRunner.currentTurnContext,
      StopArgs(
        responseText: args['response_text']?.toString() ?? '',
        trajectoryId: _firstNonEmpty(args, 'interaction_id', 'trajectory_id'),
        continuationCount:
            int.tryParse('${args['continuation_count'] ?? 0}') ?? 0,
        stopReason: _interactionsStopReasons[args['stop_reason']?.toString()] ??
            StopReason.unspecified,
        errorMessage: args['error_message']?.toString() ?? '',
      ),
    );
    if (result.decision == StopDecision.continueTurn) {
      final reason = result.reason.trim();
      return {
        'decision': 'continue',
        if (reason.isNotEmpty) 'reason': reason,
      };
    }
    return {'decision': 'allow_stop'};
  }

  /// Buffers elicitations from one question batch and schedules a dispatch.
  void _enqueueElicitation(ParsedElicitation elicitation) {
    final batch = _pendingElicitations[elicitation.groupKey];
    if (batch != null) {
      batch.add(elicitation);
      return;
    }
    _pendingElicitations[elicitation.groupKey] = [elicitation];
    _runInBackground(() => _flushElicitationGroup(elicitation.groupKey));
  }

  /// Yields once so the elicitation_call steps of a multi-question batch
  /// arrive together, then answers them all.
  Future<void> _flushElicitationGroup(String groupKey) async {
    await Future<void>.delayed(Duration.zero);
    final batch = _pendingElicitations.remove(groupKey);
    if (batch == null || batch.isEmpty) return;
    final ids = [for (final item in batch) item.elicitationId];
    List<Map<String, dynamic>> events;
    try {
      final result = await _hookRunner.dispatchInteraction(
        _hookRunner.currentTurnContext,
        AskQuestionInteractionSpec(
            questions: [for (final item in batch) item.question]),
      );
      events = result == null
          ? questionResponsesToElicitationResultEvents(ids, responses: [
              for (final _ in ids) QuestionResponse(skipped: true),
            ])
          : questionResponsesToElicitationResultEvents(ids,
              responses: result.responses, cancelled: result.cancelled);
    } catch (e) {
      _logger.severe('Question elicitation failed; sending error answer: $e');
      events = questionResponsesToElicitationResultEvents(ids, responses: [
        for (final _ in ids)
          QuestionResponse(
              freeformResponse: 'SDK error processing question: $e'),
      ]);
    }
    events.forEach(_sendJsonEvent);
  }

  /// Executes a client-side tool requested by `function_invocation`.
  Future<void> _handleFunctionInvocation(Map<String, dynamic> event) async {
    final callId = _firstNonEmpty(event, 'call_id', 'id');
    final name = event['name']?.toString() ?? '';
    final subId = event['sub_interaction_id']?.toString() ?? '';
    final trajectoryId = subId.isNotEmpty
        ? subId
        : (_assembler.rootInteractionId.isNotEmpty
            ? _assembler.rootInteractionId
            : mainTrajectoryId ?? '');
    final rawArgs = event['arguments'];
    final call = ToolCall(
      id: callId,
      name: name,
      args: rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : {},
    );
    try {
      _safeAdd(Step(
        id: callId,
        stepIndex: 1,
        trajectoryId: trajectoryId,
        type: StepType.toolCall,
        source: StepSource.model,
        target: StepTarget.environment,
        status: StepStatus.active,
        toolCalls: [call],
      ));
      ToolResult result;
      try {
        result = (await _toolRunner.processToolCalls([call])).single;
      } catch (e) {
        result = ToolResult(
          id: callId,
          name: name,
          error: e.toString(),
          exception: e is Exception ? e : Exception(e.toString()),
        );
      }
      await sendToolResults([result]);
    } catch (e) {
      _logger.severe('Function invocation failed; returning error: $e');
      await sendToolResults([
        ToolResult(id: callId, name: name, error: 'Internal SDK error: $e'),
      ]);
    }
  }

  /// Sends tool results as GAOS `function_result` events.
  ///
  /// Each result needs an [ToolResult.id] to correlate with its call. Media
  /// attachments are stripped; only the JSON-compatible value is sent.
  @override
  Future<void> sendToolResults(List<ToolResult> results) async {
    for (final result in results) {
      final id = result.id;
      if (id == null || id.isEmpty) {
        throw ArgumentError("ToolResult for '${result.name}' is missing an id. "
            'The InteractionsConnection protocol requires an id to correlate '
            'results with calls.');
      }
      if (result.error != null) {
        _sendJsonEvent(toolResultToFunctionResultEvent(
            callId: id, toolName: result.name, errorMessage: result.error));
        continue;
      }
      final value =
          _toJsonValue(extractMediaFromResult(result.result).cleanedValue);
      _sendJsonEvent(toolResultToFunctionResultEvent(
        callId: id,
        toolName: result.name,
        result:
            value is Map ? Map<String, dynamic>.from(value) : {'result': value},
      ));
    }
  }

  @override
  Future<void> send(
    ContentPrimitive? prompt, {
    Map<String, dynamic>? kwargs,
  }) async {
    _idleState = false;
    _turnStopReason = StopReason.unspecified;
    if (_assembler.rootInteractionId.isNotEmpty) {
      mainTrajectoryId = _assembler.rootInteractionId;
    }
    _sendJsonEvent(contentToUserInputEvent(prompt ?? ''));
  }

  @override
  Future<void> cancel() async {
    _sendJsonEvent(buildCancelInteractionEvent());
  }

  /// Automated triggers are not yet supported over the Interactions protocol.
  @override
  Future<void> sendTriggerNotification(String content) {
    throw UnsupportedError('Automated trigger notifications are not yet '
        'supported on InteractionsConnection.');
  }

  /// Completes the interaction so the harness runs session-end hooks, then
  /// shuts the harness down.
  ///
  /// Waits up to [sessionEndTimeout] for `interaction.completed`; a hook error
  /// is rethrown after shutdown finishes.
  @override
  Future<void> disconnect() async {
    Object? hookError;
    if (!_disconnecting && _hookRunner.onSessionEndHooks.isNotEmpty) {
      try {
        _sendJsonEvent(buildCompleteInteractionEvent());
        await _sessionEndDone.future.timeout(sessionEndTimeout);
      } catch (e) {
        hookError = e;
      }
    }
    await super.disconnect();
    if (hookError != null) throw hookError;
  }
}

/// Strategy that spawns localharness in GAOS Interactions mode.
class InteractionsConnectionStrategy extends LocalConnectionStrategy {
  /// Creates a strategy with the same configuration as
  /// [LocalConnectionStrategy].
  ///
  /// Inline root skills are not part of the Interactions `agent_config` and are
  /// ignored, matching the Python SDK.
  InteractionsConnectionStrategy({
    super.binaryPath,
    required super.toolRunner,
    required super.hookRunner,
    super.tools,
    super.models,
    required super.systemInstructions,
    required super.capabilitiesConfig,
    super.conversationId,
    super.sessionContinuationMode,
    super.saveDir,
    required super.workspaces,
    super.appDataDir,
    required super.skillsPaths,
    super.inlineSkills,
    super.mcpServers,
    super.subagents,
    super.debugConfig,
    super.retryConfig,
    super.budgetConfig,
    super.compactionConfig,
    super.policies,
  });

  /// Builds the `interaction.create` event. Exposed for testing.
  Map<String, dynamic> buildCreateInteractionEventForTest() =>
      _buildCreateInteractionEvent();

  Map<String, dynamic> _buildCreateInteractionEvent() {
    if (_inlineSkills.isNotEmpty) {
      _logger.warning('inlineSkills are not supported by '
          'InteractionsAgentConfig and will be ignored.');
    }
    return buildCreateInteractionEvent(
      models: _models,
      systemInstructions: _systemInstructions,
      capabilitiesConfig: _capabilitiesConfig,
      compactionConfig: _effectiveCompactionConfig(),
      conversationId: _conversationId,
      sessionContinuationMode: _sessionContinuationMode,
      workspaces: _workspaces,
      skillsPaths: _skillsPaths,
      appDataDir: _appDataDir,
      mcpServers: _mcpServers,
      subagents: _subagents,
      retryConfig: _retryConfig,
      budgetConfig: _budgetConfig,
      policies: _policies,
      tools: _tools,
      toolRunner: _toolRunner,
      hookRunner: _hookRunner,
    );
  }

  @override
  Future<void> start() async {
    _validateConnection();
    final createEvent = _buildCreateInteractionEvent();

    final binaryPath =
        await BinaryDiscovery.discover(configPath: _configuredBinaryPath);
    _logger.info('Starting localharness (Interactions API) at: $binaryPath');
    final process = await Process.start(binaryPath, []);
    _process = process;
    await _sendHandshakeInputConfig(process, useInteractionsApi: true);
    final outputConfig = await _readHandshakeOutputConfig(process);
    final ws = await _connectWebSocketWithRetry(outputConfig, process);
    _ws = ws;

    final created = Completer<String>();
    final messages = StreamController<dynamic>();
    ws.listen(
      (message) {
        if (created.isCompleted) {
          messages.add(message);
          return;
        }
        try {
          final response = jsonDecode(message as String);
          if (response is! Map ||
              response['event_type'] != 'interaction.created') {
            throw AntigravityConnectionException(
                'Expected interaction.created handshake response, got: '
                '$message');
          }
          created.complete(response['interaction_id']?.toString() ?? '');
        } catch (e) {
          created.completeError(e);
        }
      },
      onError: (Object err) {
        if (!created.isCompleted) created.completeError(err);
        messages.addError(err);
      },
      onDone: () {
        if (!created.isCompleted) {
          created.completeError(AntigravityConnectionException(
              'WebSocket closed before the interaction was created.'));
        }
        messages.close();
      },
    );
    ws.add(jsonEncode(createEvent));

    final String rootInteractionId;
    try {
      rootInteractionId = await created.future;
    } catch (e) {
      await _failWithProcessStderr(
          process, 'Failed to initialize interaction with localharness', e);
    }

    final connection = InteractionsConnection(
      process: process,
      ws: ws,
      messageStream: messages.stream,
      toolRunner: _toolRunner,
      hookRunner: _hookRunner,
      rootInteractionId: rootInteractionId,
    );
    _connection = connection;
    connection._startStderrReader();
    connection._startReaderLoop();
  }
}
