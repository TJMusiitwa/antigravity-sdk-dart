import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../../hooks/hooks.dart';
import '../../types.dart';
import 'local_connection_config.dart';

final _logger = Logger('antigravity.connection.local.hook_router');

const _protoFieldToSdkName = {
  'create_file': 'create_file',
  'edit_file': 'edit_file',
  'find_file': 'find_file',
  'list_directory': 'list_directory',
  'run_command': 'run_command',
  'search_directory': 'search_directory',
  'view_file': 'view_file',
  'invoke_subagent': 'start_subagent',
  'generate_image': 'generate_image',
  'search_web': 'search_web',
  'read_url_content': 'read_url_content',
  'finish': 'finish',
};

const _wirePathArgumentKeys = {
  'path',
  'file_path',
  'directory_path',
  'TargetFile',
  'output_path',
};

String normalizeWirePath(String path) {
  final uri = Uri.tryParse(path);
  if (uri != null && uri.hasScheme) {
    if (uri.scheme == 'file') {
      return uri.toFilePath();
    }
    if (uri.scheme == 'cns') {
      return '/cns/${uri.host}${uri.path}';
    }
  }
  return path;
}

void _normalizePathArgs(Map<String, dynamic> args) {
  for (final key in _wirePathArgumentKeys) {
    final val = args[key];
    if (val is String && val.isNotEmpty) {
      args[key] = normalizeWirePath(val);
    }
  }
}

class HookRouter {
  final HookRunner _hookRunner;
  final Future<void> Function(Map<String, dynamic> event) _send;
  final dynamic Function(Map<String, dynamic> stepUpdate)? _resultExtractor;

  TurnContext? _currentTurnContext;

  HookRouter(
    this._hookRunner,
    this._send, {
    dynamic Function(Map<String, dynamic> stepUpdate)? resultExtractor,
  }) : _resultExtractor = resultExtractor;

  TurnContext? get currentTurnContext => _currentTurnContext;

  ContentPrimitive _fromProtoUserInput(Map<String, dynamic> ui) {
    final parts = ui['parts'] as List?;
    if (parts == null || parts.isEmpty) return '';

    final contentList = <dynamic>[];
    for (final part in parts) {
      if (part is! Map) continue;
      final parsed = _parseUserInputPart(part);
      if (parsed != null) {
        contentList.add(parsed);
      }
    }

    if (contentList.isEmpty) return '';
    return contentList.length == 1 ? contentList[0] : contentList;
  }

  dynamic _parseUserInputPart(Map part) {
    if (part.containsKey('text')) {
      return part['text'].toString();
    }
    if (part.containsKey('slash_command')) {
      return _parseSlashCommandPart(part['slash_command']);
    }
    if (part.containsKey('media')) {
      return _parseMediaPart(part['media']);
    }
    return null;
  }

  SlashCommand? _parseSlashCommandPart(dynamic sc) {
    if (sc is! Map || !sc.containsKey('name')) return null;
    final scNameStr = sc['name'].toString();
    final scName = BuiltinSlashCommandName.values.firstWhere(
      (e) => e.value == scNameStr,
      orElse: () => BuiltinSlashCommandName.plan,
    );
    return SlashCommand(name: scName);
  }

  MediaContent? _parseMediaPart(dynamic media) {
    if (media is! Map || !media.containsKey('mime_type') || !media.containsKey('data')) {
      return null;
    }
    final mimeType = media['mime_type'].toString();
    final data = base64Decode(media['data'].toString());
    final description = media['description']?.toString() ?? '';
    try {
      return MediaContent.fromBytes(data, mimeType, description: description);
    } catch (_) {
      return null;
    }
  }

  Future<void> handle(Map<String, dynamic> req) async {
    final requestId = req['request_id']?.toString() ?? '';
    final hookTypeStr = req['type']?.toString() ?? '';
    _logger.fine('Handling hook request: $hookTypeStr ($requestId)');

    final response = <String, dynamic>{'request_id': requestId};

    try {
      await _dispatchHook(hookTypeStr, req, response);
    } catch (e, stackTrace) {
      _logger.severe('Hook execution failed: $e', e, stackTrace);
      response['error_message'] = 'Hook failed: $e';
    }

    await _send({'call_hook_response': response});
  }

  Future<void> _dispatchHook(
    String hookType,
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    switch (hookType) {
      case 'LIFECYCLE_HOOK_ON_SESSION_START' || 'ON_SESSION_START':
        await _hookRunner.dispatchSessionStart();
        response['empty_result'] = {};
      case 'LIFECYCLE_HOOK_ON_SESSION_END' || 'ON_SESSION_END':
        await _hookRunner.dispatchSessionEnd();
        response['empty_result'] = {};
      case 'LIFECYCLE_HOOK_PRE_TURN' || 'PRE_TURN':
        await _handlePreTurn(req, response);
      case 'LIFECYCLE_HOOK_POST_TURN' || 'POST_TURN':
        await _handlePostTurn(req, response);
      case 'LIFECYCLE_HOOK_PRE_TOOL' || 'PRE_TOOL':
        await _handlePreTool(req, response);
      case 'LIFECYCLE_HOOK_POST_TOOL' || 'POST_TOOL':
        await _handlePostTool(req, response);
      case 'LIFECYCLE_HOOK_ON_TOOL_ERROR' || 'ON_TOOL_ERROR':
        await _handleOnToolError(req, response);
      default:
        _logger.warning('Unknown hook received: $hookType');
        response['empty_result'] = {};
    }
  }

  Future<void> _handlePreTurn(
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    Map<String, dynamic>? userInputMap;
    final args = req['pre_turn_args'];
    if (args is Map && args['user_input'] is Map) {
      userInputMap = Map<String, dynamic>.from(args['user_input'] as Map);
    }
    final userInput = userInputMap != null ? _fromProtoUserInput(userInputMap) : '';
    final res = await _hookRunner.dispatchPreTurn(userInput);
    _currentTurnContext = _hookRunner.currentTurnContext;

    final ptr = <String, dynamic>{'decision': res.allow ? 'ALLOW' : 'DENY'};
    if (!res.allow) {
      ptr['reason'] = res.message;
    }
    response['pre_turn_result'] = ptr;
  }

  Future<void> _handlePostTurn(
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    var responseText = '';
    final args = req['post_turn_args'];
    if (args is Map) {
      responseText = (args['response_text'] ?? args['responseText'] ?? '').toString();
    }
    final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
    await _hookRunner.dispatchPostTurn(turnCtx, responseText);
    _currentTurnContext = null;
    response['empty_result'] = {};
  }

  Future<void> _handlePreTool(
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    final toolCall = _parsePreToolCall(req['pre_tool_args']);
    final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
    final res = await _hookRunner.dispatchPreToolCall(turnCtx, toolCall);

    final ptr = <String, dynamic>{'decision': res.allow ? 'ALLOW' : 'DENY'};
    if (res.allow) {
      if (res.modifiedArgs != null) {
        ptr['modified_arguments_json'] = jsonEncode(res.modifiedArgs);
      }
    } else {
      ptr['reason'] = res.message;
    }
    response['pre_tool_result'] = ptr;
  }

  ToolCall _parsePreToolCall(dynamic ptaRaw) {
    var toolName = '';
    var args = <String, dynamic>{};
    String? serverName;
    String? callId;
    String? stepId;

    if (ptaRaw is Map) {
      final pta = ptaRaw;
      final rawToolName = (pta['tool_name'] ?? pta['toolName'] ?? '').toString();
      toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;
      args = _extractToolCallArguments(pta);
      serverName = (pta['server_name'] ?? pta['serverName'])?.toString();
      callId = _extractCallId(pta);
      stepId = _extractStepId(pta);
      _normalizePathArgs(args);
    }

    String? canonicalPath;
    for (final key in _wirePathArgumentKeys) {
      final val = args[key];
      if (val is String && val.isNotEmpty) {
        canonicalPath = val;
        break;
      }
    }

    return ToolCall(
      name: toolName,
      args: args,
      id: callId,
      callId: callId,
      stepId: stepId,
      serverName: serverName,
      canonicalPath: canonicalPath,
    );
  }

  Map<String, dynamic> _extractToolCallArguments(Map pta) {
    if (pta.containsKey('arguments_json') && pta['arguments_json'] != null) {
      final argsJson = pta['arguments_json'].toString();
      if (argsJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(argsJson);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    } else if (pta.containsKey('arguments') && pta['arguments'] is Map) {
      return Map<String, dynamic>.from(pta['arguments'] as Map);
    }
    return <String, dynamic>{};
  }

  Future<void> _handlePostTool(
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    var toolName = '';
    dynamic resultVal;
    var errorStr = '';
    String? callId;
    String? stepId;

    final args = req['post_tool_args'];
    if (args is Map) {
      final rawToolName = (args['tool_name'] ?? args['toolName'] ?? '').toString();
      toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;
      callId = _extractCallId(args);
      stepId = _extractStepId(args);

      final hasError = args.containsKey('error') && args['error'].toString().isNotEmpty;
      if (hasError) {
        errorStr = args['error'].toString();
      } else {
        resultVal = args['result'];
      }

      if (args['step_update'] is Map && _resultExtractor != null) {
        final stepUpdate = Map<String, dynamic>.from(args['step_update'] as Map);
        final extracted = _resultExtractor!(stepUpdate);
        if (extracted != null) {
          resultVal = extracted;
        }
      }
    }

    final toolResult = ToolResult(
      name: toolName,
      callId: callId,
      stepId: stepId,
      result: resultVal,
      error: errorStr.isNotEmpty ? errorStr : null,
    );

    final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
    await _hookRunner.dispatchPostToolCall(turnCtx, toolResult);
    response['empty_result'] = {};
  }

  Future<void> _handleOnToolError(
    Map<String, dynamic> req,
    Map<String, dynamic> response,
  ) async {
    final errorPayload = req['on_tool_error_args'] ?? req['post_tool_args'];
    final extracted = errorPayload is Map
        ? _extractToolErrorDetails(errorPayload)
        : (
            error: 'Unknown tool error',
            rawToolName: '',
            serverName: null,
            callId: null,
            stepId: null,
          );

    final toolName = _protoFieldToSdkName[extracted.rawToolName] ?? extracted.rawToolName;
    final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
    await _hookRunner.dispatchOnToolError(
      turnCtx,
      ToolExecutionException(
        extracted.error,
        toolName: toolName,
        serverName: extracted.serverName,
        callId: extracted.callId,
        stepId: extracted.stepId,
      ),
    );
    response['empty_result'] = {};
  }
}

String? _extractCallId(Map args) {
  return (args['call_id'] ?? args['callId'] ?? args['id'])?.toString();
}

String? _extractStepId(Map args) {
  final traj = args['trajectory_id'] ?? args['trajectoryId'];
  final step = args['step_index'] ?? args['stepIndex'];
  if (traj != null || step != null) {
    return makeStepId(traj, step);
  }
  return (args['step_id'] ?? args['stepId'])?.toString();
}

/// Extracts error message, raw tool name, optional server name, optional call ID, and optional step ID from hook argument payloads.
({
  String error,
  String rawToolName,
  String? serverName,
  String? callId,
  String? stepId
}) _extractToolErrorDetails(Map args) {
  final errorStr = (args['error'] ??
          args['error_message'] ??
          args['errorMessage'] ??
          'Unknown tool error')
      .toString();
  final rawToolName = (args['tool_name'] ?? args['toolName'] ?? '').toString();
  final serverName = (args['server_name'] ?? args['serverName'])?.toString();
  final callId = _extractCallId(args);
  final stepId = _extractStepId(args);
  return (
    error: errorStr,
    rawToolName: rawToolName,
    serverName: serverName,
    callId: callId,
    stepId: stepId,
  );
}
