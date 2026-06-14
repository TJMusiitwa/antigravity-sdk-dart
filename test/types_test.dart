import 'dart:convert';

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // ToolCall
  // ---------------------------------------------------------------------------
  group('ToolCall', () {
    test('constructs with required name and defaults', () {
      final tc = ToolCall(name: 'view_file');
      expect(tc.name, equals('view_file'));
      expect(tc.args, isEmpty);
      expect(tc.id, isNull);
      expect(tc.canonicalPath, isNull);
    });

    test('constructs with all fields', () {
      final tc = ToolCall(
        name: 'create_file',
        args: {'path': '/tmp/x', 'content': 'hello'},
        id: 'call-1',
        canonicalPath: '/tmp/x',
      );
      expect(tc.id, equals('call-1'));
      expect(tc.args['path'], equals('/tmp/x'));
      expect(tc.canonicalPath, equals('/tmp/x'));
    });

    test('toJson includes name and arguments_json', () {
      final tc = ToolCall(name: 'run_command', args: {'cmd': 'ls'});
      final json = tc.toMap();
      expect(json['name'], equals('run_command'));
      expect(json['arguments_json'], isNotNull);
      final decoded = jsonDecode(json['arguments_json'] as String);
      expect(decoded['cmd'], equals('ls'));
    });

    test('toJson includes id when provided', () {
      final tc = ToolCall(name: 'view_file', id: 'abc');
      final json = tc.toMap();
      expect(json['id'], equals('abc'));
    });

    test('fromJson parses arguments_json string', () {
      final map = {
        'name': 'view_file',
        'id': '123',
        'arguments_json': '{"path": "/tmp/f"}',
        'canonical_path': '/tmp/f',
      };
      final tc = ToolCall.fromMap(map);
      expect(tc.name, equals('view_file'));
      expect(tc.id, equals('123'));
      expect(tc.args['path'], equals('/tmp/f'));
      expect(tc.canonicalPath, equals('/tmp/f'));
    });

    test('fromJson parses arguments map (legacy format)', () {
      final map = {
        'name': 'create_file',
        'arguments': {'path': '/out.dart'},
      };
      final tc = ToolCall.fromMap(map);
      expect(tc.args['path'], equals('/out.dart'));
    });

    test('fromJson handles malformed arguments_json gracefully', () {
      final map = {'name': 'view_file', 'arguments_json': '{invalid json}'};
      final tc = ToolCall.fromMap(map);
      expect(tc.args, isEmpty);
    });

    test('fromJson handles missing name with empty string', () {
      final tc = ToolCall.fromMap({'id': 'x'});
      expect(tc.name, equals(''));
    });

    test('fromJson handles missing canonical_path as null', () {
      final tc = ToolCall.fromMap({'name': 'view_file'});
      expect(tc.canonicalPath, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // ToolResult
  // ---------------------------------------------------------------------------
  group('ToolResult', () {
    test('constructs with result', () {
      final tr = ToolResult(name: 'view_file', result: 'file content');
      expect(tr.name, equals('view_file'));
      expect(tr.result, equals('file content'));
      expect(tr.error, isNull);
    });

    test('constructs with error', () {
      final tr = ToolResult(name: 'run_command', error: 'permission denied');
      expect(tr.error, equals('permission denied'));
    });

    test('toJson returns error map when error is set', () {
      final tr = ToolResult(name: 'run_command', id: 't1', error: 'oops');
      final json = tr.toMap();
      expect(json['error'], equals('oops'));
      expect(json.containsKey('result'), isFalse);
    });

    test('toJson returns result map when no error', () {
      final tr = ToolResult(name: 'view_file', id: 't2', result: 'data');
      final json = tr.toMap();
      expect(json['result'], equals('data'));
      expect(json.containsKey('error'), isFalse);
    });

    test('toJson includes id and name', () {
      final tr = ToolResult(name: 'finish', id: 'fin-1', result: null);
      final json = tr.toMap();
      expect(json['id'], equals('fin-1'));
      expect(json['name'], equals('finish'));
    });
  });

  // ---------------------------------------------------------------------------
  // Step & StepType / StepSource / StepTarget / StepStatus enums
  // ---------------------------------------------------------------------------
  group('StepType.fromString()', () {
    test('parses known value strings', () {
      expect(
        StepType.fromString('TEXT_RESPONSE'),
        equals(StepType.textResponse),
      );
      expect(StepType.fromString('TOOL_CALL'), equals(StepType.toolCall));
      expect(
        StepType.fromString('SYSTEM_MESSAGE'),
        equals(StepType.systemMessage),
      );
      expect(StepType.fromString('COMPACTION'), equals(StepType.compaction));
      expect(StepType.fromString('FINISH'), equals(StepType.finish));
      expect(StepType.fromString('UNKNOWN'), equals(StepType.unknown));
    });

    test('parses by enum name (lowercase)', () {
      expect(
        StepType.fromString('textResponse'),
        equals(StepType.textResponse),
      );
      expect(StepType.fromString('toolCall'), equals(StepType.toolCall));
    });

    test('falls back to unknown for unrecognised string', () {
      expect(StepType.fromString('garbage'), equals(StepType.unknown));
      expect(StepType.fromString(''), equals(StepType.unknown));
    });
  });

  group('StepSource.fromString()', () {
    test('parses all known values', () {
      expect(StepSource.fromString('SYSTEM'), equals(StepSource.system));
      expect(StepSource.fromString('USER'), equals(StepSource.user));
      expect(StepSource.fromString('MODEL'), equals(StepSource.model));
      expect(StepSource.fromString('UNKNOWN'), equals(StepSource.unknown));
    });

    test('falls back to unknown', () {
      expect(StepSource.fromString('alien'), equals(StepSource.unknown));
    });
  });

  group('StepTarget.fromString()', () {
    test('parses all known values', () {
      expect(StepTarget.fromString('TARGET_USER'), equals(StepTarget.user));
      expect(
        StepTarget.fromString('TARGET_ENVIRONMENT'),
        equals(StepTarget.environment),
      );
      expect(
        StepTarget.fromString('TARGET_UNSPECIFIED'),
        equals(StepTarget.unspecified),
      );
    });

    test('falls back to unknown', () {
      expect(StepTarget.fromString('bogus'), equals(StepTarget.unknown));
    });
  });

  group('StepStatus.fromString()', () {
    test('parses all known values', () {
      expect(StepStatus.fromString('ACTIVE'), equals(StepStatus.active));
      expect(StepStatus.fromString('DONE'), equals(StepStatus.done));
      expect(
        StepStatus.fromString('WAITING_FOR_USER'),
        equals(StepStatus.waitingForUser),
      );
      expect(StepStatus.fromString('ERROR'), equals(StepStatus.error));
      expect(StepStatus.fromString('CANCELED'), equals(StepStatus.canceled));
    });

    test('falls back to unknown for empty string', () {
      expect(StepStatus.fromString(''), equals(StepStatus.unknown));
    });
  });

  group('Step.fromMap()', () {
    Map<String, dynamic> base() => {
      'id': 'step-1',
      'step_index': 5,
      'cascade_id': 'cascade-a',
      'trajectory_id': 'traj-b',
      'type': 'TEXT_RESPONSE',
      'source': 'MODEL',
      'target': 'TARGET_USER',
      'status': 'DONE',
      'content': 'hello world',
      'content_delta': ' world',
      'thinking': 'think',
      'thinking_delta': 'k',
      'tool_calls': [],
      'error': '',
      'is_complete_response': true,
    };

    test('parses a complete step correctly', () {
      final step = Step.fromMap(base());
      expect(step.id, equals('step-1'));
      expect(step.stepIndex, equals(5));
      expect(step.type, equals(StepType.textResponse));
      expect(step.source, equals(StepSource.model));
      expect(step.target, equals(StepTarget.user));
      expect(step.status, equals(StepStatus.done));
      expect(step.content, equals('hello world'));
      expect(step.contentDelta, equals(' world'));
      expect(step.thinking, equals('think'));
      expect(step.thinkingDelta, equals('k'));
      expect(step.isCompleteResponse, isTrue);
    });

    test('parses nested tool_calls list', () {
      final json = base()
        ..['tool_calls'] = [
          {'name': 'view_file', 'arguments_json': '{"path": "/x"}'},
        ];
      final step = Step.fromMap(json);
      expect(step.toolCalls.length, equals(1));
      expect(step.toolCalls[0].name, equals('view_file'));
    });

    test('uses text_delta as fallback for content_delta', () {
      final json = base()
        ..remove('content_delta')
        ..['text_delta'] = 'delta_fallback';
      final step = Step.fromMap(json);
      expect(step.contentDelta, equals('delta_fallback'));
    });

    test('uses error_message as fallback for error field', () {
      final json = base()
        ..remove('error')
        ..['error_message'] = 'fallback error';
      final step = Step.fromMap(json);
      expect(step.error, equals('fallback error'));
    });

    test('uses defaults for missing fields', () {
      final step = Step.fromMap({});
      expect(step.id, equals(''));
      expect(step.stepIndex, equals(0));
      expect(step.type, equals(StepType.unknown));
      expect(step.toolCalls, isEmpty);
      expect(step.content, equals(''));
      expect(step.usageMetadata, isNull);
    });

    test('parses usage_metadata when present', () {
      final json = base()
        ..['usage_metadata'] = {
          'prompt_token_count': 10,
          'total_token_count': 25,
        };
      final step = Step.fromMap(json);
      expect(step.usageMetadata, isNotNull);
      expect(step.usageMetadata!.promptTokenCount, equals(10));
      expect(step.usageMetadata!.totalTokenCount, equals(25));
    });

    test('parses protobuf state, source, and text formats correctly', () {
      final protoJson = {
        'trajectory_id': 'traj-123',
        'step_index': 1,
        'state': 'STATE_DONE',
        'source': 'SOURCE_MODEL',
        'target': 'TARGET_USER',
        'text': 'Hello from protobuf',
      };
      final step = Step.fromMap(protoJson);
      expect(step.status, equals(StepStatus.done));
      expect(step.source, equals(StepSource.model));
      expect(step.content, equals('Hello from protobuf'));
      expect(step.type, equals(StepType.textResponse));
    });

    test('extracts nested error_message from error map correctly', () {
      final protoJson = {
        'error': {'error_message': 'API rate limit exceeded', 'http_code': 429},
      };
      final step = Step.fromMap(protoJson);
      expect(step.error, equals('API rate limit exceeded'));
    });

    test('parses tool calls from individual proto fields correctly', () {
      final protoJson = {
        'trajectory_id': 'traj-456',
        'step_index': 2,
        'run_command': {'command': 'git status'},
      };
      final step = Step.fromMap(protoJson);
      expect(step.type, equals(StepType.toolCall));
      expect(step.toolCalls.length, equals(1));
      final call = step.toolCalls[0];
      expect(call.name, equals('run_command'));
      expect(call.id, equals('traj-456:2'));
      expect(call.args['command'], equals('git status'));
    });
  });

  group('UsageMetadata.fromMap()', () {
    test('parses all fields', () {
      final meta = UsageMetadata.fromMap({
        'prompt_token_count': 5,
        'cached_content_token_count': 2,
        'candidates_token_count': 10,
        'thoughts_token_count': 3,
        'total_token_count': 20,
      });
      expect(meta.promptTokenCount, equals(5));
      expect(meta.cachedContentTokenCount, equals(2));
      expect(meta.candidatesTokenCount, equals(10));
      expect(meta.thoughtsTokenCount, equals(3));
      expect(meta.totalTokenCount, equals(20));
    });

    test('returns nulls for missing fields', () {
      final meta = UsageMetadata.fromMap({});
      expect(meta.promptTokenCount, isNull);
      expect(meta.totalTokenCount, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CapabilitiesConfig
  // ---------------------------------------------------------------------------
  group('CapabilitiesConfig', () {
    test('constructs with defaults', () {
      final config = CapabilitiesConfig();
      expect(config.enableSubagents, isTrue);
      expect(config.enabledTools, isNull);
      expect(config.disabledTools, isNull);
      expect(config.compactionThreshold, isNull);
    });

    test('throws when both enabledTools and disabledTools are provided', () {
      expect(
        () => CapabilitiesConfig(
          enabledTools: [BuiltinTools.viewFile],
          disabledTools: [BuiltinTools.runCommand],
        ),
        throwsA(isA<AntigravityValidationException>()),
      );
    });

    test('allows enabledTools without disabledTools', () {
      final config = CapabilitiesConfig(
        enabledTools: [BuiltinTools.viewFile, BuiltinTools.finish],
      );
      expect(config.enabledTools, isNotNull);
    });

    test('allows disabledTools without enabledTools', () {
      final config = CapabilitiesConfig(
        disabledTools: [BuiltinTools.runCommand],
      );
      expect(config.disabledTools, isNotNull);
    });

    test('toJson includes enable_subagents', () {
      final json = CapabilitiesConfig(enableSubagents: false).toMap();
      expect(json['enable_subagents'], isFalse);
    });

    test('toJson includes enabled_tools when provided', () {
      final json = CapabilitiesConfig(
        enabledTools: [BuiltinTools.viewFile],
      ).toMap();
      expect(json['enabled_tools'], equals(['view_file']));
    });

    test('toJson includes compaction_threshold when set', () {
      final json = CapabilitiesConfig(compactionThreshold: 8000).toMap();
      expect(json['compaction_threshold'], equals(8000));
    });
  });

  // ---------------------------------------------------------------------------
  // BuiltinTools
  // ---------------------------------------------------------------------------
  group('BuiltinTools', () {
    test('readOnly() contains expected tools', () {
      final ro = BuiltinTools.readOnly().map((t) => t.value).toSet();
      expect(ro, containsAll(['list_directory', 'view_file', 'finish']));
      expect(ro.contains('run_command'), isFalse);
    });

    test('fileTools() contains view, create, edit file', () {
      final ft = BuiltinTools.fileTools().map((t) => t.value).toSet();
      expect(ft, containsAll(['view_file', 'create_file', 'edit_file']));
    });

    test('allTools() contains all enum values', () {
      expect(
        BuiltinTools.allTools().length,
        equals(BuiltinTools.values.length),
      );
    });

    test('nondestructive() does not include run_command', () {
      final nd = BuiltinTools.nondestructive().map((t) => t.value);
      expect(nd.contains('run_command'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Config types
  // ---------------------------------------------------------------------------
  group('ThinkingLevel.fromString()', () {
    test('parses known levels', () {
      expect(
        ThinkingLevel.fromString('minimal'),
        equals(ThinkingLevel.minimal),
      );
      expect(ThinkingLevel.fromString('low'), equals(ThinkingLevel.low));
      expect(ThinkingLevel.fromString('medium'), equals(ThinkingLevel.medium));
      expect(ThinkingLevel.fromString('high'), equals(ThinkingLevel.high));
    });

    test('defaults to minimal for unknown string', () {
      expect(ThinkingLevel.fromString('ultra'), equals(ThinkingLevel.minimal));
      expect(ThinkingLevel.fromString(''), equals(ThinkingLevel.minimal));
    });
  });

  group('GenerationConfig', () {
    test('toJson is empty map when no thinking level', () {
      final json = GenerationConfig().toMap();
      expect(json, isEmpty);
    });

    test('toJson includes thinking_level when set', () {
      final json = GenerationConfig(thinkingLevel: ThinkingLevel.high).toMap();
      expect(json['thinking_level'], equals('high'));
    });
  });

  group('ModelEntry', () {
    test('constructs with defaults', () {
      final entry = ModelEntry(name: 'gemini-3.5-flash');
      expect(entry.name, equals('gemini-3.5-flash'));
      expect(entry.apiKey, isNull);
    });

    test('toJson includes api_key when set', () {
      final json = ModelEntry(name: 'gemini', apiKey: 'key123').toMap();
      expect(json['api_key'], equals('key123'));
    });

    test('toJson omits api_key when null', () {
      final json = ModelEntry(name: 'gemini').toMap();
      expect(json.containsKey('api_key'), isFalse);
    });
  });

  group('ModelConfig', () {
    test('uses sensible defaults', () {
      final config = ModelConfig();
      expect(config.defaultModelEntry.name, equals('gemini-3.5-flash'));
    });

    test('toJson contains default and image_generation keys', () {
      final json = ModelConfig().toMap();
      expect(json.containsKey('default'), isTrue);
      expect(json.containsKey('image_generation'), isTrue);
    });
  });

  group('GeminiConfig', () {
    test('toJson includes api_key when provided', () {
      final json = GeminiConfig(apiKey: 'MY_KEY').toMap();
      expect(json['api_key'], equals('MY_KEY'));
    });

    test('toJson omits api_key when not set', () {
      final json = GeminiConfig().toMap();
      expect(json.containsKey('api_key'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // SystemInstructions
  // ---------------------------------------------------------------------------
  group('SystemInstructionSection', () {
    test('toJson includes content and title', () {
      final section = SystemInstructionSection(
        content: 'Be helpful.',
        title: 'persona',
      );
      final json = section.toMap();
      expect(json['content'], equals('Be helpful.'));
      expect(json['title'], equals('persona'));
    });

    test('uses default title when not specified', () {
      final section = SystemInstructionSection(content: 'text');
      expect(section.title, equals('user_system_instructions'));
    });
  });

  group('CustomSystemInstructions', () {
    test('toJson wraps text in custom.part structure', () {
      final si = CustomSystemInstructions(text: 'You are an agent.');
      final json = si.toMap();
      final custom = json['custom'] as Map;
      final parts = custom['part'] as List;
      expect(parts.first['text'], equals('You are an agent.'));
    });
  });

  group('TemplatedSystemInstructions', () {
    test('toJson with identity and sections', () {
      final si = TemplatedSystemInstructions(
        identity: 'MyBot',
        sections: [
          SystemInstructionSection(content: 'Extra rules', title: 'rules'),
        ],
      );
      final json = si.toMap();
      final appended = json['appended'] as Map;
      expect(appended['custom_identity'], equals('MyBot'));
      final sections = appended['appended_sections'] as List;
      expect(sections.length, equals(1));
      expect(sections[0]['title'], equals('rules'));
    });

    test('toJson omits custom_identity when null', () {
      final si = TemplatedSystemInstructions(sections: []);
      final json = si.toMap();
      final appended = json['appended'] as Map;
      expect(appended.containsKey('custom_identity'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // MCP config types
  // ---------------------------------------------------------------------------
  group('McpStdioServer', () {
    test('type is stdio', () {
      final server = McpStdioServer(
        name: 'node-server',
        command: 'node',
        args: ['server.js'],
      );
      expect(server.type, equals('stdio'));
    });

    test('toJson includes command, args, and type', () {
      final json = McpStdioServer(
        name: 'py-server',
        command: 'python3',
        args: ['-m', 'mcp_server'],
      ).toMap();
      expect(json['name'], equals('py-server'));
      expect(json['command'], equals('python3'));
      expect(json['args'], equals(['-m', 'mcp_server']));
      expect(json['type'], equals('stdio'));
    });

    test('defaults args to empty list', () {
      final server = McpStdioServer(name: 'bin-server', command: 'binary');
      expect(server.args, isEmpty);
    });
  });

  group('McpStreamableHttpServer', () {
    test('type is http', () {
      final server = McpStreamableHttpServer(
        name: 'http-server',
        url: 'http://localhost:8080/mcp',
      );
      expect(server.type, equals('http'));
    });

    test('toJson includes url and type', () {
      final json = McpStreamableHttpServer(
        name: 'http-server',
        url: 'http://localhost:9000/mcp',
      ).toMap();
      expect(json['url'], equals('http://localhost:9000/mcp'));
      expect(json['type'], equals('http'));
    });

    test('defaults timeout and terminateOnClose', () {
      final server = McpStreamableHttpServer(
        name: 'http-server',
        url: 'http://localhost/mcp',
      );
      expect(server.timeout, equals(30.0));
      expect(server.sseReadTimeout, equals(300.0));
      expect(server.terminateOnClose, isTrue);
    });

    test('toJson includes timeout fields', () {
      final json = McpStreamableHttpServer(
        name: 'http-server',
        url: 'http://localhost/mcp',
        timeout: 60.0,
        sseReadTimeout: 120.0,
        terminateOnClose: false,
      ).toMap();
      expect(json['timeout'], equals(60.0));
      expect(json['sse_read_timeout'], equals(120.0));
      expect(json['terminate_on_close'], isFalse);
    });

    test('toJson omits headers when null', () {
      final json = McpStreamableHttpServer(
        name: 'http-server',
        url: 'http://localhost/mcp',
      ).toMap();
      expect(json.containsKey('headers'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // FileChange types
  // ---------------------------------------------------------------------------
  group('FileChange', () {
    test('stores kind and path', () {
      final fc = FileChange(kind: FileChangeKind.added, path: '/tmp/new.dart');
      expect(fc.kind, equals(FileChangeKind.added));
      expect(fc.path, equals('/tmp/new.dart'));
    });

    test('FileChangeKind.modified has correct value', () {
      expect(FileChangeKind.modified.value, equals('modified'));
    });

    test('FileChangeKind.deleted has correct value', () {
      expect(FileChangeKind.deleted.value, equals('deleted'));
    });
  });

  // ---------------------------------------------------------------------------
  // Exception types
  // ---------------------------------------------------------------------------
  group('AntigravityConnectionException', () {
    test('toString includes class name and message', () {
      final ex = AntigravityConnectionException('conn failed');
      expect(ex.toString(), contains('AntigravityConnectionException'));
      expect(ex.toString(), contains('conn failed'));
    });

    test('implements Exception', () {
      expect(AntigravityConnectionException('err'), isA<Exception>());
    });
  });

  group('AntigravityValidationException', () {
    test('toString includes class name and message', () {
      final ex = AntigravityValidationException('invalid config');
      expect(ex.toString(), contains('AntigravityValidationException'));
      expect(ex.toString(), contains('invalid config'));
    });

    test('implements Exception', () {
      expect(AntigravityValidationException('err'), isA<Exception>());
    });
  });

  // ---------------------------------------------------------------------------
  // Interaction types
  // ---------------------------------------------------------------------------
  group('HookResult', () {
    test('defaults allow to true and message to empty', () {
      final r = HookResult();
      expect(r.allow, isTrue);
      expect(r.message, isEmpty);
    });

    test('accepts custom values', () {
      final r = HookResult(allow: false, message: 'blocked');
      expect(r.allow, isFalse);
      expect(r.message, equals('blocked'));
    });
  });

  group('QuestionResponse', () {
    test('constructs with defaults', () {
      final qr = QuestionResponse();
      expect(qr.freeformResponse, isEmpty);
      expect(qr.skipped, isFalse);
      expect(qr.selectedOptionIds, isNull);
    });

    test('stores selectedOptionIds and freeform', () {
      final qr = QuestionResponse(
        selectedOptionIds: ['opt1', 'opt2'],
        freeformResponse: 'custom',
        skipped: true,
      );
      expect(qr.selectedOptionIds, equals(['opt1', 'opt2']));
      expect(qr.freeformResponse, equals('custom'));
      expect(qr.skipped, isTrue);
    });
  });

  group('AskQuestionEntry', () {
    test('constructs with options and defaults isMultiSelect to false', () {
      final entry = AskQuestionEntry(
        question: 'What do you prefer?',
        options: [
          AskQuestionOption(id: 'a', text: 'Option A'),
          AskQuestionOption(id: 'b', text: 'Option B'),
        ],
      );
      expect(entry.question, equals('What do you prefer?'));
      expect(entry.options.length, equals(2));
      expect(entry.isMultiSelect, isFalse);
    });

    test('allows isMultiSelect = true', () {
      final entry = AskQuestionEntry(
        question: 'Select all that apply',
        options: [],
        isMultiSelect: true,
      );
      expect(entry.isMultiSelect, isTrue);
    });
  });

  group('AskQuestionInteractionSpec', () {
    test('stores list of questions', () {
      final spec = AskQuestionInteractionSpec(
        questions: [
          AskQuestionEntry(question: 'Q1?', options: []),
          AskQuestionEntry(question: 'Q2?', options: []),
        ],
      );
      expect(spec.questions.length, equals(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Chunk types
  // ---------------------------------------------------------------------------
  group('StreamChunk subtypes', () {
    test('Text stores stepIndex and text', () {
      final chunk = Text(stepIndex: 3, text: 'hello');
      expect(chunk.stepIndex, equals(3));
      expect(chunk.text, equals('hello'));
    });

    test('Thought stores stepIndex, text, and optional signature', () {
      final chunk = Thought(stepIndex: 1, text: 'thinking', signature: [1, 2]);
      expect(chunk.text, equals('thinking'));
      expect(chunk.signature, equals([1, 2]));
    });

    test('Thought signature is nullable', () {
      final chunk = Thought(stepIndex: 0, text: 'think');
      expect(chunk.signature, isNull);
    });
  });
}
