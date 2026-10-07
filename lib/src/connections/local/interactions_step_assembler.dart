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

/// Assembles GAOS Interactions `step.*` events into SDK [Step]s.
library;

import 'dart:collection';

import '../../types.dart';
import 'hook_router.dart';

const _callToResultKind = {
  'function_call': 'function',
  'code_execution_call': 'code_execution',
  'view_file_call': 'view_file',
  'list_directory_call': 'list_directory',
  'find_file_call': 'find_file',
  'search_directory_call': 'search_directory',
  'edit_file_call': 'edit_file',
  'generate_image_call': 'generate_image',
  'google_search_call': 'google_search',
  'url_context_call': 'url_context',
  'mcp_server_tool_call': 'mcp_server_tool',
  'skill_lookup_call': 'skill_lookup',
};

const _resultToCallKind = {
  'function_result': 'function',
  'code_execution_result': 'code_execution',
  'view_file_result': 'view_file',
  'list_directory_result': 'list_directory',
  'find_file_result': 'find_file',
  'search_directory_result': 'search_directory',
  'edit_file_result': 'edit_file',
  'generate_image_result': 'generate_image',
  'google_search_result': 'google_search',
  'url_context_result': 'url_context',
  'mcp_server_tool_result': 'mcp_server_tool',
  'skill_lookup_result': 'skill_lookup',
};

final _resultKindDefaultToolName = {
  'code_execution': BuiltinTools.runCommand.value,
  'view_file': BuiltinTools.viewFile.value,
  'list_directory': BuiltinTools.listDirectory.value,
  'find_file': BuiltinTools.findFile.value,
  'search_directory': BuiltinTools.searchDirectory.value,
  'edit_file': BuiltinTools.editFile.value,
  'generate_image': BuiltinTools.generateImage.value,
  'google_search': BuiltinTools.searchWeb.value,
  'url_context': BuiltinTools.readUrlContent.value,
  // Surfaced for skill sources; not a BuiltinTools member.
  'skill_lookup': 'skill_lookup',
};

const _callStepEnvelopeKeys = {
  'type',
  'id',
  'signature',
  'timestamp',
  'description',
  'name',
  'server_name',
  'arguments',
};

const _resultStepEnvelopeKeys = {
  'type',
  'call_id',
  'signature',
  'timestamp',
  'description',
  'name',
  'server_name',
  'is_error',
  'result',
};

/// Creates a GAOS step ID: `<trajectory>:<index>`, or `<index>` alone.
String interactionsStepId(String trajectoryId, int stepIndex) =>
    trajectoryId.isEmpty ? '$stepIndex' : '$trajectoryId:$stepIndex';

/// A question elicitation parsed from an `elicitation_call` step.
class ParsedElicitation {
  final String elicitationId;

  /// The question batch this elicitation belongs to.
  final String groupKey;
  final String trajectoryId;
  final int stepIndex;
  final AskQuestionEntry question;

  ParsedElicitation({
    required this.elicitationId,
    required this.groupKey,
    required this.trajectoryId,
    required this.stepIndex,
    required this.question,
  });
}

/// The outcome of assembling one `step.*` event.
class StepAssemblyResult {
  final Step? step;
  final bool dispatchPre;
  final bool dispatchPost;
  final UsageMetadata? stepUsage;
  final String trajectoryId;
  final ParsedElicitation? elicitation;

  StepAssemblyResult({
    this.step,
    this.dispatchPre = false,
    this.dispatchPost = false,
    this.stepUsage,
    this.trajectoryId = '',
    this.elicitation,
  });
}

class _StepState {
  final String trajectoryId;
  final String parentTrajectoryId;
  final int depth;
  final int stepIndex;
  final String subtype;
  StepType type;
  final StepSource source;
  final StepTarget target;
  final String description;
  String content;
  String thinking;
  final List<ToolCall> toolCalls;
  final bool isError;
  final String errorMessage;
  final bool isToolCallStep;
  final bool isToolResultStep;

  _StepState({
    required this.trajectoryId,
    required this.parentTrajectoryId,
    required this.depth,
    required this.stepIndex,
    required this.subtype,
    required this.type,
    required this.source,
    required this.target,
    this.description = '',
    this.content = '',
    this.thinking = '',
    this.toolCalls = const [],
    this.isError = false,
    this.errorMessage = '',
    this.isToolCallStep = false,
    this.isToolResultStep = false,
  });
}

int _intValue(dynamic value) =>
    value is int ? value : int.tryParse('${value ?? 0}') ?? 0;

Map<String, dynamic> _mapValue(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _stringValue(dynamic value) => value == null ? '' : value.toString();

List<dynamic> _listValue(dynamic value) => value is List ? List.of(value) : [];

/// Parses a GAOS `Interaction.Usage` map into [UsageMetadata].
UsageMetadata? parseInteractionUsage(dynamic usage) {
  if (usage is! Map || usage.isEmpty) return null;
  int? count(String key) {
    final v = usage[key];
    return v == null ? null : _intValue(v);
  }

  final prompt = count('total_input_tokens');
  final cached = count('total_cached_tokens');
  final output = count('total_output_tokens');
  final thoughts = count('total_thought_tokens');
  final total = count('total_tokens');
  if ([prompt, cached, output, thoughts, total].every((v) => v == null)) {
    return null;
  }
  return UsageMetadata(
    promptTokenCount: prompt,
    cachedContentTokenCount: cached,
    candidatesTokenCount: output,
    thoughtsTokenCount: thoughts,
    totalTokenCount: total,
  );
}

/// Extracts plain text from a GAOS content value (string, block, or list).
String extractTextFromContent(dynamic content) {
  if (content is String) return content;
  if (content is Map) {
    if (content.containsKey('name') && !content.containsKey('type')) {
      return '/${content['name']}';
    }
    if (content['type'] == 'text') return _stringValue(content['text']);
    if (content.containsKey('content')) {
      return extractTextFromContent(content['content']);
    }
    return '';
  }
  if (content is List) {
    final buffer = StringBuffer();
    for (final item in content) {
      if (item is Map && item['type'] == 'text') {
        buffer.write(_stringValue(item['text']));
      } else if (item is String) {
        buffer.write(item);
      }
    }
    return buffer.toString();
  }
  return '';
}

({Map<String, dynamic> args, String? canonicalPath}) _normalizeToolArgs(
    Map<String, dynamic> args) {
  final normalized = Map<String, dynamic>.from(args);
  String? canonicalPath;
  for (final key in wirePathArgumentKeys) {
    final value = normalized[key];
    if (value is String && value.isNotEmpty) {
      final path = normalizeWirePath(value);
      normalized[key] = path;
      canonicalPath ??= path;
    }
  }
  final imagePaths = normalized['image_paths'];
  if (imagePaths is List) {
    normalized['image_paths'] = [
      for (final p in imagePaths) p is String ? normalizeWirePath(p) : p,
    ];
  }
  return (args: normalized, canonicalPath: canonicalPath);
}

/// Extracts the question batch prefix from `<conv>-question-<step>-<index>`.
String extractElicitationGroupKey(String elicitationId) {
  const marker = '-question-';
  final pos = elicitationId.lastIndexOf('-');
  final markerPos = elicitationId.indexOf(marker);
  if (markerPos >= 0 && pos > markerPos) {
    return elicitationId.substring(0, pos);
  }
  return elicitationId;
}

ParsedElicitation? _parseElicitationCall(
  Map<String, dynamic> step,
  String trajectoryId,
  int stepIndex,
) {
  final id = _stringValue(step['elicitation_id']);
  if (id.isEmpty) return null;
  final preamble = _mapValue(step['preamble']);
  final request = _mapValue(step['multiple_choice_request']);
  final choices = request['choices'];
  final options = <AskQuestionOption>[];
  if (choices is List) {
    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      if (choice is! Map) continue;
      final label = _stringValue(choice['label']);
      options.add(AskQuestionOption(
        id: label.isEmpty ? '${i + 1}' : label,
        text: extractTextFromContent(choice['display'] ?? const []),
      ));
    }
  }
  return ParsedElicitation(
    elicitationId: id,
    groupKey: extractElicitationGroupKey(id),
    trajectoryId: trajectoryId,
    stepIndex: stepIndex,
    question: AskQuestionEntry(
      question: extractTextFromContent(preamble['content'] ?? const []),
      options: options,
      isMultiSelect: request['allow_multiple_selections'] == true,
    ),
  );
}

/// Translates GAOS `step.start`, `step.delta`, and `step.stop` events into
/// SDK [Step]s, correlating tool calls with their results.
class InteractionsStepAssembler {
  String _rootInteractionId;
  final Map<(String, int), _StepState> _steps = {};
  final Map<String, ToolCall> _pendingCallsById = {};
  final Map<(String, String), Queue<ToolCall>> _pendingCallsByKind = {};
  final Map<String, String> _parentTrajectories = {};

  InteractionsStepAssembler({String rootInteractionId = ''})
      : _rootInteractionId = rootInteractionId;

  /// The root interaction (main trajectory) ID.
  String get rootInteractionId => _rootInteractionId;

  /// Records the root interaction ID when [interactionId] is non-empty.
  void setRootInteractionId(String interactionId) {
    if (interactionId.isNotEmpty) _rootInteractionId = interactionId;
  }

  /// Records the parent of a subagent interaction.
  void recordParentTrajectory(String subInteractionId, String parentId) {
    if (subInteractionId.isNotEmpty && parentId.isNotEmpty) {
      _parentTrajectories[subInteractionId] = parentId;
    }
  }

  ({String trajectoryId, String parentId, int depth}) _resolveTrajectory(
      Map<String, dynamic> event) {
    final subId = _stringValue(event['sub_interaction_id']);
    if (subId.isEmpty || subId == _rootInteractionId) {
      return (trajectoryId: _rootInteractionId, parentId: '', depth: 0);
    }
    final parentId = _parentTrajectories[subId] ?? _rootInteractionId;
    var depth = 1;
    var current = parentId;
    final visited = {subId};
    while (current.isNotEmpty &&
        current != _rootInteractionId &&
        !visited.contains(current) &&
        _parentTrajectories.containsKey(current)) {
      visited.add(current);
      current = _parentTrajectories[current]!;
      depth++;
    }
    return (trajectoryId: subId, parentId: parentId, depth: depth);
  }

  _StepState _store(_StepState state) =>
      _steps[(state.trajectoryId, state.stepIndex)] = state;

  /// Processes a `step.start` event.
  StepAssemblyResult handleStepStart(Map<String, dynamic> event) {
    final traj = _resolveTrajectory(event);
    final index = _intValue(event['index']);
    final stepMap = _mapValue(event['step']);
    final subtype = _stringValue(stepMap['type']);
    final description = _stringValue(stepMap['description']);

    _StepState newState({
      required StepType type,
      StepSource source = StepSource.model,
      StepTarget target = StepTarget.user,
      String content = '',
      String thinking = '',
      List<ToolCall> toolCalls = const [],
      bool isError = false,
      String errorMessage = '',
      bool isToolCallStep = false,
      bool isToolResultStep = false,
    }) =>
        _store(_StepState(
          trajectoryId: traj.trajectoryId,
          parentTrajectoryId: traj.parentId,
          depth: traj.depth,
          stepIndex: index,
          subtype: subtype,
          type: type,
          source: source,
          target: target,
          description: description,
          content: content,
          thinking: thinking,
          toolCalls: toolCalls,
          isError: isError,
          errorMessage: errorMessage,
          isToolCallStep: isToolCallStep,
          isToolResultStep: isToolResultStep,
        ));

    StepAssemblyResult started(
      _StepState state, {
      StepStatus status = StepStatus.active,
      String contentDelta = '',
      String thinkingDelta = '',
      ParsedElicitation? elicitation,
    }) =>
        StepAssemblyResult(
          step: _buildStep(state,
              status: status,
              contentDelta: contentDelta,
              thinkingDelta: thinkingDelta),
          dispatchPre: true,
          trajectoryId: traj.trajectoryId,
          elicitation: elicitation,
        );

    final stepId = interactionsStepId(traj.trajectoryId, index);
    switch (subtype) {
      case 'user_input':
        final text = extractTextFromContent(stepMap['content'] ?? '');
        final state = newState(
          type: text.isEmpty ? StepType.unknown : StepType.textResponse,
          source: StepSource.user,
          content: text,
        );
        return started(state, contentDelta: text);
      case 'thought':
        final thinking = extractTextFromContent(stepMap['summary'] ?? const []);
        final state = newState(type: StepType.thinking, thinking: thinking);
        return started(state, thinkingDelta: thinking);
      case 'model_output':
        final text = extractTextFromContent(stepMap['content'] ?? const []);
        final state = newState(type: StepType.textResponse, content: text);
        return started(state, contentDelta: text);
      case 'elicitation_call':
        final elicitation =
            _parseElicitationCall(stepMap, traj.trajectoryId, index);
        final call = ToolCall(
          name: BuiltinTools.askQuestion.value,
          args: elicitation == null
              ? {}
              : {'question': elicitation.question.question},
          id: elicitation?.elicitationId ?? stepId,
          stepId: stepId,
        );
        _pendingCallsById[call.id!] = call;
        final state = newState(
          type: StepType.toolCall,
          content: description,
          toolCalls: [call],
          isToolCallStep: true,
        );
        return started(state,
            status: StepStatus.waitingForUser, elicitation: elicitation);
      case 'elicitation_result':
        final id = _stringValue(stepMap['elicitation_id']);
        final call = (id.isEmpty ? null : _pendingCallsById.remove(id)) ??
            ToolCall(
              name: BuiltinTools.askQuestion.value,
              args: {},
              id: id.isEmpty ? stepId : id,
              stepId: stepId,
            );
        newState(
          type: StepType.toolCall,
          content: description,
          toolCalls: [call],
          isToolResultStep: true,
        );
        return StepAssemblyResult(trajectoryId: traj.trajectoryId);
    }

    final callKind = _callToResultKind[subtype];
    if (callKind != null) {
      final call = _buildToolCallFromCallStep(
          subtype, stepMap, traj.trajectoryId, index);
      if (call.id?.isNotEmpty ?? false) _pendingCallsById[call.id!] = call;
      _pendingCallsByKind
          .putIfAbsent((traj.trajectoryId, callKind), Queue.new).add(call);
      final state = newState(
        type: StepType.toolCall,
        target: StepTarget.environment,
        content: description,
        toolCalls: [call],
        isToolCallStep: true,
      );
      return started(state);
    }

    if (_resultToCallKind.containsKey(subtype)) {
      final resolved = _resolveToolResultFromResultStep(
          subtype, stepMap, traj.trajectoryId, index);
      newState(
        type: StepType.toolCall,
        target: StepTarget.environment,
        content: resolved.summary.isNotEmpty ? resolved.summary : description,
        toolCalls: [resolved.call],
        isError: resolved.isError,
        errorMessage: resolved.errorMessage,
        isToolResultStep: true,
      );
      return StepAssemblyResult(trajectoryId: traj.trajectoryId);
    }

    final state = newState(
      type: StepType.unknown,
      target: StepTarget.unspecified,
      content: description,
    );
    return started(state);
  }

  /// Processes a `step.delta` event.
  StepAssemblyResult handleStepDelta(Map<String, dynamic> event) {
    final traj = _resolveTrajectory(event);
    final index = _intValue(event['index']);
    final delta = _mapValue(event['delta']);
    final deltaType = _stringValue(delta['type']);
    final isThoughtDelta =
        deltaType == 'raw_thought' || deltaType == 'thought_summary';

    var state = _steps[(traj.trajectoryId, index)];
    final dispatchPre = state == null;
    state ??= _store(_StepState(
      trajectoryId: traj.trajectoryId,
      parentTrajectoryId: traj.parentId,
      depth: traj.depth,
      stepIndex: index,
      subtype: isThoughtDelta ? 'thought' : 'model_output',
      type: isThoughtDelta ? StepType.thinking : StepType.textResponse,
      source: StepSource.model,
      target: StepTarget.user,
    ));

    if (isThoughtDelta ||
        (state.type == StepType.thinking && deltaType != 'text')) {
      final block = delta['content'];
      final text = _stringValue(block is Map ? block['text'] : delta['text']);
      state.thinking += text;
      return StepAssemblyResult(
        step: _buildStep(state, status: StepStatus.active, thinkingDelta: text),
        dispatchPre: dispatchPre,
        trajectoryId: traj.trajectoryId,
      );
    }

    final text = _stringValue(delta['text']);
    state.content += text;
    if (state.type == StepType.unknown && state.content.isNotEmpty) {
      state.type = StepType.textResponse;
    }
    return StepAssemblyResult(
      step: _buildStep(state, status: StepStatus.active, contentDelta: text),
      dispatchPre: dispatchPre,
      trajectoryId: traj.trajectoryId,
    );
  }

  /// Processes a `step.stop` event.
  StepAssemblyResult handleStepStop(Map<String, dynamic> event) {
    final traj = _resolveTrajectory(event);
    final index = _intValue(event['index']);
    final usage = parseInteractionUsage(event['usage']);
    final state = _steps[(traj.trajectoryId, index)] ??
        _StepState(
          trajectoryId: traj.trajectoryId,
          parentTrajectoryId: traj.parentId,
          depth: traj.depth,
          stepIndex: index,
          subtype: 'model_output',
          type: StepType.unknown,
          source: StepSource.model,
          target: StepTarget.user,
        );

    // A *_call step starts and stops together when the call is issued; its
    // completion arrives later as a separate *_result step, so the stop of the
    // call step itself is not emitted again.
    if (state.isToolCallStep) {
      return StepAssemblyResult(
          stepUsage: usage, trajectoryId: traj.trajectoryId);
    }

    if (state.subtype == 'model_output' &&
        state.content.isEmpty &&
        !state.isError) {
      state.type = StepType.unknown;
    }
    return StepAssemblyResult(
      step: _buildStep(state,
          status: state.isError ? StepStatus.error : StepStatus.done),
      dispatchPost: true,
      stepUsage: usage,
      trajectoryId: traj.trajectoryId,
    );
  }

  Step _buildStep(
    _StepState state, {
    required StepStatus status,
    String contentDelta = '',
    String thinkingDelta = '',
  }) {
    return Step(
      id: interactionsStepId(state.trajectoryId, state.stepIndex),
      stepIndex: state.stepIndex,
      trajectoryId: state.trajectoryId,
      parentTrajectoryId: state.parentTrajectoryId,
      depth: state.depth,
      type: state.type,
      source: state.source,
      target: state.target,
      status: status,
      content: state.content,
      contentDelta: contentDelta,
      thinking: state.thinking,
      thinkingDelta: thinkingDelta,
      toolCalls: List.of(state.toolCalls),
      error: state.errorMessage,
      isCompleteResponse: state.source == StepSource.model &&
          status == StepStatus.done &&
          state.content.isNotEmpty &&
          state.target == StepTarget.user &&
          state.type == StepType.textResponse,
    );
  }

  ToolCall _buildToolCallFromCallStep(
    String subtype,
    Map<String, dynamic> stepMap,
    String trajectoryId,
    int index,
  ) {
    final stepId = interactionsStepId(trajectoryId, index);
    final callId = _stringValue(stepMap['id']);
    final kind = _callToResultKind[subtype] ?? subtype;
    final name = _stringValue(stepMap['name']);
    final serverName = _stringValue(stepMap['server_name']);

    // Keep every non-envelope field, then merge nested `arguments`, so new
    // proto fields survive without per-field enumeration.
    final rawArgs = <String, dynamic>{
      for (final entry in stepMap.entries)
        if (!_callStepEnvelopeKeys.contains(entry.key))
          entry.key: entry.value is List ? List.of(entry.value) : entry.value,
      ..._mapValue(stepMap['arguments']),
    };

    switch (subtype) {
      case 'code_execution_call':
        final code = rawArgs.remove('code') ?? '';
        rawArgs.putIfAbsent('command_line', () => code);
        rawArgs.putIfAbsent('language', () => 'bash');
      case 'google_search_call':
        final queries = _listValue(rawArgs['queries']);
        rawArgs['queries'] = queries;
        rawArgs.putIfAbsent('query', () => queries.firstOrNull ?? '');
      case 'url_context_call':
        final urls = _listValue(rawArgs['urls']);
        rawArgs['urls'] = urls;
        rawArgs.putIfAbsent('url', () => urls.firstOrNull ?? '');
      case 'skill_lookup_call':
        rawArgs.putIfAbsent('operation', () => '');
        rawArgs['requested_skill_names'] =
            _listValue(rawArgs['requested_skill_names']);
    }

    final normalized = _normalizeToolArgs(rawArgs);
    return ToolCall(
      name: name.isNotEmpty
          ? name
          : (_resultKindDefaultToolName[kind] ?? subtype),
      args: normalized.args,
      id: callId.isNotEmpty ? callId : stepId,
      stepId: stepId,
      canonicalPath: normalized.canonicalPath,
      serverName: serverName.isEmpty ? null : serverName,
    );
  }

  ({ToolCall call, bool isError, String errorMessage, String summary})
      _resolveToolResultFromResultStep(
    String subtype,
    Map<String, dynamic> stepMap,
    String trajectoryId,
    int index,
  ) {
    final kind = _resultToCallKind[subtype]!;
    final callId = _stringValue(stepMap['call_id']);
    final queue = _pendingCallsByKind[(trajectoryId, kind)];
    ToolCall? matched;
    if (callId.isNotEmpty && _pendingCallsById.containsKey(callId)) {
      matched = _pendingCallsById.remove(callId);
      queue?.remove(matched);
    } else if (queue != null && queue.isNotEmpty) {
      matched = queue.removeFirst();
      if (matched.id != null) _pendingCallsById.remove(matched.id);
    }

    if (matched == null) {
      final stepId = interactionsStepId(trajectoryId, index);
      final name = _stringValue(stepMap['name']);
      final serverName = _stringValue(stepMap['server_name']);
      matched = ToolCall(
        name: name.isNotEmpty
            ? name
            : (_resultKindDefaultToolName[kind] ?? subtype),
        args: {},
        id: callId.isNotEmpty ? callId : stepId,
        stepId: stepId,
        serverName: serverName.isEmpty ? null : serverName,
      );
    }

    var isError = stepMap['is_error'] == true;
    var errorMessage = '';
    var summary = '';
    switch (subtype) {
      case 'function_result':
        final result = stepMap['result'];
        if (isError) {
          errorMessage =
              result == null ? 'Tool execution failed' : result.toString();
        } else if (result is String) {
          summary = result;
        }
      case 'code_execution_result':
        final output = _stringValue(stepMap['result']);
        summary = output;
        if (isError) {
          errorMessage = output.isNotEmpty
              ? output
              : 'Command failed with exit code ${stepMap['exit_code']}';
        }
      case 'generate_image_result':
        // generate_image splits its inputs across the call step (prompt,
        // image_paths) and the result step (image_name, aspect_ratio).
        final args = Map<String, dynamic>.from(matched.args);
        for (final entry in stepMap.entries) {
          if (!_resultStepEnvelopeKeys.contains(entry.key)) {
            args[entry.key] = entry.value;
          }
        }
        final normalized = _normalizeToolArgs(args);
        matched = matched.copyWith(
          args: normalized.args,
          canonicalPath: normalized.canonicalPath ?? matched.canonicalPath,
        );
      case 'google_search_result':
        final results = stepMap['result'];
        summary = [
          if (results is List)
            for (final r in results)
              if (r is Map && _stringValue(r['search_suggestions']).isNotEmpty)
                _stringValue(r['search_suggestions']),
        ].join('\n');
        if (isError) {
          errorMessage = summary.isNotEmpty ? summary : 'Web search failed';
        }
      case 'url_context_result':
        if (isError) errorMessage = 'Reading URL content failed';
      case 'skill_lookup_result':
        final error = _stringValue(stepMap['error_message']);
        if (error.isNotEmpty) {
          isError = true;
          errorMessage = error;
        }
    }
    return (
      call: matched,
      isError: isError,
      errorMessage: errorMessage,
      summary: summary,
    );
  }
}
