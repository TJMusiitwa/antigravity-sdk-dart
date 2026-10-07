import 'dart:convert';

import 'package:antigravity/antigravity.dart';
import 'package:antigravity/src/connections/local/interactions_config_converter.dart';
import 'package:test/test.dart';

final _addNumbers = Tool(
  name: 'add_numbers',
  description: 'Adds two numbers.',
  schema: {
    'type': 'object',
    'properties': {
      'a': {'type': 'integer'},
      'b': {'type': 'integer'},
    },
  },
  handler: (args, _) => (args['a'] as int) + (args['b'] as int),
);

Tool _tool(String name, String description) => Tool(
      name: name,
      description: description,
      schema: {
        'type': 'object',
        'properties': {
          'y': {'type': 'string'},
        },
      },
      handler: (args, _) => args['y'],
    );

class _PreTurn extends PreTurnHook {
  @override
  Future<HookResult> run(HookContext context, ContentPrimitive data) async =>
      HookResult(allow: true);
}

class _PreTool extends PreToolCallDecideHook {
  @override
  Future<HookResult> run(HookContext context, ToolCall data) async =>
      HookResult(allow: true);
}

Matcher _has(Map<String, dynamic> expected) => anyElement(equals(expected));

List<String> _functionNames(List<dynamic> tools) => [
      for (final t in tools)
        if (t['type'] == 'function') t['name'] as String,
    ];

void main() {
  test('session continuation modes map to interaction IDs', () {
    final create = buildCreateInteractionEvent(
      conversationId: 'conv-123',
      sessionContinuationMode: SessionContinuationMode.createOnly,
    );
    expect(create['event_type'], 'interaction.create');
    expect(create['agent'], 'antigravity');
    expect(create['interaction_id'], 'conv-123');
    expect(create, isNot(contains('previous_interaction_id')));

    final resume = buildCreateInteractionEvent(
      conversationId: 'conv-123',
      sessionContinuationMode: SessionContinuationMode.resume,
    );
    expect(resume, isNot(contains('interaction_id')));
    expect(resume['previous_interaction_id'], 'conv-123');

    final both = buildCreateInteractionEvent(
      conversationId: 'conv-123',
      sessionContinuationMode: SessionContinuationMode.createOrResume,
    );
    expect(both['interaction_id'], 'conv-123');
    expect(both['previous_interaction_id'], 'conv-123');
  });

  test('system instructions become developer instructions', () {
    expect(
      buildCreateInteractionEvent(
        systemInstructions: CustomSystemInstructions(text: 'Be concise.'),
      )['developer_instructions'],
      [
        {'type': 'text', 'text': 'Be concise.'},
      ],
    );
    expect(
      buildCreateInteractionEvent(
        systemInstructions: TemplatedSystemInstructions(
          identity: 'CustomBot',
          sections: [
            SystemInstructionSection(title: 'rules', content: 'Rule 1')
          ],
        ),
      )['appended_developer_instructions'],
      {
        'custom_identity': 'CustomBot',
        'appended_sections': [
          {'title': 'rules', 'content': 'Rule 1'},
        ],
      },
    );
    expect(
      buildCreateInteractionEvent(
        systemInstructions: 'Plain string instructions',
      )['appended_developer_instructions'],
      {
        'appended_sections': [
          {
            'title': 'user_system_instructions',
            'content': 'Plain string instructions',
          },
        ],
      },
    );
    expect(() => buildCreateInteractionEvent(systemInstructions: 123),
        throwsArgumentError);
  });

  test('tools, MCP servers, and capabilities translate to GAOS tools', () {
    final event = buildCreateInteractionEvent(
      toolRunner: ToolRunner(tools: [_addNumbers]),
      mcpServers: [
        McpStdioServer(
          name: 'my_stdio',
          timeoutSeconds: 15,
          command: '/bin/mcp',
          args: ['--flag'],
          env: {'FOO': 'BAR'},
          enabledTools: ['tool_a'],
        ),
        McpStreamableHttpServer(
          name: 'my_http',
          url: 'https://example.com/mcp',
          headers: {'Auth': 'Bearer x'},
          disabledTools: ['tool_b'],
        ),
      ],
      capabilitiesConfig: CapabilitiesConfig(
        enabledTools: BuiltinTools.values,
        agentBehavior: AgentBehavior.interactive,
        runCommandConfig: RunCommandConfig(
          timeoutSeconds: 5.0,
          enableDaemons: true,
          enableSandbox: true,
        ),
      ),
    );
    final tools = event['tools'] as List;
    final function = tools.singleWhere((t) => t['type'] == 'function');
    expect(function['name'], 'add_numbers');
    expect(function['description'], 'Adds two numbers.');
    expect((function['parameters']['properties'] as Map).keys, ['a', 'b']);
    expect(
        tools,
        _has({
          'type': 'mcp_server',
          'name': 'my_stdio',
          'timeout': '15s',
          'stdio': {
            'command': '/bin/mcp',
            'args': ['--flag'],
            'env': {'FOO': 'BAR'},
          },
          'allowed_tools': [
            {
              'mode': 'any',
              'tools': ['tool_a'],
            },
          ],
        }));
    expect(
        tools,
        _has({
          'type': 'mcp_server',
          'name': 'my_http',
          'http': {
            'url': 'https://example.com/mcp',
            'headers': {'Auth': 'Bearer x'},
          },
          'allowed_tools': [
            {
              'mode': 'none',
              'tools': ['tool_b'],
            },
          ],
        }));
    expect(
        tools,
        _has({
          'type': 'bash',
          'max_timeout_ms': 5000,
          'enable_daemon_commands': true,
          'enable_sandbox': true,
        }));
    expect(
        tools,
        _has({
          'type': 'filesystem',
          'supported_operations': [
            'file_read',
            'file_write',
            'file_edit',
            'file_find',
            'directory_list',
            'file_grep',
          ],
        }));
    for (final type in ['manage_task', 'schedule', 'google_search']) {
      expect(tools, _has({'type': type}));
    }
    expect(tools, _has({'type': 'url_context'}));
    expect(event['agent_config']['policy'], {
      'enable_user_questions': true,
      'enable_image_generation': true,
    });
  });

  test('tools partition between the root agent and subagents', () {
    final subOnly = _tool('sub_only_tool', 'Subagent-only tool.');
    final schemaTool = _tool('schema_fn', 'Tool with explicit schema.');
    final runner = ToolRunner(tools: [_addNumbers, subOnly]);
    final event = buildCreateInteractionEvent(
      toolRunner: runner,
      subagents: [
        SubagentConfig(
          name: 'worker',
          description: 'Worker subagent',
          tools: ['sub_only_tool', schemaTool],
          skillsConfig: SubagentInheritSkillsConfig(
            skillNames: ['skill_a'],
            extraSkillsPaths: ['/tmp/extra_skills'],
          ),
        ),
      ],
    );
    expect(_functionNames(event['tools']), ['add_numbers']);
    final subagent =
        event['agent_config']['subagents_config']['custom_subagents'][0];
    expect(_functionNames(subagent['tools']), ['sub_only_tool', 'schema_fn']);
    expect(subagent['skills_config'], {
      'inherit_config': {
        'skill_names': ['skill_a'],
        'extra_skills_paths': ['/tmp/extra_skills'],
      },
    });

    final explicit = buildCreateInteractionEvent(
      toolRunner: runner,
      tools: ['add_numbers', 'unregistered_tool', schemaTool],
    );
    expect(_functionNames(explicit['tools']),
        ['add_numbers', 'unregistered_tool', 'schema_fn']);
    expect(
        (explicit['tools'] as List)
            .singleWhere((t) => t['name'] == 'unregistered_tool'),
        {
          'type': 'function',
          'name': 'unregistered_tool',
          'parameters': {'type': 'object', 'properties': {}},
        });
  });

  test('subagent skills modes translate and unsupported options are rejected',
      () {
    final subagents = buildCreateInteractionEvent(subagents: [
      SubagentConfig(
        name: 's_none',
        description: 'No skills',
        skillsConfig: SubagentNoneSkillsConfig(),
      ),
      SubagentConfig(
        name: 's_override',
        description: 'Override skills',
        skillsConfig:
            SubagentOverrideSkillsConfig(skillsPaths: ['/tmp/custom_skills']),
      ),
    ])['agent_config']['subagents_config']['custom_subagents'];
    expect(subagents[0]['skills_config'], {'none_config': {}});
    expect(subagents[1]['skills_config'], {
      'override_config': {
        'skills_paths': ['/tmp/custom_skills'],
      },
    });

    expect(
      () => buildCreateInteractionEvent(subagents: [
        SubagentConfig(
          name: 's_inline',
          description: 'Inline skills unsupported',
          skillsConfig: SubagentOverrideSkillsConfig(inlineSkills: [
            InlineSkill(name: 'sk', description: 'd', content: 'i'),
          ]),
        ),
      ]),
      throwsA(isA<AntigravityValidationException>()),
    );
    expect(
      () => buildCreateInteractionEvent(subagents: [
        SubagentConfig(
          name: 's_model',
          description: 'Model override unsupported',
          model: 'gemini-2.5-flash',
        ),
      ]),
      throwsA(isA<AntigravityValidationException>()),
    );
  });

  test('agent_config carries every configured field', () {
    final hooks = HookRunner(hooks: [
      _PreTurn(),
      _PreTool(),
      FunctionStopHook((_, __) => null),
    ]);
    final event = buildCreateInteractionEvent(
      appDataDir: '/tmp/appdata',
      skillsPaths: ['/tmp/skills'],
      workspaces: ['/tmp/ws'],
      models: [
        ModelTarget(
          name: 'gemini-2.5-pro',
          types: [ModelType.text],
          endpoint: GeminiAPIEndpoint(
            apiKey: 'test-key',
            options: GeminiModelOptions(
              thinkingLevel: ThinkingLevel.high,
              serviceTier: ServiceTier.priority,
            ),
          ),
        ),
        ModelTarget(
          name: 'gemini-2.5-flash',
          types: [ModelType.image],
          endpoint: VertexEndpoint(
            baseUrl: 'https://us-central1-aiplatform.googleapis.com',
            httpHeaders: {'X-Custom': '1'},
            apiKey: 'vertex-key',
            project: 'my-proj',
            location: 'us-central1',
            options: GeminiModelOptions(thinkingLevel: ThinkingLevel.low),
          ),
        ),
      ],
      hookRunner: hooks,
      compactionConfig: CompactionConfig(tokenThreshold: 50000),
      capabilitiesConfig: CapabilitiesConfig(
        enableSubagents: true,
        allowedSubagents: ['helper'],
        maxSubagentDepth: 2,
        finishToolSchemaJson: '{"type": "object"}',
        agentBehavior: AgentBehavior.interactive,
        toolOutputTruncationConfig: ToolOutputTruncationConfig(maxTokens: 4096),
      ),
      subagents: [
        SubagentConfig(
          name: 'helper',
          description: 'Helper subagent',
          capabilities: SubagentCapabilities(
            enabledTools: [BuiltinTools.viewFile],
            agentBehavior: AgentBehavior.autonomous,
          ),
        ),
      ],
      retryConfig: RetryConfig(
        apiRetry: ModelAPIRetryConfig(
          maxRetries: 4,
          initialSleepDurationMs: 250,
          exponentialMultiplier: 2.0,
        ),
        modelOutputRetry: ModelOutputRetryConfig(maxRetries: 2),
      ),
      budgetConfig: BudgetConfig(
        maxModelCalls: 10,
        scope: BudgetScope.forwardLooking,
      ),
      policies: [deny('run_command', reason: 'No bash'), allowAll()],
      initialTrajectory: utf8.encode('traj-bytes'),
    );
    final config = event['agent_config'];
    expect(config['type'], 'antigravity');
    expect(config['app_data_dir'], '/tmp/appdata');
    expect(config['skills_paths'], ['/tmp/skills']);
    expect(config['enabled_hooks'], ['pre_turn', 'pre_tool', 'stop']);
    expect(config['compaction_config'], {'token_threshold': 50000});
    expect(config['finish_tool_output_schema'], {'type': 'object'});
    expect(config['agent_behavior'], 'interactive');
    expect(config['tool_output_truncation'], {
      'truncate': {'max_tokens': 4096},
    });
    expect(config['retry_config'], {
      'api_retry': {
        'max_retries': 4,
        'initial_sleep_duration_ms': 250,
        'exponential_multiplier': 2.0,
      },
      'model_output_retry': {'max_retries': 2},
    });
    expect(
        config['initial_trajectory'], base64Encode(utf8.encode('traj-bytes')));
    expect(config['workspaces'], [
      {
        'filesystem_workspace': {'directory': '/tmp/ws'},
      },
    ]);
    expect(config['models'], {
      'models': [
        {
          'name': 'gemini-2.5-pro',
          'types': ['text'],
          'gemini_api_endpoint': {
            'api_key': 'test-key',
            'options': {'thinking_level': 'high', 'service_tier': 'priority'},
          },
        },
        {
          'name': 'gemini-2.5-flash',
          'types': ['image'],
          'vertex_endpoint': {
            'base_url': 'https://us-central1-aiplatform.googleapis.com',
            'http_headers': {'X-Custom': '1'},
            'api_key': 'vertex-key',
            'project': 'my-proj',
            'location': 'us-central1',
            'options': {'thinking_level': 'low'},
          },
        },
      ],
    });
    expect(config['subagents_config']['allowed_subagents'], {
      'enumerated': {
        'names': ['helper'],
      },
    });
    expect(config['subagents_config']['max_nesting_depth'], 2);
    expect(config['subagents_config']['custom_subagents'], [
      {
        'name': 'helper',
        'description': 'Helper subagent',
        'tools': [
          {
            'type': 'filesystem',
            'supported_operations': ['file_read'],
          },
        ],
        'allowed_subagents': {'disabled': {}},
        'agent_behavior': 'autonomous',
      },
    ]);
    expect(config['budget_config'],
        {'max_model_calls': 10, 'scope': 'forward_looking'});
    expect(config['policy_config'], {
      'workspace_containment': 'disabled',
      'rules': [
        {
          'tool': 'run_command',
          'name': 'run_command',
          'decision': 'deny',
          'deny_reason': 'No bash',
        },
        {'tool': '*', 'name': 'allow_all', 'decision': 'allow'},
      ],
    });
  });

  test('workspaceOnly keeps containment and MCP rules split server names', () {
    final config = buildCreateInteractionEvent(policies: [
      workspaceOnly(['/tmp/ws']),
      allow('my_mcp/tool_a'),
      allowAll(),
    ])['agent_config']['policy_config'];
    expect(config, isNot(contains('workspace_containment')));
    expect(config['rules'], [
      for (final tool in BuiltinTools.fileTools())
        {'tool': tool.value, 'name': 'workspace_only', 'decision': 'deny'},
      {
        'server_name': 'my_mcp',
        'tool': 'tool_a',
        'name': 'my_mcp/tool_a',
        'decision': 'allow',
      },
      {'tool': '*', 'name': 'allow_all', 'decision': 'allow'},
    ]);
  });

  test('auto and dynamic policies are rejected', () {
    expect(() => buildCreateInteractionEvent(policies: [auto()]),
        throwsA(isA<AntigravityValidationException>()));
    expect(
        () => buildCreateInteractionEvent(policies: [
              deny('run_command',
                  when: (tc) => '${tc.args['CommandLine']}'.contains('rm')),
            ]),
        throwsA(isA<AntigravityValidationException>()));
    expect(
        () => buildCreateInteractionEvent(policies: [askUser('run_command')]),
        throwsA(isA<AntigravityValidationException>()));
  });

  test('prompt content becomes an input event', () {
    expect(contentToUserInputEvent('Hello\x00world'), {
      'event_type': 'input',
      'content': [
        {'type': 'text', 'text': 'Helloworld'},
      ],
    });
    expect(
        contentToUserInputEvent(
            SlashCommand(name: BuiltinSlashCommandName.plan)),
        {
          'event_type': 'input',
          'slash_command': {'name': 'plan'},
        });
    final png = utf8.encode('pngdata');
    expect(
        contentToUserInputEvent([
          'Describe this:',
          Image(mimeType: 'image/png', description: '', data: png),
        ]),
        {
          'event_type': 'input',
          'content': [
            {'type': 'text', 'text': 'Describe this:'},
            {
              'type': 'image',
              'mime_type': 'image/png',
              'data': base64Encode(png)
            },
          ],
        });
  });

  test('tool results become function_result events', () {
    expect(
        toolResultToFunctionResultEvent(
            callId: 'call-1', toolName: 'my_tool', result: {'sum': 42}),
        {
          'event_type': 'function_result',
          'call_id': 'call-1',
          'name': 'my_tool',
          'is_error': false,
          'result': {'sum': 42},
        });
    expect(
        toolResultToFunctionResultEvent(
            callId: 'call-2', toolName: 'my_tool', errorMessage: 'boom'),
        {
          'event_type': 'function_result',
          'call_id': 'call-2',
          'name': 'my_tool',
          'is_error': true,
          'result': 'boom',
        });
  });

  test('question responses become elicitation_result events', () {
    expect(
        questionResponsesToElicitationResultEvents(
          ['q-0', 'q-1'],
          responses: [
            QuestionResponse(
                selectedOptionIds: ['1'], freeformResponse: 'extra'),
            QuestionResponse(skipped: true),
          ],
        ),
        [
          {
            'event_type': 'elicitation_result',
            'elicitation_id': 'q-0',
            'multiple_choice': {
              'selected_choice_labels': ['1'],
              'user_input': [
                {'type': 'text', 'text': 'extra'},
              ],
            },
          },
          {
            'event_type': 'elicitation_result',
            'elicitation_id': 'q-1',
            'multiple_choice': {},
          },
        ]);
    expect(questionResponsesToElicitationResultEvents(['q-0'], responses: []), [
      {
        'event_type': 'elicitation_result',
        'elicitation_id': 'q-0',
        'multiple_choice': {},
      },
    ]);
    expect(
        questionResponsesToElicitationResultEvents(['q-0', 'q-1'],
            cancelled: true),
        [
          {
            'event_type': 'elicitation_result',
            'elicitation_id': 'q-0',
            'confirmation': {'is_confirmed': false},
          },
        ]);
  });

  test('cancel and complete events', () {
    expect(buildCancelInteractionEvent(), {'event_type': 'interaction.cancel'});
    expect(buildCompleteInteractionEvent(),
        {'event_type': 'interaction.complete'});
  });
}
