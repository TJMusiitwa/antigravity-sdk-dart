import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:antigravity/antigravity.dart';
import 'package:antigravity/beta.dart' as beta;
import 'package:test/test.dart';

import 'agent_conversation_test.dart'
    show
        FakeAgentConfig,
        FakeConnection,
        FakeConnectionStrategy,
        TestPostTurnHook;

void main() {
  final skill = InlineSkill(
      name: 'audit',
      description: 'Audit code',
      content: 'Check code.',
      dependentTools: ['view_file'],
      dependentSkills: ['style']);
  Map<String, dynamic> wire(
          {List<InlineSkill> inline = const [],
          List<String> paths = const [],
          SubagentSkillsOption? subSkills,
          SubagentCapabilities? subCapabilities,
          List<McpServerConfig> servers = const []}) =>
      LocalConnectionStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner(),
        systemInstructions: null,
        capabilitiesConfig: CapabilitiesConfig(),
        workspaces: const [],
        skillsPaths: paths,
        inlineSkills: inline,
        mcpServers: servers,
        subagents: [
          SubagentConfig(
              name: 'worker',
              description: 'Work',
              skillsConfig: subSkills,
              capabilities: subCapabilities)
        ],
      ).buildHarnessConfigForTest();

  test(
      'inline skills serialize dependencies into metadata and preserve overrides',
      () {
    final result = wire(inline: [skill]);
    final entry = result['skills_config']['skills'][0]['skill'];
    expect(entry['content'], 'Check code.');
    expect(jsonDecode(entry['metadata']['dependent_tools']), ['view_file']);
    expect(jsonDecode(entry['metadata']['dependent_skills']), ['style']);
    final override =
        skill.copyWith(metadata: {'dependent_tools': '["custom"]'});
    expect(
        wire(inline: [override])['skills_config']['skills'][0]['skill']
            ['metadata']['dependent_tools'],
        '["custom"]');
    expect(InlineSkill.fromJson(skill.toJson()), skill);
  });

  test('local configs and strategies reject mixed skill sources', () {
    expect(
        () => LocalAgentConfig(
            apiKey: 'test', inlineSkills: [skill], skillsPaths: ['/skills']),
        throwsArgumentError);
    expect(
        () => wire(inline: [skill], paths: ['/skills']), throwsArgumentError);
    final config = LocalAgentConfig(apiKey: 'test', inlineSkills: [skill]);
    expect(config.lightweight().inlineSkills, [skill]);
    expect(config.eval().inlineSkills, [skill]);
    final strategy = config.createStrategy(
        toolRunner: ToolRunner(),
        hookRunner: HookRunner()) as LocalConnectionStrategy;
    expect(strategy.buildHarnessConfigForTest()['skills_config']['enabled'],
        isTrue);
  });

  test('subagent skills accept shorthand, round trip, and use proto oneof', () {
    for (final mode in <SubagentSkillsOption>[
      SubagentNoneSkillsConfig(),
      SubagentInheritSkillsConfig(
          skillNames: ['audit'], extraSkillsPaths: ['/extra']),
      SubagentOverrideSkillsConfig(skillsPaths: ['/override']),
    ]) {
      final config = SubagentConfig(
          name: 'worker', description: 'Work', skillsConfig: mode);
      expect(SubagentConfig.fromJson(config.toJson()).skillsConfig,
          config.skillsConfig);
    }
    expect(
        wire(subSkills: SubagentNoneSkillsConfig())['custom_subagents'][0]
            ['skills_config'],
        {'none_config': {}});
    expect(
        wire(
                subSkills: SubagentOverrideSkillsConfig(
                    skillsPaths: ['/override']))['custom_subagents'][0]
            ['skills_config'],
        {
          'override_config': {
            'skills_paths': ['/override']
          }
        });
    expect(wire()['custom_subagents'][0], isNot(contains('skills_config')));
    expect(
        () => SubagentSkillsConfig(
            noneConfig: SubagentNoneSkillsConfig(),
            inheritConfig: SubagentInheritSkillsConfig()),
        throwsArgumentError);
    expect(() => SubagentOverrideSkillsConfig(), throwsArgumentError);
    expect(
        () => wire(
            subSkills: SubagentOverrideSkillsConfig(inlineSkills: [skill])),
        throwsArgumentError);
  });

  test('all local config variants carry inline skills and reject mixed sources',
      () {
    final configs = <BaseLocalAgentConfig>[
      LocalOpenAIAgentConfig(model: 'local', inlineSkills: [skill]),
      LiteRTAgentConfig(
          modelPath: '/tmp/model.litertlm', inlineSkills: [skill]),
    ];
    for (final config in configs) {
      final strategy = config.createStrategy(
          toolRunner: ToolRunner(),
          hookRunner: HookRunner()) as LocalConnectionStrategy;
      expect(
          strategy.buildHarnessConfigForTest()['skills_config']['skills'][0]
              ['skill']['name'],
          'audit');
    }
    expect(
        () => LocalOpenAIAgentConfig(
            inlineSkills: [skill], skillsPaths: ['/skills']),
        throwsArgumentError);
    expect(
        () => LiteRTAgentConfig(
            modelPath: '/tmp/model.litertlm',
            inlineSkills: [skill],
            skillsPaths: ['/skills']),
        throwsArgumentError);
  });

  test('tool inspection and iterable batches retain schema and input order',
      () async {
    final tool = Tool(
        name: 'echo',
        description: 'Echo a number',
        schema: {'type': 'object'},
        handler: (args, context) async => args['n']);
    expect(tool.toString(), contains('echo'));
    expect(tool.toString(), contains('object'));
    final runner = ToolRunner(tools: {tool});
    final results = await runner.processToolCalls(
        [1, 2].map((n) => ToolCall(id: '$n', name: 'echo', args: {'n': n})));
    expect(results.map((result) => result.result), [1, 2]);
    expect(await runner.processToolCalls(const []), isEmpty);
  });

  test('MCP eager loading works on both transports and URI factory', () {
    final servers = <McpServerConfig>[
      McpStdioServer(
          name: 'stdio', command: 'server', forceAllToolsEager: true),
      McpStreamableHttpServer.fromUri(
          name: 'http',
          uri: Uri.parse('https://example.com/mcp'),
          forceAllToolsEager: true),
    ];
    for (final server in servers) {
      expect(
          McpServerConfig.fromJson(server.toJson()).forceAllToolsEager, isTrue);
    }
    for (final server in wire(servers: servers)['mcp_servers']) {
      expect(server['force_all_tools_eager'], isTrue);
    }
  });

  test('workflow tools keep delegation enabled and obey subagent denylist', () {
    expect(
        CapabilitiesConfig(
                enabledTools: [BuiltinTools.runWorkflow], maxSubagentDepth: 2)
            .maxSubagentDepth,
        2);
    expect(
        SubagentCapabilities(
            disabledTools: [BuiltinTools.startSubagent],
            allowedSubagents: ['worker']).allowedSubagents,
        ['worker']);
    final config = wire(
        subCapabilities: SubagentCapabilities(disabledTools: [
      BuiltinTools.runWorkflow,
      BuiltinTools.runCommand
    ]));
    expect(config['harness_side_tools']['run_workflow']['enabled'], isTrue);
    expect(
        config['custom_subagents'][0]['harness_side_tools']['run_workflow']
            ['enabled'],
        isFalse);
    expect(
        config['custom_subagents'][0]['harness_side_tools']['run_command']
            ['enabled'],
        isFalse);
  });

  test('bulk hooks execute in registration order', () async {
    final calls = <int>[];
    final runner = HookRunner(hooks: [TestPostTurnHook((_) => calls.add(1))]);
    runner.registerHooks([
      TestPostTurnHook((_) => calls.add(2)),
      TestPostTurnHook((_) => calls.add(3))
    ]);
    await runner.dispatchPostTurn(runner.createTurnContext(), 'done');
    expect(calls, [1, 2, 3]);
  });

  test(
      'allowAll disables workspace containment unless workspaceOnly is present',
      () {
    expect(toPolicyConfigProto([allowAll()]).config['workspace_containment'],
        'WORKSPACE_CONTAINMENT_DISABLED');
    expect(
        toPolicyConfigProto([
          allowAll(),
          workspaceOnly(['/workspace'])
        ]).config['workspace_containment'],
        'WORKSPACE_CONTAINMENT_UNSPECIFIED');
    expect(toPolicyConfigProto([allow('*')]).config['workspace_containment'],
        'WORKSPACE_CONTAINMENT_UNSPECIFIED');
  });

  test('error step text and thoughts are not emitted', () async {
    final connection = _WorkflowConnection('error_text');
    final conversation = Conversation(connection);
    final response = await conversation.chat('test');
    expect(await response.text(), isEmpty);
    expect(await response.thoughts.toList(), isEmpty);
    await connection.disconnect();
  });

  test('empty tool IDs are never deduplicated but named IDs are', () async {
    final connection = _WorkflowConnection('dedup');
    final conversation = Conversation(connection);
    final response = await conversation.chat('test');
    final calls = await response.toolCalls.toList();
    expect(calls.map((call) => call.id), ['', '', 'same']);
    await connection.disconnect();
  });

  test('usage zero identity preserves nulls and returns an independent copy',
      () {
    final usage =
        UsageMetadata(totalTokenCount: 12, serviceTier: ServiceTier.standard);
    for (final value in [usage + 0, usage - 0.0]) {
      expect(value, usage);
      expect(identical(value, usage), isFalse);
      expect(value.promptTokenCount, isNull);
    }
    expect((usage - UsageMetadata(totalTokenCount: 3)).totalTokenCount, 9);
    expect(() => usage - 1, throwsArgumentError);
    expect(() => usage + '0', throwsArgumentError);
  });

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
    expect(Step.fromMap(step.toMap()).workflowProgress, step.workflowProgress);
  });

  test(
      'beta workflow resolves response and reports errors or missing invocation',
      () async {
    final directory = await Directory.systemTemp.createTemp('workflow_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/workflow.py');
    await file.writeAsString('log("done")');
    for (final mode in ['success', 'error', 'missing']) {
      final connection = _WorkflowConnection(mode);
      final agent = Agent(FakeAgentConfig(_WorkflowStrategy(connection),
          capabilities: CapabilitiesConfig(), policies: [allowAll()]));
      await agent.start();
      try {
        if (mode == 'success') {
          final result = await agent.beta.runWorkflow(scriptPath: file.path);
          expect(result, isA<beta.WorkflowResult>());
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
            agent.beta.runWorkflow(scriptPath: '${directory.path}/missing.py'),
            throwsA(isA<FileSystemException>()));
      } finally {
        await agent.stop();
      }
    }
  });

  test('beta workflow validates the script before asking the model', () async {
    final directory = await Directory.systemTemp.createTemp('workflow_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/bad.py');
    await file.writeAsString('import os\nlog("x")\n');
    final agent = Agent(FakeAgentConfig(
        _WorkflowStrategy(_WorkflowConnection('success')),
        capabilities: CapabilitiesConfig(),
        policies: [allowAll()]));
    await agent.start();
    try {
      await expectLater(
          agent.beta.runWorkflow(scriptPath: file.path),
          throwsA(isA<beta.WorkflowException>().having((e) => e.message,
              'message', contains('import statements are not allowed'))));
      expect(agent.conversation.history, isEmpty);
    } finally {
      await agent.stop();
    }
  });
}

class _WorkflowConnection extends FakeConnection {
  final String mode;
  _WorkflowConnection(this.mode);
  final controller = StreamController<Step>.broadcast();
  @override
  Stream<Step> receiveSteps() => controller.stream;
  @override
  Future<void> send(ContentPrimitive? prompt,
      {Map<String, dynamic>? kwargs}) async {
    scheduleMicrotask(() {
      if (mode == 'error_text') {
        controller.add(Step(
            source: StepSource.model,
            target: StepTarget.user,
            status: StepStatus.error,
            contentDelta: 'bad text',
            thinkingDelta: 'bad thought'));
        return;
      }
      if (mode == 'dedup') {
        for (final id in ['', '', 'same', 'same']) {
          controller.add(
              Step(toolCalls: [ToolCall(id: id, name: 'example', args: {})]));
        }
        controller.add(Step(id: 'idle_sentinel', type: StepType.finish));
        return;
      }
      if (mode != 'missing') {
        controller.add(Step.fromMap({
          'step_index': 1,
          'run_workflow': {'output': 'workflow output'},
          'state': mode == 'error' ? 'STATE_ERROR' : 'STATE_DONE',
          'error': mode == 'error' ? 'failed' : ''
        }));
      }
      controller.add(Step(
          stepIndex: 2,
          type: StepType.textResponse,
          source: StepSource.model,
          target: StepTarget.user,
          contentDelta: 'finished',
          status: StepStatus.done));
      controller.add(Step(
          id: 'idle_sentinel',
          stepIndex: -1,
          type: StepType.finish,
          status: StepStatus.done));
    });
  }

  @override
  Future<void> disconnect() async {
    await controller.close();
    await super.disconnect();
  }
}

class _WorkflowStrategy extends FakeConnectionStrategy {
  final _WorkflowConnection custom;
  _WorkflowStrategy(this.custom);
  @override
  Connection connect() => custom;
  @override
  Future<void> stop() => custom.disconnect();
}
