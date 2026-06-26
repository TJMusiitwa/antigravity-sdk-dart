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
      } else if (hookTypeStr == 'LIFECYCLE_HOOK_POST_TOOL' ||
          hookTypeStr == 'POST_TOOL') {
        var toolName = '';
        dynamic resultVal;
        var errorStr = '';

        if (req.containsKey('post_tool_args') && req['post_tool_args'] is Map) {
          final args = req['post_tool_args'] as Map;
          final rawToolName =
              (args['tool_name'] ?? args['toolName'] ?? '').toString();
          toolName = _protoFieldToSdkName[rawToolName] ?? rawToolName;

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
          result: resultVal,
          error: errorStr.isNotEmpty ? errorStr : null,
        );

        final turnCtx = _currentTurnContext ?? _hookRunner.createTurnContext();
        await _hookRunner.dispatchPostToolCall(turnCtx, toolResult);
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
