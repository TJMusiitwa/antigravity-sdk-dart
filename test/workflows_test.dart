import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:antigravity/beta.dart';
import 'package:test/test.dart';

import 'agent_conversation_test.dart'
    show FakeAgentConfig, WorkflowConnection, WorkflowConnectionStrategy;

Matcher _rejects(String message) => throwsA(
  isA<WorkflowException>().having(
    (e) => e.message,
    'message',
    contains(message),
  ),
);

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
    expect(
      () => validateWorkflowSource('phase("Step")\nreturn "done"\n'),
      _rejects(_returnYield),
    );
    expect(() => validateWorkflowSource("yield 'x'\n"), _rejects(_returnYield));
    expect(
      () => validateWorkflowSource('def gen():\n  yield 1\n'),
      _rejects(_returnYield),
    );
    expect(
      () => validateWorkflowSource('def gen_from():\n  yield from [1]\n'),
      _rejects(_returnYield),
    );
    expect(
      () => validateWorkflowSource('for x in [1]:\n  if x:\n    return x\n'),
      _rejects(_returnYield),
    );
    expect(
      () => validateWorkflowSource('class C:\n  return 1\n'),
      _rejects(_returnYield),
    );
  });

  test('allows return inside nested functions', () {
    expect(
      () => validateWorkflowSource(
        'def outer():\n  def inner():\n    return 1\n  return inner()\n'
        'async def stage(x): return x\n',
      ),
      returnsNormally,
    );
  });

  test('allows imports, while loops, and private names', () {
    expect(
      () => validateWorkflowSource(
        'import json\n'
        'from os import path\n'
        'attempts = 0\n'
        'while attempts < 2:\n'
        '  attempts += 1\n'
        'x = obj._secret\n'
        "__import__('os')\n",
      ),
      returnsNormally,
    );
  });

  test('allows multi-turn agents, call_tool, ToolError, and args', () {
    expect(
      () => validateWorkflowSource('''
target = args.get("target", "README.md")
phase("Read")
try:
    raw = await call_tool("read_file", Path=target)
except ToolError as err:
    log(err.tool, err.message)
    raw = "{}"
reviewer = agent("You are a code reviewer.", role="Code Reviewer")
verdict = await reviewer(f"Review {raw}", schema={"type": "string"})
log(verdict)
'''),
      returnsNormally,
    );
  });

  test('rejects print calls anywhere', () {
    const printMessage =
        'print() is not allowed in workflow scripts; use '
        'workflows.log(...) to emit output';
    for (final source in [
      'phase("Step")\nprint("hello")\n',
      'async def helper(item):\n'
          '  print(item)\n'
          '  return await agent(item, schema={"type": "string"})\n'
          'await pipeline(["a"], helper)\n',
      'import builtins\nbuiltins.print(1)\n',
      '__builtins__.print(1)\n',
      'x = [print (i) for i in range(2)]\n',
    ]) {
      expect(
        () => validateWorkflowSource(source),
        _rejects(printMessage),
        reason: source,
      );
    }
  });

  test('the bundled example workflow script passes validation', () {
    final script = File('example/resources/security_audit_workflow.py');
    expect(script.existsSync(), isTrue);
    expect(
      () => validateWorkflowSource(script.readAsStringSync()),
      returnsNormally,
    );
  });

  test('allows print that is not a builtin call', () {
    expect(
      () => validateWorkflowSource(
        'printer.print(1)\n'
        'log("print(x)")\n'
        'def print(x):\n  return x\n'
        'fn = print\n',
      ),
      returnsNormally,
    );
  });

  test('allows dunder parameter and keyword names', () {
    expect(
      () => validateWorkflowSource(
        'def f(__a, *, __b=1):\n  return 1\nf(1, __b=2)\n',
      ),
      returnsNormally,
    );
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
      expect(
        () => validateWorkflowSource(source),
        _rejects('workflow syntax error'),
        reason: source,
      );
    }
  });

  group('agent.beta.runWorkflow', () {
    test(
      'workflow steps normalize paths and keep output out of tool arguments',
      () {
        final step = Step.fromMap({
          'run_workflow': {
            'scriptPath': 'file:///tmp/a.py',
            'script': 'log("ok")',
            'description': 'audit',
            'output': 'ok',
          },
          'state': 'STATE_DONE',
        });
        expect(step.workflowProgress!.scriptPath, '/tmp/a.py');
        expect(step.workflowProgress!.output, 'ok');
        expect(step.toolCalls.single.name, 'run_workflow');
        expect(step.toolCalls.single.args, {
          'script_path': '/tmp/a.py',
          'script': 'log("ok")',
          'description': 'audit',
        });
        expect(
          Step.fromMap(step.toMap()).workflowProgress,
          step.workflowProgress,
        );
      },
    );

    test('beta workflow resolves response and reports errors or missing invocation', () async {
      final directory = await Directory.systemTemp.createTemp('workflow_test_');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workflow.py');
      await file.writeAsString('log("done")');
      for (final mode in ['success', 'error', 'missing']) {
        final connection = WorkflowConnection(mode);
        final agent = Agent(
          FakeAgentConfig(
            WorkflowConnectionStrategy(connection),
            capabilities: CapabilitiesConfig(),
            policies: [allowAll()],
          ),
        );
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
            await expectLater(
              agent.beta.runWorkflow(scriptPath: file.path),
              throwsA(isA<ToolExecutionException>()),
            );
          }
          await expectLater(
            agent.beta.runWorkflow(scriptPath: ''),
            throwsArgumentError,
          );
          await expectLater(
            agent.beta.runWorkflow(scriptPath: '${directory.path}/missing.py'),
            throwsA(isA<FileSystemException>()),
          );
        } finally {
          await agent.stop();
        }
      }
    });

    test('runWorkflow resolves against any workspace and sends args', () async {
      final first = await Directory.systemTemp.createTemp('workflow_ws1_');
      final second = await Directory.systemTemp.createTemp('workflow_ws2_');
      addTearDown(() => first.delete(recursive: true));
      addTearDown(() => second.delete(recursive: true));
      final script = File('${second.path}/my_workflow.py');
      await script.writeAsString("phase('Audit')\nlog('done')\n");
      final connection = WorkflowConnection('success');
      final agent = Agent(
        FakeAgentConfig(
          WorkflowConnectionStrategy(connection),
          capabilities: CapabilitiesConfig(),
          policies: [allowAll()],
          workspaces: [first.path, second.path],
        ),
      );
      await agent.start();
      try {
        final result = await agent.beta.runWorkflow(
          scriptPath: 'my_workflow.py',
          args: {'target': 'auth.py', 'retries': 2},
        );
        expect(result.scriptPath, await script.resolveSymbolicLinks());
        expect(
          connection.prompts.last,
          'Run the workflow script at `${await script.resolveSymbolicLinks()}`'
          ' (Run workflow my_workflow.py) with Args'
          ' `{"target": "auth.py", "retries": 2}` using the `run_workflow`'
          ' tool.',
        );

        await agent.beta.runWorkflow(scriptPath: 'my_workflow.py', args: {});
        expect(connection.prompts.last as String, isNot(contains('with Args')));

        await agent.beta.runWorkflow(
          scriptPath: 'my_workflow.py',
          args: {
            'nested': {
              'list': [1, 2.5, null, true],
              'text': 'café "q"',
            },
          },
        );
        expect(
          connection.prompts.last as String,
          contains(
            'with Args `{"nested": {"list": [1, 2.5, null, true],'
            r' "text": "caf\u00e9 \"q\""}}`',
          ),
        );

        final promptCount = connection.prompts.length;
        for (final bad in [
          {'bad': Object()},
          {'bad_float': double.nan},
          {'bad_float': double.infinity},
        ]) {
          await expectLater(
            agent.beta.runWorkflow(scriptPath: 'my_workflow.py', args: bad),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                contains('`args` must be JSON-serializable'),
              ),
            ),
          );
        }
        expect(connection.prompts, hasLength(promptCount));
      } finally {
        await agent.stop();
      }
    });

    test(
      'beta workflow validates the script before asking the model',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'workflow_test_',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/bad.py');
        await file.writeAsString('print("x")\n');
        final agent = Agent(
          FakeAgentConfig(
            WorkflowConnectionStrategy(WorkflowConnection('success')),
            capabilities: CapabilitiesConfig(),
            policies: [allowAll()],
          ),
        );
        await agent.start();
        try {
          await expectLater(
            agent.beta.runWorkflow(scriptPath: file.path),
            throwsA(
              isA<WorkflowException>().having(
                (e) => e.message,
                'message',
                contains('print() is not allowed'),
              ),
            ),
          );
          expect(agent.conversation.history, isEmpty);
        } finally {
          await agent.stop();
        }
      },
    );
  });
}
