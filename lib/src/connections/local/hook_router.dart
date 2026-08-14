import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../../hooks/hooks.dart';
import '../../types.dart';

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
    if (parts == null || parts.isEmpty) {
      return '';
    }

    final List<dynamic> contentList = [];
    for (final part in parts) {
      if (part is Map) {
        if (part.containsKey('text')) {
          contentList.add(part['text'].toString());
        } else if (part.containsKey('slash_command')) {
          final sc = part['slash_command'];
          if (sc is Map && sc.containsKey('name')) {
            final scNameStr = sc['name'].toString();
            final scName = BuiltinSlashCommandName.values.firstWhere(
              (e) => e.value == scNameStr,
              orElse: () => BuiltinSlashCommandName.plan,
            );
            contentList.add(SlashCommand(name: scName));
          }
        } else if (part.containsKey('media')) {
          final media = part['media'];
          if (media is Map &&
              media.containsKey('mime_type') &&
              media.containsKey('data')) {
            final mimeType = media['mime_type'].toString();
            final dataBase64 = media['data'].toString();
            final data = base64Decode(dataBase64);
            final description = media['description']?.toString() ?? '';
            try {
              contentList.add(MediaContent.fromBytes(
                data,
                mimeType,
                description: description,
              ));
            } catch (_) {}
          }
        }
      }
    }

    if (contentList.isEmpty) {
      return '';
    }
    if (contentList.length == 1) {
      return contentList[0];
    }
    return contentList;
  }

  Future<void> handle(Map<String, dynamic> req) async {
    final requestId = req['request_id']?.toString() ?? '';
    final hookTypeStr = req['type']?.toString() ?? '';

    _logger.fine('Handling hook request: $hookTypeStr ($requestId)');

    final response = <String, dynamic>{
      'request_id': requestId,
    };

    try {
      if (hookTypeStr == 'LIFECYCLE_HOOK_ON_SESSION_START' ||
          hookTypeStr == 'ON_SESSION_START') {
        await _hookRunner.dispatchSessionStart();
        response['empty_result'] = {};
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_ON_SESSION_END' ||
          hookTypeStr == 'ON_SESSION_END') {
        await _hookRunner.dispatchSessionEnd();
        response['empty_result'] = {};
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_PRE_TURN' ||
          hookTypeStr == 'PRE_TURN') {
        Map<String, dynamic>? userInputMap;
        if (req.containsKey('pre_turn_args') && req['pre_turn_args'] is Map) {
          final args = req['pre_turn_args'] as Map;
          if (args.containsKey('user_input') && args['user_input'] is Map) {
            userInputMap = Map<String, dynamic>.from(args['user_input'] as Map);
          }
        }
        final userInput =
            userInputMap != null ? _fromProtoUserInput(userInputMap) : '';
        final res = await _hookRunner.dispatchPreTurn(userInput);
        _currentTurnContext = _hookRunner.currentTurnContext;

        final ptr = <String, dynamic>{};
        if (res.allow) {
          ptr['decision'] = 'ALLOW';
        } else {
          ptr['decision'] = 'DENY';
          ptr['reason'] = res.message;
        }
        response['pre_turn_result'] = ptr;
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_POST_TURN' ||
          hookTypeStr == 'POST_TURN') {
        var responseText = '';
        if (req.containsKey('post_turn_args') && req['post_turn_args'] is Map) {
          final args = req['post_turn_args'] as Map;
          responseText =
              (args['response_text'] ?? args['responseText'] ?? '').toString();
        }
        final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
        await _hookRunner.dispatchPostTurn(turnCtx, responseText);
        _currentTurnContext = null;
        response['empty_result'] = {};
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_PRE_TOOL' ||
          hookTypeStr == 'PRE_TOOL') {
        var toolName = '';
        var args = <String, dynamic>{};
        String? serverName;
        String? callId;

        if (req.containsKey('pre_tool_args') && req['pre_tool_args'] is Map) {
          final pta = req['pre_tool_args'] as Map;
          final rawToolName =
              (pta['tool_name'] ?? pta['toolName'] ?? '').toString();
          toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;

          if (pta.containsKey('arguments_json') &&
              pta['arguments_json'] != null) {
            final argsJson = pta['arguments_json'].toString();
            if (argsJson.isNotEmpty) {
              try {
                final decoded = jsonDecode(argsJson);
                if (decoded is Map) {
                  args = Map<String, dynamic>.from(decoded);
                }
              } catch (_) {}
            }
          } else if (pta.containsKey('arguments') &&
              pta['arguments'] is Map) {
            args = Map<String, dynamic>.from(pta['arguments'] as Map);
          }

          if (pta.containsKey('server_name') && pta['server_name'] != null) {
            serverName = pta['server_name'].toString();
          } else if (pta.containsKey('serverName') &&
              pta['serverName'] != null) {
            serverName = pta['serverName'].toString();
          }

          callId = _extractCallId(pta);
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

        final tc = ToolCall(
          name: toolName,
          args: args,
          id: callId,
          callId: callId,
          serverName: serverName,
          canonicalPath: canonicalPath,
        );

        final turnCtx =
            _currentTurnContext ?? _hookRunner.createTurnContext();
        final res = await _hookRunner.dispatchPreToolCall(turnCtx, tc);

        final ptr = <String, dynamic>{};
        if (res.allow) {
          ptr['decision'] = 'ALLOW';
        } else {
          ptr['decision'] = 'DENY';
          ptr['reason'] = res.message;
        }
        response['pre_tool_result'] = ptr;
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_POST_TOOL' ||
          hookTypeStr == 'POST_TOOL') {
        var toolName = '';
        dynamic resultVal;
        var errorStr = '';
        String? callId;

        if (req.containsKey('post_tool_args') && req['post_tool_args'] is Map) {
          final args = req['post_tool_args'] as Map;
          final rawToolName =
              (args['tool_name'] ?? args['toolName'] ?? '').toString();
          toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;
          callId = _extractCallId(args);

          final hasError =
              args.containsKey('error') && args['error'].toString().isNotEmpty;
          if (hasError) {
            errorStr = args['error'].toString();
          } else {
            resultVal = args['result'];
          }

          if (args.containsKey('step_update') &&
              args['step_update'] is Map &&
              _resultExtractor != null) {
            final stepUpdate =
                Map<String, dynamic>.from(args['step_update'] as Map);
            final extracted = _resultExtractor!(stepUpdate);
            if (extracted != null) {
              resultVal = extracted;
            }
          }
        }

        final toolResult = ToolResult(
          name: toolName,
          callId: callId,
          result: resultVal,
          error: errorStr.isNotEmpty ? errorStr : null,
        );

        final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
        await _hookRunner.dispatchPostToolCall(turnCtx, toolResult);
        response['empty_result'] = {};
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_ON_TOOL_ERROR' ||
          hookTypeStr == 'ON_TOOL_ERROR') {
        var errorStr = 'Unknown tool error';
        var rawToolName = '';
        String? serverName;
        String? callId;
        if (req.containsKey('on_tool_error_args') &&
            req['on_tool_error_args'] is Map) {
          final extracted = _extractToolErrorDetails(
            req['on_tool_error_args'] as Map,
          );
          errorStr = extracted.error;
          rawToolName = extracted.rawToolName;
          serverName = extracted.serverName;
          callId = extracted.callId;
        } else if (req.containsKey('post_tool_args') &&
            req['post_tool_args'] is Map) {
          final extracted = _extractToolErrorDetails(
            req['post_tool_args'] as Map,
          );
          errorStr = extracted.error;
          rawToolName = extracted.rawToolName;
          serverName = extracted.serverName;
          callId = extracted.callId;
        }
        final toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;

        final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
        await _hookRunner.dispatchOnToolError(
          turnCtx,
          ToolExecutionException(
            errorStr,
            toolName: toolName,
            serverName: serverName,
            callId: callId,
          ),
        );
        response['empty_result'] = {};
      } else {
        _logger.warning('Unknown hook received: $hookTypeStr');
        response['empty_result'] = {};
      }
    } catch (e, stackTrace) {
      _logger.severe('Hook execution failed: $e', e, stackTrace);
      response['error_message'] = 'Hook failed: $e';
    }

    await _send({
      'call_hook_response': response,
    });
  }
}

String? _extractCallId(Map args) {
  return (args['call_id'] ?? args['callId'] ?? args['id'])?.toString();
}

/// Extracts error message, raw tool name, optional server name, and optional call ID from hook argument payloads.
({String error, String rawToolName, String? serverName, String? callId})
    _extractToolErrorDetails(Map args) {
  final errorStr = (args['error'] ??
          args['error_message'] ??
          args['errorMessage'] ??
          'Unknown tool error')
      .toString();
  final rawToolName = (args['tool_name'] ?? args['toolName'] ?? '').toString();
  final serverName = (args['server_name'] ?? args['serverName'])?.toString();
  final callId = _extractCallId(args);
  return (
    error: errorStr,
    rawToolName: rawToolName,
    serverName: serverName,
    callId: callId,
  );
}
