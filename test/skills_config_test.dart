import 'dart:convert';

import 'package:antigravity/antigravity.dart';
import 'package:test/test.dart';

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
}
