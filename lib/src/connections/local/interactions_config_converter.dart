// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Translates SDK configs and client inputs into GAOS Interactions JSON events.
library;

import 'dart:convert';
import 'dart:io';

import '../../hooks/hooks.dart';
import '../../hooks/policy.dart';
import '../../tools/schema_utils.dart';
import '../../tools/tool_runner.dart';
import '../../types.dart';

const _policyDecisionJson = {
  Decision.approve: 'allow',
  Decision.deny: 'deny',
  Decision.askUser: 'ask_user',
};

const _budgetScopeJson = {
  BudgetScope.lifetime: 'lifetime',
  BudgetScope.forwardLooking: 'forward_looking',
};

/// The empty JSON schema used for tools that declare no parameters.
Map<String, dynamic> _emptyParameters() =>
    {'type': 'object', 'properties': <String, dynamic>{}};

String _sanitizePrompt(String text) => text.replaceAll('\x00', '');

/// Converts a registered [Tool] into a GAOS Interactions function tool.
Map<String, dynamic> toolToFunctionToolDict(Tool tool) {
  return {
    'type': 'function',
    'name': tool.name,
    if (tool.description.isNotEmpty) 'description': tool.description,
    'parameters':
        normalizeSchema(tool.schema.isEmpty ? _emptyParameters() : tool.schema),
  };
}

Map<String, dynamic> _unresolvedFunctionTool(String name) =>
    {'type': 'function', 'name': name, 'parameters': _emptyParameters()};

void _translateSystemInstructions(
  dynamic instructions,
  Map<String, dynamic> target,
) {
  if (instructions == null ||
      (instructions is String && instructions.isEmpty)) {
    return;
  }
  if (instructions is String) {
    instructions = TemplatedSystemInstructions(
      sections: [SystemInstructionSection(content: instructions)],
    );
  }
  switch (instructions) {
    case CustomSystemInstructions(:final text):
      if (text.isNotEmpty) {
        target['developer_instructions'] = [
          {'type': 'text', 'text': text},
        ];
      }
    case TemplatedSystemInstructions(:final identity, :final sections):
      final appended = <String, dynamic>{
        if (identity != null && identity.isNotEmpty)
          'custom_identity': identity,
        if (sections.isNotEmpty)
          'appended_sections': [
            for (final s in sections) {'title': s.title, 'content': s.content},
          ],
      };
      if (appended.isNotEmpty) {
        target['appended_developer_instructions'] = appended;
      }
    default:
      throw ArgumentError(
          'Unsupported systemInstructions type: ${instructions.runtimeType}');
  }
}

Map<String, dynamic> _translateMcpServer(McpServerConfig server) {
  final timeout = server.timeoutSeconds;
  final mcp = <String, dynamic>{
    'type': 'mcp_server',
    'name': server.name,
    if (timeout != null && timeout > 0) 'timeout': '${timeout}s',
  };
  switch (server) {
    case McpStdioServer(:final command, :final args, :final env):
      mcp['stdio'] = {
        'command': command,
        if (args.isNotEmpty) 'args': List<String>.from(args),
        if (env != null && env.isNotEmpty) 'env': Map<String, String>.from(env),
      };
    case McpStreamableHttpServer(:final url, :final headers):
      mcp['http'] = {
        'url': url,
        if (headers != null && headers.isNotEmpty)
          'headers': Map<String, String>.from(headers),
      };
    default:
      throw ArgumentError(
          'Unknown McpServerConfig type: ${server.runtimeType}');
  }
  final enabled = server.enabledTools;
  final disabled = server.disabledTools;
  if (enabled != null && enabled.isNotEmpty) {
    mcp['allowed_tools'] = [
      {'mode': 'any', 'tools': List<String>.from(enabled)},
    ];
  } else if (disabled != null && disabled.isNotEmpty) {
    mcp['allowed_tools'] = [
      {'mode': 'none', 'tools': List<String>.from(disabled)},
    ];
  }
  return mcp;
}

/// Resolves active built-in tools, defaulting subagents to read-only tools.
Set<BuiltinTools> _resolveActiveTools(
  List<BuiltinTools>? enabledTools,
  List<BuiltinTools>? disabledTools,
) {
  if (enabledTools != null) return enabledTools.toSet();
  return BuiltinTools.defaultTools()
      .toSet()
      .difference(disabledTools?.toSet() ?? const {});
}

({List<Map<String, dynamic>> tools, Map<String, dynamic> policy})
    _translateCapabilities(
  Set<BuiltinTools> active,
  RunCommandConfig? runCommand,
) {
  final tools = <Map<String, dynamic>>[];
  if (active.contains(BuiltinTools.runCommand)) {
    final bash = <String, dynamic>{'type': 'bash'};
    if (runCommand != null) {
      final timeout = runCommand.timeoutSeconds;
      if (timeout != null) {
        final timeoutMs = (timeout * 1000).round();
        if (timeoutMs > 0) bash['max_timeout_ms'] = timeoutMs;
      }
      if (runCommand.enableDaemons) bash['enable_daemon_commands'] = true;
      if (runCommand.enableSandbox) bash['enable_sandbox'] = true;
    }
    tools.add(bash);
  }
  if (active.contains(BuiltinTools.runCommand) ||
      active.contains(BuiltinTools.schedule)) {
    tools.add({'type': 'manage_task'});
  }
  if (active.contains(BuiltinTools.schedule)) tools.add({'type': 'schedule'});
  if (active.contains(BuiltinTools.searchWeb)) {
    tools.add({'type': 'google_search'});
  }
  if (active.contains(BuiltinTools.readUrlContent)) {
    tools.add({'type': 'url_context'});
  }

  final fsOps = [
    if (active.contains(BuiltinTools.viewFile)) 'file_read',
    if (active.contains(BuiltinTools.createFile)) 'file_write',
    if (active.contains(BuiltinTools.editFile)) 'file_edit',
    if (active.contains(BuiltinTools.findFile)) 'file_find',
    if (active.contains(BuiltinTools.listDirectory)) 'directory_list',
    if (active.contains(BuiltinTools.searchDirectory)) 'file_grep',
  ];
  if (fsOps.isNotEmpty) {
    tools.add({'type': 'filesystem', 'supported_operations': fsOps});
  }

  final policy = <String, dynamic>{
    if (active.contains(BuiltinTools.askQuestion))
      'enable_user_questions': true,
    if (active.contains(BuiltinTools.generateImage))
      'enable_image_generation': true,
  };
  return (tools: tools, policy: policy);
}

Map<String, dynamic> _allowedSubagentsDict(
  bool enabled,
  List<String>? allowedNames,
) {
  if (!enabled) return {'disabled': <String, dynamic>{}};
  if (allowedNames != null && allowedNames.isNotEmpty) {
    return {
      'enumerated': {'names': List<String>.from(allowedNames)},
    };
  }
  return {'all': <String, dynamic>{}};
}

Map<String, dynamic>? _translateSubagentSkillsConfig(
    SubagentSkillsConfig? config) {
  if (config == null) return null;
  if (config.noneConfig != null) return {'none_config': <String, dynamic>{}};
  final inherit = config.inheritConfig;
  if (inherit != null) {
    return {
      'inherit_config': {
        if (inherit.skillNames.isNotEmpty)
          'skill_names': List<String>.from(inherit.skillNames),
        if (inherit.extraSkillsPaths.isNotEmpty)
          'extra_skills_paths': List<String>.from(inherit.extraSkillsPaths),
      },
    };
  }
  final override = config.overrideConfig;
  if (override != null) {
    if (override.inlineSkills.isNotEmpty) {
      throw AntigravityValidationException(
          'inlineSkills in SubagentOverrideSkillsConfig is not supported by '
          'InteractionsAgentConfig; use skillsPaths instead.');
    }
    return {
      'override_config': {
        if (override.skillsPaths.isNotEmpty)
          'skills_paths': List<String>.from(override.skillsPaths),
      },
    };
  }
  return null;
}

Map<String, dynamic> _translateCustomSubagent(
  SubagentConfig subagent,
  Map<String, Map<String, dynamic>> allToolDicts,
) {
  if (subagent.model != null) {
    throw AntigravityValidationException(
        "Subagent '${subagent.name}' sets 'model', which is not supported by "
        'InteractionsAgentConfig.');
  }
  final caps = subagent.capabilities ??
      SubagentCapabilities(enabledTools: BuiltinTools.readOnly());
  final result = <String, dynamic>{
    'name': subagent.name,
    if (subagent.description.isNotEmpty) 'description': subagent.description,
  };
  _translateSystemInstructions(subagent.systemInstructions, result);

  final resolvedTools = <Map<String, dynamic>>[];
  for (final tool in subagent.tools) {
    if (tool is String) {
      resolvedTools.add(allToolDicts[tool] ?? _unresolvedFunctionTool(tool));
    } else if (tool is Tool) {
      final dict = toolToFunctionToolDict(tool);
      allToolDicts[tool.name] = dict;
      resolvedTools.add(dict);
    } else {
      throw ArgumentError(
          "Invalid tool type in subagent '${subagent.name}' tools list: $tool");
    }
  }

  final active = _resolveActiveTools(caps.enabledTools, caps.disabledTools);
  final translated = _translateCapabilities(active, caps.runCommandConfig);
  final tools = [...resolvedTools, ...translated.tools];
  if (tools.isNotEmpty) result['tools'] = tools;
  if (translated.policy.isNotEmpty) result['policy'] = translated.policy;
  result['allowed_subagents'] = _allowedSubagentsDict(
    active.contains(BuiltinTools.startSubagent),
    caps.allowedSubagents,
  );
  result['agent_behavior'] = caps.agentBehavior.value;
  final skills = _translateSubagentSkillsConfig(subagent.skillsConfig);
  if (skills != null) result['skills_config'] = skills;
  return result;
}

Map<String, dynamic> _translateGeminiOptions(GeminiModelOptions? options) => {
      if (options?.thinkingLevel != null)
        'thinking_level': options!.thinkingLevel!.value,
      if (options?.serviceTier != null)
        'service_tier': options!.serviceTier!.value,
    };

Map<String, dynamic> _translateModelTarget(ModelTarget model) {
  final result = <String, dynamic>{
    'name': model.name ?? '',
    if (model.types.isNotEmpty) 'types': [for (final t in model.types) t.value],
  };
  switch (model.endpoint) {
    case GeminiAPIEndpoint ep:
      final opts = _translateGeminiOptions(ep.options);
      result['gemini_api_endpoint'] = {
        if (ep.baseUrl?.isNotEmpty ?? false) 'base_url': ep.baseUrl,
        if (ep.httpHeaders?.isNotEmpty ?? false)
          'http_headers': Map<String, String>.from(ep.httpHeaders!),
        if (ep.apiKey?.isNotEmpty ?? false) 'api_key': ep.apiKey,
        if (opts.isNotEmpty) 'options': opts,
      };
    case VertexEndpoint ep:
      final opts = _translateGeminiOptions(ep.options);
      result['vertex_endpoint'] = {
        if (ep.baseUrl?.isNotEmpty ?? false) 'base_url': ep.baseUrl,
        if (ep.httpHeaders?.isNotEmpty ?? false)
          'http_headers': Map<String, String>.from(ep.httpHeaders!),
        if (ep.project?.isNotEmpty ?? false) 'project': ep.project,
        if (ep.location?.isNotEmpty ?? false) 'location': ep.location,
        if (ep.apiKey?.isNotEmpty ?? false) 'api_key': ep.apiKey,
        if (opts.isNotEmpty) 'options': opts,
      };
    default:
      throw ArgumentError(
          'Unrecognized endpoint type: ${model.endpoint.runtimeType}');
  }
  return result;
}

/// Returns the GAOS lifecycle hook names that have handlers in [hookRunner].
List<String> interactionsEnabledHooks(HookRunner? hookRunner) {
  if (hookRunner == null) return const [];
  return [
    if (hookRunner.onSessionStartHooks.isNotEmpty) 'on_session_start',
    if (hookRunner.onSessionEndHooks.isNotEmpty) 'on_session_end',
    if (hookRunner.preTurnHooks.isNotEmpty) 'pre_turn',
    if (hookRunner.postTurnHooks.isNotEmpty) 'post_turn',
    if (hookRunner.preToolCallDecideHooks.isNotEmpty) 'pre_tool',
    if (hookRunner.postToolCallHooks.isNotEmpty) 'post_tool',
    if (hookRunner.onToolErrorHooks.isNotEmpty) 'on_tool_error',
    if (hookRunner.onCompactionHooks.isNotEmpty) 'on_compaction',
    if (hookRunner.stopHooks.isNotEmpty) 'stop',
  ];
}

/// Translates [policies] into a GAOS `PolicyConfig`.
///
/// Fails closed: [AutoPolicy] and dynamic rules (a `when` predicate or an
/// `askUser` decision) are not supported by the Interactions protocol.
Map<String, dynamic> _translatePolicyConfig(List<dynamic> policies) {
  final rules = <Map<String, dynamic>>[];
  var hasWorkspaceOnly = false;
  var hasAllowAll = false;
  for (final p in flattenPolicies(policies)) {
    if (p.auto) {
      throw AntigravityValidationException(
          'policy.auto() is not yet supported by the GAOS Interactions API '
          'protocol in localharness.');
    }
    final isWorkspaceOnly = p.name == workspaceOnlyPolicyName;
    hasWorkspaceOnly = hasWorkspaceOnly || isWorkspaceOnly;
    hasAllowAll = hasAllowAll ||
        (p.name == 'allow_all' &&
            p.tool == '*' &&
            p.decision == Decision.approve &&
            p.when == null);
    final isDynamic =
        (p.when != null || p.decision == Decision.askUser) && !isWorkspaceOnly;
    if (isDynamic) {
      throw AntigravityValidationException(
          "Dynamic policy rules (with 'when' predicates or 'askUser' "
          "handlers, such as '${p.name.isNotEmpty ? p.name : p.tool}') are not "
          'yet supported by the GAOS Interactions API protocol in '
          'localharness.');
    }
    final slash = p.tool == '*' ? -1 : p.tool.indexOf('/');
    final toolName = slash < 0 ? p.tool : p.tool.substring(slash + 1);
    final serverName = slash < 0 ? '' : p.tool.substring(0, slash);
    rules.add({
      if (toolName.isNotEmpty) 'tool': toolName,
      if (serverName.isNotEmpty) 'server_name': serverName,
      'name': p.name.isNotEmpty ? p.name : p.tool,
      'decision': _policyDecisionJson[p.decision],
      if (p.reason.isNotEmpty) 'deny_reason': p.reason,
    });
  }
  return {
    if (rules.isNotEmpty) 'rules': rules,
    if (hasAllowAll && !hasWorkspaceOnly) 'workspace_containment': 'disabled',
  };
}

Map<String, dynamic> _translateBudgetConfig(BudgetConfig budget) {
  bool positive(int? v) => v != null && v > 0;
  final result = <String, dynamic>{
    if (positive(budget.maxModelCalls)) 'max_model_calls': budget.maxModelCalls,
    if (positive(budget.maxToolCalls)) 'max_tool_calls': budget.maxToolCalls,
    if (positive(budget.maxInputTokens))
      'max_input_tokens': budget.maxInputTokens,
    if (positive(budget.maxOutputTokens))
      'max_output_tokens': budget.maxOutputTokens,
    if (positive(budget.maxTotalTokens))
      'max_total_tokens': budget.maxTotalTokens,
  };
  if (result.isEmpty) return result;
  result['scope'] = _budgetScopeJson[budget.scope];
  return result;
}

Map<String, dynamic> _translateRetryConfig(RetryConfig retry) {
  final api = retry.apiRetry?.toMap();
  final output = retry.modelOutputRetry?.toMap();
  return {
    if (api != null && api.isNotEmpty) 'api_retry': api,
    if (output != null && output.isNotEmpty) 'model_output_retry': output,
  };
}

/// Builds a GAOS `interaction.create` event from SDK configuration.
Map<String, dynamic> buildCreateInteractionEvent({
  List<ModelTarget>? models,
  dynamic systemInstructions,
  CapabilitiesConfig? capabilitiesConfig,
  CompactionConfig? compactionConfig,
  String? conversationId,
  SessionContinuationMode? sessionContinuationMode,
  List<String>? workspaces,
  List<String>? skillsPaths,
  String? appDataDir,
  List<McpServerConfig>? mcpServers,
  List<SubagentConfig>? subagents,
  RetryConfig? retryConfig,
  BudgetConfig? budgetConfig,
  List<dynamic>? policies,
  List<Object>? tools,
  ToolRunner? toolRunner,
  HookRunner? hookRunner,
  List<int>? initialTrajectory,
}) {
  final event = <String, dynamic>{
    'event_type': 'interaction.create',
    'agent': 'antigravity',
  };

  if (conversationId != null && conversationId.isNotEmpty) {
    switch (sessionContinuationMode) {
      case SessionContinuationMode.createOnly:
        event['interaction_id'] = conversationId;
      case SessionContinuationMode.resume:
        event['previous_interaction_id'] = conversationId;
      default:
        event['interaction_id'] = conversationId;
        event['previous_interaction_id'] = conversationId;
    }
  }

  _translateSystemInstructions(systemInstructions, event);

  final caps = capabilitiesConfig ?? CapabilitiesConfig();
  final allToolDicts = <String, Map<String, dynamic>>{
    for (final tool in toolRunner?.tools.values ?? const <Tool>[])
      tool.name: toolToFunctionToolDict(tool),
  };

  var rootTools = <Map<String, dynamic>>[];
  if (tools != null) {
    for (final tool in tools) {
      if (tool is String) {
        rootTools.add(allToolDicts[tool] ?? _unresolvedFunctionTool(tool));
      } else if (tool is Tool) {
        final dict = toolToFunctionToolDict(tool);
        allToolDicts[tool.name] = dict;
        rootTools.add(dict);
      }
    }
  } else if (toolRunner != null) {
    final subagentToolNames = {
      for (final sa in subagents ?? const <SubagentConfig>[])
        for (final t in sa.tools)
          if (t is String) t else if (t is Tool) t.name,
    };
    rootTools = [
      for (final entry in allToolDicts.entries)
        if (!subagentToolNames.contains(entry.key)) entry.value,
    ];
  }

  final active = _resolveActiveTools(caps.enabledTools, caps.disabledTools);
  final translated = _translateCapabilities(active, caps.runCommandConfig);
  final allTools = [
    ...rootTools,
    for (final s in mcpServers ?? const <McpServerConfig>[])
      _translateMcpServer(s),
    ...translated.tools,
  ];
  if (allTools.isNotEmpty) event['tools'] = allTools;

  final agentConfig = <String, dynamic>{'type': 'antigravity'};
  if (translated.policy.isNotEmpty) agentConfig['policy'] = translated.policy;

  final subagentsEnabled =
      caps.enableSubagents && active.contains(BuiltinTools.startSubagent);
  final customSubagents = subagents ?? const <SubagentConfig>[];
  if (subagentsEnabled || customSubagents.isNotEmpty) {
    final maxDepth = caps.maxSubagentDepth;
    agentConfig['subagents_config'] = {
      'allowed_subagents':
          _allowedSubagentsDict(subagentsEnabled, caps.allowedSubagents),
      if (maxDepth != null && maxDepth > 0) 'max_nesting_depth': maxDepth,
      if (customSubagents.isNotEmpty)
        'custom_subagents': [
          for (final sa in customSubagents)
            _translateCustomSubagent(sa, allToolDicts),
        ],
    };
  }

  if (models != null && models.isNotEmpty) {
    agentConfig['models'] = {
      'models': [for (final m in models) _translateModelTarget(m)],
    };
  }
  if (workspaces != null && workspaces.isNotEmpty) {
    agentConfig['workspaces'] = [
      for (final w in workspaces)
        {
          'filesystem_workspace': {
            'directory': Platform.isWindows ? w.replaceAll(r'\', '/') : w,
          },
        },
    ];
  }
  if (skillsPaths != null && skillsPaths.isNotEmpty) {
    agentConfig['skills_paths'] = List<String>.from(skillsPaths);
  }
  if (appDataDir != null && appDataDir.isNotEmpty) {
    agentConfig['app_data_dir'] = appDataDir;
  }
  final hooks = interactionsEnabledHooks(hookRunner);
  if (hooks.isNotEmpty) agentConfig['enabled_hooks'] = hooks;

  final threshold = (compactionConfig ??
          // ignore: deprecated_member_use_from_same_package
          (caps.compactionThreshold == null
              ? null
              // ignore: deprecated_member_use_from_same_package
              : CompactionConfig(tokenThreshold: caps.compactionThreshold)))
      ?.tokenThreshold;
  if (threshold != null && threshold > 0) {
    agentConfig['compaction_config'] = {'token_threshold': threshold};
  }

  final finishSchema = caps.finishToolSchemaJson;
  if (finishSchema != null && finishSchema.isNotEmpty) {
    agentConfig['finish_tool_output_schema'] = jsonDecode(finishSchema);
  }
  final truncation = caps.toolOutputTruncationConfig;
  if (truncation != null) {
    agentConfig['tool_output_truncation'] = {
      'truncate': {'max_tokens': truncation.maxTokens},
    };
  }
  if (retryConfig != null) {
    final retry = _translateRetryConfig(retryConfig);
    if (retry.isNotEmpty) agentConfig['retry_config'] = retry;
  }
  if (policies != null && policies.isNotEmpty) {
    final policy = _translatePolicyConfig(policies);
    if (policy.isNotEmpty) agentConfig['policy_config'] = policy;
  }
  if (budgetConfig != null) {
    final budget = _translateBudgetConfig(budgetConfig);
    if (budget.isNotEmpty) agentConfig['budget_config'] = budget;
  }
  agentConfig['agent_behavior'] = caps.agentBehavior.value;
  if (initialTrajectory != null && initialTrajectory.isNotEmpty) {
    agentConfig['initial_trajectory'] = base64Encode(initialTrajectory);
  }

  event['agent_config'] = agentConfig;
  return event;
}

Map<String, dynamic> _primitiveToContentDict(dynamic item) {
  if (item is String) return {'type': 'text', 'text': _sanitizePrompt(item)};
  if (item is MediaContent) {
    return {
      'type': switch (item) {
        Image() => 'image',
        Audio() => 'audio',
        Video() => 'video',
        Document() => 'document',
      },
      'mime_type': item.mimeType,
      'data': base64Encode(item.data),
    };
  }
  throw ArgumentError('Unsupported prompt content type: ${item.runtimeType}');
}

/// Converts SDK prompt content into a GAOS `input` event.
Map<String, dynamic> contentToUserInputEvent(ContentPrimitive content) {
  final items = content is List ? content : [content];
  if (items.length == 1 && items.single is SlashCommand) {
    return {
      'event_type': 'input',
      'slash_command': {'name': (items.single as SlashCommand).name.value},
    };
  }
  return {
    'event_type': 'input',
    'content': [for (final item in items) _primitiveToContentDict(item)],
  };
}

/// Builds a GAOS `function_result` event.
Map<String, dynamic> toolResultToFunctionResultEvent({
  required String callId,
  required String toolName,
  Map<String, dynamic>? result,
  String? errorMessage,
}) {
  return {
    'event_type': 'function_result',
    'call_id': callId,
    'name': toolName,
    'is_error': errorMessage != null,
    'result': errorMessage ?? result ?? <String, dynamic>{},
  };
}

/// Builds GAOS `elicitation_result` events answering question elicitations.
///
/// A cancelled batch is answered with a single declined confirmation for the
/// first elicitation, matching the harness's cancellation contract.
List<Map<String, dynamic>> questionResponsesToElicitationResultEvents(
  List<String> elicitationIds, {
  List<QuestionResponse>? responses,
  bool cancelled = false,
}) {
  if (cancelled) {
    if (elicitationIds.isEmpty) return const [];
    return [
      {
        'event_type': 'elicitation_result',
        'elicitation_id': elicitationIds.first,
        'confirmation': {'is_confirmed': false},
      },
    ];
  }
  return [
    for (var i = 0; i < elicitationIds.length; i++)
      {
        'event_type': 'elicitation_result',
        'elicitation_id': elicitationIds[i],
        'multiple_choice': _multipleChoice(
            responses != null && i < responses.length ? responses[i] : null),
      },
  ];
}

Map<String, dynamic> _multipleChoice(QuestionResponse? response) {
  if (response == null || response.skipped) return {};
  final selected = response.selectedOptionIds;
  return {
    if (selected != null && selected.isNotEmpty)
      'selected_choice_labels': List<String>.from(selected),
    if (response.freeformResponse.isNotEmpty)
      'user_input': [
        {'type': 'text', 'text': response.freeformResponse},
      ],
  };
}

/// Builds a GAOS event cancelling the current turn.
Map<String, dynamic> buildCancelInteractionEvent() =>
    {'event_type': 'interaction.cancel'};

/// Builds a GAOS event completing the session.
Map<String, dynamic> buildCompleteInteractionEvent() =>
    {'event_type': 'interaction.complete'};
