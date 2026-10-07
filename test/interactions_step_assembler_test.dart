import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/interactions_step_assembler.dart';
import 'package:test/test.dart';

Map<String, dynamic> _start(int index, Map<String, dynamic> step,
        {String? sub}) =>
    {
      'event_type': 'step.start',
      'index': index,
      'step': step,
      if (sub != null) 'sub_interaction_id': sub,
    };

Map<String, dynamic> _delta(int index, Map<String, dynamic> delta) =>
    {'event_type': 'step.delta', 'index': index, 'delta': delta};

Map<String, dynamic> _stop(int index,
        {Map<String, dynamic>? usage, String? sub}) =>
    {
      'event_type': 'step.stop',
      'index': index,
      if (usage != null) 'usage': usage,
      if (sub != null) 'sub_interaction_id': sub,
    };

void main() {
  late InteractionsStepAssembler assembler;
  setUp(
      () => assembler = InteractionsStepAssembler(rootInteractionId: 'root-1'));

  test('user input step lifecycle', () {
    final start = assembler.handleStepStart(
        _start(0, {'type': 'user_input', 'content': 'Hello agent'}));
    final step = start.step!;
    expect(start.dispatchPre, isTrue);
    expect(start.dispatchPost, isFalse);
    expect(step.id, 'root-1:0');
    expect(step.source, StepSource.user);
    expect(step.target, StepTarget.user);
    expect(step.type, StepType.textResponse);
    expect(step.status, StepStatus.active);
    expect(step.content, 'Hello agent');
    expect(step.contentDelta, 'Hello agent');
    expect(step.isCompleteResponse, isFalse);

    final stop = assembler.handleStepStop(_stop(0));
    expect(stop.dispatchPost, isTrue);
    expect(stop.step!.status, StepStatus.done);
    expect(stop.step!.content, 'Hello agent');
    expect(stop.step!.contentDelta, '');
    expect(stop.step!.isCompleteResponse, isFalse);
  });

  test('thought and model output stream deltas and parse usage', () {
    final thought = assembler.handleStepStart(_start(1, {'type': 'thought'}));
    expect(thought.step!.type, StepType.thinking);
    expect(thought.dispatchPre, isTrue);

    final d1 = assembler.handleStepDelta(_delta(1, {
      'type': 'raw_thought',
      'content': {'type': 'text', 'text': 'Thinking '},
    }));
    expect(d1.step!.thinking, 'Thinking ');
    expect(d1.step!.thinkingDelta, 'Thinking ');
    final d2 = assembler.handleStepDelta(_delta(1, {
      'type': 'raw_thought',
      'content': {'type': 'text', 'text': 'deeply...'},
    }));
    expect(d2.step!.thinking, 'Thinking deeply...');
    expect(d2.step!.thinkingDelta, 'deeply...');
    final thoughtStop = assembler.handleStepStop(_stop(1));
    expect(thoughtStop.step!.status, StepStatus.done);
    expect(thoughtStop.step!.thinkingDelta, '');

    assembler.handleStepStart(_start(2, {'type': 'model_output'}));
    final m1 = assembler
        .handleStepDelta(_delta(2, {'type': 'text', 'text': 'Hello '}));
    expect(m1.step!.isCompleteResponse, isFalse);
    final m2 = assembler
        .handleStepDelta(_delta(2, {'type': 'text', 'text': 'world!'}));
    expect(m2.step!.content, 'Hello world!');
    expect(m2.step!.contentDelta, 'world!');

    final stop = assembler.handleStepStop(_stop(2, usage: {
      'total_input_tokens': 100,
      'total_cached_tokens': 20,
      'total_output_tokens': 30,
      'total_thought_tokens': 10,
      'total_tokens': 140,
    }));
    expect(stop.step!.status, StepStatus.done);
    expect(stop.step!.isCompleteResponse, isTrue);
    expect(stop.stepUsage!.promptTokenCount, 100);
    expect(stop.stepUsage!.cachedContentTokenCount, 20);
    expect(stop.stepUsage!.candidatesTokenCount, 30);
    expect(stop.stepUsage!.thoughtsTokenCount, 10);
    expect(stop.stepUsage!.totalTokenCount, 140);
  });

  test('built-in and custom tool calls pair with their results', () {
    final call = assembler.handleStepStart(_start(1, {
      'type': 'view_file_call',
      'description': 'Viewing file:///tmp/test.py',
      'file_path': 'file:///tmp/test.py',
      'start_line': 1,
      'end_line': 50,
    }));
    final step = call.step!;
    expect(step.type, StepType.toolCall);
    expect(step.status, StepStatus.active);
    expect(step.target, StepTarget.environment);
    final toolCall = step.toolCalls.single;
    expect(toolCall.name, 'view_file');
    expect(toolCall.args,
        {'file_path': '/tmp/test.py', 'start_line': 1, 'end_line': 50});
    expect(toolCall.canonicalPath, '/tmp/test.py');
    expect(assembler.handleStepStop(_stop(1)).step, isNull);

    expect(
        assembler
            .handleStepStart(_start(2, {
              'type': 'view_file_result',
              'description': 'Viewing file:///tmp/test.py',
            }))
            .step,
        isNull);
    final result = assembler.handleStepStop(_stop(2));
    expect(result.dispatchPost, isTrue);
    expect(result.step!.status, StepStatus.done);
    expect(result.step!.toolCalls.single.id, toolCall.id);
    expect(result.step!.isCompleteResponse, isFalse);

    final fnCall = assembler.handleStepStart(_start(3, {
      'type': 'function_call',
      'id': 'call-abc',
      'name': 'custom_op',
      'arguments': {'x': 5},
    }));
    expect(fnCall.step!.toolCalls.single.id, 'call-abc');
    expect(fnCall.step!.toolCalls.single.name, 'custom_op');
    expect(fnCall.step!.toolCalls.single.args, {'x': 5});
    assembler.handleStepStop(_stop(3));
    assembler.handleStepStart(_start(4, {
      'type': 'function_result',
      'call_id': 'call-abc',
      'name': 'custom_op',
      'is_error': true,
      'result': 'Database offline',
    }));
    final fnResult = assembler.handleStepStop(_stop(4));
    expect(fnResult.step!.status, StepStatus.error);
    expect(fnResult.step!.error, 'Database offline');
    expect(fnResult.step!.toolCalls.single.id, 'call-abc');
  });

  test('elicitations and nested subagents resolve depth and questions', () {
    assembler.recordParentTrajectory('sub-1', 'root-1');
    assembler.recordParentTrajectory('sub-2', 'sub-1');
    final start = assembler.handleStepStart(
      _start(
          5,
          {
            'type': 'elicitation_call',
            'description': 'Prompted for questions',
            'elicitation_id': 'sub-2-question-2-0',
            'preamble': {
              'content': [
                {'type': 'text', 'text': 'Python or Go?'},
              ],
            },
            'multiple_choice_request': {
              'choices': [
                {
                  'label': '1',
                  'display': [
                    {'type': 'text', 'text': 'Python'},
                  ],
                },
                {
                  'label': '2',
                  'display': [
                    {'type': 'text', 'text': 'Go'},
                  ],
                },
              ],
              'allow_multiple_selections': false,
            },
          },
          sub: 'sub-2'),
    );
    expect(start.step!.trajectoryId, 'sub-2');
    expect(start.step!.parentTrajectoryId, 'sub-1');
    expect(start.step!.depth, 2);
    expect(start.step!.status, StepStatus.waitingForUser);
    final elicitation = start.elicitation!;
    expect(elicitation.elicitationId, 'sub-2-question-2-0');
    expect(elicitation.groupKey, 'sub-2-question-2');
    expect(elicitation.question.question, 'Python or Go?');
    expect(elicitation.question.options.map((o) => (o.id, o.text)),
        [('1', 'Python'), ('2', 'Go')]);

    assembler.handleStepStart(_start(
        6,
        {
          'type': 'elicitation_result',
          'elicitation_id': 'sub-2-question-2-0',
          'multiple_choice': {
            'selected_choice_labels': ['1'],
          },
        },
        sub: 'sub-2'));
    final stop = assembler.handleStepStop(_stop(6, sub: 'sub-2'));
    expect(stop.step!.status, StepStatus.done);
    expect(stop.step!.toolCalls.single.args, {'question': 'Python or Go?'});
  });

  test('tool calls preserve additional proto fields', () {
    final start = assembler.handleStepStart(_start(1, {
      'type': 'view_file_call',
      'id': 'call-vf-extra',
      'file_path': 'file:///workspace/src/main.py',
      'start_line': 1,
      'end_line': 50,
      'content_offset': 1024,
    }));
    expect(start.step!.toolCalls.single.args, {
      'file_path': '/workspace/src/main.py',
      'start_line': 1,
      'end_line': 50,
      'content_offset': 1024,
    });
  });

  test('delta before start synthesizes a step; empty output is unknown', () {
    final d1 = assembler
        .handleStepDelta(_delta(10, {'type': 'text', 'text': 'Synthesized '}));
    expect(d1.dispatchPre, isTrue);
    expect(d1.step!.type, StepType.textResponse);
    final d2 =
        assembler.handleStepDelta(_delta(10, {'type': 'text', 'text': 'step'}));
    expect(d2.dispatchPre, isFalse);
    expect(d2.step!.content, 'Synthesized step');
    final stop = assembler.handleStepStop(_stop(10));
    expect(stop.dispatchPost, isTrue);
    expect(stop.step!.isCompleteResponse, isTrue);

    assembler.handleStepStart(_start(11, {'type': 'model_output'}));
    final empty = assembler.handleStepStop(_stop(11));
    expect(empty.step!.type, StepType.unknown);
    expect(empty.step!.isCompleteResponse, isFalse);
  });

  test('additional built-in call and result subtypes', () {
    final ce = assembler.handleStepStart(_start(
        1, {'type': 'code_execution_call', 'id': 'ce-1', 'code': 'ls -la'}));
    expect(ce.step!.toolCalls.single.name, 'run_command');
    expect(ce.step!.toolCalls.single.args,
        {'command_line': 'ls -la', 'language': 'bash'});
    assembler.handleStepStop(_stop(1));
    assembler.handleStepStart(_start(2, {
      'type': 'code_execution_result',
      'call_id': 'ce-1',
      'is_error': true,
      'result': '',
      'exit_code': 2,
    }));
    final ceResult = assembler.handleStepStop(_stop(2));
    expect(ceResult.step!.status, StepStatus.error);
    expect(ceResult.step!.error, 'Command failed with exit code 2');

    final gi = assembler.handleStepStart(_start(3, {
      'type': 'generate_image_call',
      'id': 'gi-1',
      'prompt': 'A sunset',
      'image_paths': ['file:///tmp/ref1.png', '/tmp/ref2.png'],
    }));
    expect(gi.step!.toolCalls.single.name, 'generate_image');
    expect(gi.step!.toolCalls.single.args, {
      'prompt': 'A sunset',
      'image_paths': ['/tmp/ref1.png', '/tmp/ref2.png'],
    });
    assembler.handleStepStop(_stop(3));
    assembler.handleStepStart(_start(4, {
      'type': 'generate_image_result',
      'call_id': 'gi-1',
      'image_name': 'sunset_out',
      'aspect_ratio': '16:9',
    }));
    expect(assembler.handleStepStop(_stop(4)).step!.toolCalls.single.args, {
      'prompt': 'A sunset',
      'image_paths': ['/tmp/ref1.png', '/tmp/ref2.png'],
      'image_name': 'sunset_out',
      'aspect_ratio': '16:9',
    });

    final gs = assembler.handleStepStart(_start(5, {
      'type': 'google_search_call',
      'id': 'gs-1',
      'queries': ['antigravity sdk', 'gaos interactions'],
    }));
    expect(gs.step!.toolCalls.single.name, 'search_web');
    expect(gs.step!.toolCalls.single.args['query'], 'antigravity sdk');
    assembler.handleStepStop(_stop(5));
    assembler.handleStepStart(_start(6, {
      'type': 'google_search_result',
      'call_id': 'gs-1',
      'is_error': true,
      'result': [
        {'search_suggestions': 'Try another query'},
      ],
    }));
    final gsResult = assembler.handleStepStop(_stop(6));
    expect(gsResult.step!.status, StepStatus.error);
    expect(gsResult.step!.error, 'Try another query');

    final uc = assembler.handleStepStart(_start(7, {
      'type': 'url_context_call',
      'id': 'uc-1',
      'urls': ['https://example.com'],
    }));
    expect(uc.step!.toolCalls.single.name, 'read_url_content');
    expect(uc.step!.toolCalls.single.args['url'], 'https://example.com');
    assembler.handleStepStop(_stop(7));
    assembler.handleStepStart(_start(8,
        {'type': 'url_context_result', 'call_id': 'uc-1', 'is_error': true}));
    expect(assembler.handleStepStop(_stop(8)).step!.error,
        'Reading URL content failed');

    final sl = assembler.handleStepStart(_start(9, {
      'type': 'skill_lookup_call',
      'id': 'sl-1',
      'requested_skill_names': ['critique'],
    }));
    expect(sl.step!.toolCalls.single.args, {
      'operation': '',
      'requested_skill_names': ['critique'],
    });
    assembler.handleStepStop(_stop(9));
    assembler.handleStepStart(_start(10, {
      'type': 'skill_lookup_result',
      'call_id': 'sl-1',
      'error_message': 'Skill lookup failed',
    }));
    expect(
        assembler.handleStepStop(_stop(10)).step!.error, 'Skill lookup failed');
  });

  test('results without a call ID pair with the oldest call of their kind', () {
    assembler.handleStepStart(_start(1, {'type': 'find_file_call', 'id': 'a'}));
    assembler.handleStepStart(_start(2, {'type': 'find_file_call', 'id': 'b'}));
    assembler.handleStepStart(_start(3, {'type': 'find_file_result'}));
    expect(assembler.handleStepStop(_stop(3)).step!.toolCalls.single.id, 'a');
    assembler.handleStepStart(_start(4, {'type': 'find_file_result'}));
    expect(assembler.handleStepStop(_stop(4)).step!.toolCalls.single.id, 'b');
  });
}
