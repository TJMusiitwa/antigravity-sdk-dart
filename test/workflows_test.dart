import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:antigravity/beta.dart';
import 'package:test/test.dart';

import 'agent_conversation_test.dart'
    show FakeAgentConfig, WorkflowConnection, WorkflowConnectionStrategy;

Matcher _rejects(String message) => throwsA(isA<WorkflowException>()
    .having((e) => e.message, 'message', contains(message)));

const _returnYield = 'return/yield statements are not allowed';

void main() {
  test('accepts a typical workflow script', () {
    expect(
      () => validateWorkflowSource('''
# Explore, then summarize.
phase("Explore")
files = await agent("List files", schema={"type": "array"})

async def review(path):
    """Reviews one file."""
    result = await agent(f"Review {path}", schema={"type": "string"})
    return result

reviews = await parallel(files, review)
for i, item in enumerate(reviews):
    if not item:
        continue
    log(f"{i}: {item}", sep="\\n")
text = """multi-line
string with return, yield, import and while inside"""
data = {"__key__": 1, "a": [1, 2,
    3]}
total = (1 +
         2)
log(text.upper(), data, total)
'''),
      returnsNormally,
    );
  });

  test('rejects return and yield', () {
    expect(() => validateWorkflowSource('phase("Step")\nreturn "done"\n'),
        _rejects(_returnYield));
    expect(() => validateWorkflowSource("yield 'x'\n"), _rejects(_returnYield));
    expect(() => validateWorkflowSource('def gen():\n  yield 1\n'),
        _rejects(_returnYield));
    expect(() => validateWorkflowSource('def gen_from():\n  yield from [1]\n'),
        _rejects(_returnYield));
    expect(
        () => validateWorkflowSource('for x in [1]:\n  if x:\n    return x\n'),
        _rejects(_returnYield));
    expect(() => validateWorkflowSource('class C:\n  return 1\n'),
        _rejects(_returnYield));
  });

  test('allows return inside nested functions', () {
    expect(
        () => validateWorkflowSource(
            'def outer():\n  def inner():\n    return 1\n  return inner()\n'
            'async def stage(x): return x\n'),
        returnsNormally);
  });

  test('rejects imports', () {
    expect(() => validateWorkflowSource("import os\nphase('test')\n"),
        _rejects('import statements are not allowed in workflow scripts'));
    expect(() => validateWorkflowSource('from os import path\n'),
        _rejects('import statements are not allowed in workflow scripts'));
  });

  test('rejects while loops', () {
    expect(() => validateWorkflowSource('while True:\n  log("loop")\n'),
        _rejects('while loops are not allowed in workflow scripts'));
  });

  test('rejects private attributes and dunder names', () {
    expect(() => validateWorkflowSource('x = obj._secret\n'),
        _rejects("attribute '_secret' is not allowed in workflow scripts"));
    expect(() => validateWorkflowSource("__import__('os')\n"),
        _rejects("name '__import__' is not allowed in workflow scripts"));
    expect(() => validateWorkflowSource('x = ().__class__\n'),
        _rejects("attribute '__class__' is not allowed"));
  });

  test('allows dunder parameter and keyword names', () {
    expect(
        () => validateWorkflowSource(
            'def f(__a, *, __b=1):\n  return 1\nf(1, __b=2)\n'),
        returnsNormally);
  });

  test('reports syntax errors', () {
    for (final source in [
      'def broken(:\n',
      'x = "unterminated\n',
      'x = """never closed\n',
      'x = (1, 2]\n',
      'if True:\nlog(1)\n',
      'log(1)\n  log(2)\n',
      'if True:\n    a = 1\n  b = 2\n',
      'for x in y:\n',
    ]) {
      expect(() => validateWorkflowSource(source),
          _rejects('workflow syntax error'),
          reason: source);
    }
  });

  group('agent.beta.runWorkflow', () {
    test('workflow steps normalize paths and keep output out of tool arguments',
        () {
      final step = Step.fromMap({
        'run_workflow': {
          'scriptPath': 'file:///tmp/a.py',
          'script': 'log("ok")',
          'description': 'audit',
          'output': 'ok'
        },
        'state': 'STATE_DONE'
      });
      expect(step.workflowProgress!.scriptPath, '/tmp/a.py');
      expect(step.workflowProgress!.output, 'ok');
      expect(step.toolCalls.single.name, 'run_workflow');
      expect(step.toolCalls.single.args, {
        'script_path': '/tmp/a.py',
        'script': 'log("ok")',
        'description': 'audit'
      });
      expect(
          Step.fromMap(step.toMap()).workflowProgress, step.workflowProgress);
    });

    test(
        'beta workflow resolves response and reports errors or missing invocation',
        () async {
      final directory = await Directory.systemTemp.createTemp('workflow_test_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workflow.py');
      await file.writeAsString('log("done")');
      for (final mode in ['success', 'error', 'missing']) {
        final connection = WorkflowConnection(mode);
        final agent = Agent(FakeAgentConfig(
            WorkflowConnectionStrategy(connection),
            capabilities: CapabilitiesConfig(),
            policies: [allowAll()]));
        await agent.start();
        try {
          if (mode == 'success') {
            final result = await agent.beta.runWorkflow(scriptPath: file.path);
            expect(result, isA<WorkflowResult>());
            expect(result.output, 'workflow output');
            expect(await result.text(), 'finished');
            expect(result.responseText, 'finished');
            expect(result.scriptPath, await file.resolveSymbolicLinks());
            expect(await result.toolCalls.toList(), hasLength(1));
          } else {
            await expectLater(agent.beta.runWorkflow(scriptPath: file.path),
                throwsA(isA<ToolExecutionException>()));
          }
          await expectLater(
              agent.beta.runWorkflow(scriptPath: ''), throwsArgumentError);
          await expectLater(
              agent.beta
                  .runWorkflow(scriptPath: '${directory.path}/missing.py'),
              throwsA(isA<FileSystemException>()));
        } finally {
          await agent.stop();
        }
      }
    });

    test('beta workflow validates the script before asking the model',
        () async {
      final directory = await Directory.systemTemp.createTemp('workflow_test_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/bad.py');
      await file.writeAsString('import os\nlog("x")\n');
      final agent = Agent(FakeAgentConfig(
          WorkflowConnectionStrategy(WorkflowConnection('success')),
          capabilities: CapabilitiesConfig(),
          policies: [allowAll()]));
      await agent.start();
      try {
        await expectLater(
            agent.beta.runWorkflow(scriptPath: file.path),
            throwsA(isA<WorkflowException>().having((e) => e.message, 'message',
                contains('import statements are not allowed'))));
        expect(agent.conversation.history, isEmpty);
      } finally {
        await agent.stop();
      }
    });
  });
}
