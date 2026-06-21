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

/// Example demonstrating system instructions in Google Antigravity SDK.
///
/// This example shows how to configure the agent's system instructions using both
/// templated and custom approaches.
///
/// Templated instructions are recommended for most users because they allow you to
/// leverage the default, highly-optimized system prompt provided by the SDK (which
/// includes critical rules for agent behavior) while still customizing the agent's
/// specific identity and adding application-specific guidelines. This ensures the
/// agent remains focused and organized without requiring you to recreate complex
/// infrastructure-level instructions from scratch.
///
/// Custom instructions, on the other hand, are NOT recommended for most users
/// because they completely bypass the default SDK scaffolding and dynamic
/// environmental context (such as active workspaces, available skills, and subagent
/// coordination rules). This is a 'break glass' advanced feature where you must
/// take full responsibility for manually compiling all environment and dynamic
/// paths inside Dart if they are needed by your custom System Prompt.
///
/// This example demonstrates:
/// 1. Using TemplatedSystemInstructions to override identity and add sections.
/// 2. Using CustomSystemInstructions to provide a full structured system prompt
///    when complete control is needed.
///
/// To run:
///   dart run example/getting_started/persona_config.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with return code 0 (no unhandled exceptions).
///   2. In the templated case, the agent reviews the code snippet and
///      provides actionable feedback (e.g. about naming conventions).
///   3. The agent uses the check_style_guide tool when reviewing code.
///   4. In the custom case, the agent also produces a meaningful code review
///      consistent with the custom reviewer persona.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:antigravity/antigravity.dart';

final checkStyleGuide = Tool(
  name: 'check_style_guide',
  description: 'Checks the style guide rules for a given language.',
  schema: {
    'type': 'object',
    'properties': {
      'language': {
        'type': 'string',
        'description': 'The programming language to check.',
      },
    },
    'required': ['language'],
  },
  handler: (args, _) async {
    final language = (args['language'] as String).toLowerCase();
    if (language == 'python') {
      return 'Use snake_case for functions and variables. Use CamelCase for classes.';
    }
    return 'No specific rules found.';
  },
);

Future<void> runTemplatedExample() async {
  print('  === Templated System Instructions Example ===');

  // Override the Identity (Persona)
  const identity = 'You are an expert Code Quality Reviewer.\n'
      'Your role is to review code for readability, maintainability, and adherence to style guides.';

  // Add custom sections. These sections are passed to the local harness as
  // structured sections (with a title and content) and are appended to the
  // default system instructions. Using titles helps organize the prompt
  // and makes it easier for the model to follow specific guidelines.
  final reviewCriteria = SystemInstructionSection(
    title: 'review_criteria',
    content: '- Focus on readability and simplicity.\n'
        '- Ensure meaningful variable and function names.',
  );

  // We explicitly reference the tool name `check_style_guide` here to guide the
  // model to use this specific tool when performing style reviews. This helps
  // ground the agent's behavior in the available toolset.
  final styleGuideInstructions = SystemInstructionSection(
    title: 'style_guide_instructions',
    content:
        'When reviewing Python code, use the `check_style_guide` tool to verify rules.',
  );

  final templatedSi = TemplatedSystemInstructions(
    identity: identity,
    sections: [reviewCriteria, styleGuideInstructions],
  );

  final config = LocalAgentConfig(
    systemInstructions: templatedSi,
    tools: [checkStyleGuide],
    policies: [denyAll(), allow('check_style_guide')],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'Review this Python code: `def MY_FUNCTION(X): return X*2`';
    print('  User: $prompt');
    final response = await agent.chat(prompt);
    print('  Agent: ${await response.text()}\n');
  } finally {
    await agent.stop();
  }
}

String buildSkillsInstructions(List<String> skillsPaths) {
  if (skillsPaths.isEmpty) return '';

  var instructions = '\n<skills>\n'
      'Skills enhance your abilities with specialized expertise and'
      ' repeatable workflows to help solve advanced workflows.\n'
      'When a task matches an available skill\'s description, you must inspect'
      ' the complete SKILL.md with your \'view_file\' tool in order to understand'
      ' its capabilities.\n\n'
      'Available skills:\n';

  for (final path in skillsPaths) {
    final skillName = p.basename(path);
    // NOTE: In a production implementation, you would dynamically parse the
    // 'description' field from the YAML frontmatter of the SKILL.md file on
    // disk. To keep this example concise and standalone, we use a static
    // description.
    instructions += '* **$skillName** (located at `$path/SKILL.md`) — Provides'
        ' guidelines for code readability, style compliance, and refactoring.\n';
  }
  instructions += '</skills>\n';
  return instructions;
}

Future<void> runCustomExample() async {
  print('  === Custom System Instructions Example ===');

  // Static Identity/Persona
  const identityText = '''
<identity>
You are an expert Code Quality Reviewer agent. Your goal is to help developers maintain high standards of readability, maintainability, and correctness in their code. You will receive code snippets or descriptions of code changes and provide actionable feedback. You must always prioritize addressing the user's specific questions or concerns about the code.
</identity>
''';

  // Dynamically gather workspace and app data directory info in Dart.
  // Under a complete override, the SDK's default environmental context is
  // omitted, so we manually construct and inject this context string into the
  // custom prompt.
  final cwd = Directory.current.path;
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final appDataDir = '$home/.gemini/antigravity';
  final userEncoding = Platform.operatingSystem;

  final userInfo = '''
<user_information>
Operating System: $userEncoding
Active Workspace CWD: $cwd
Storage Directory (App Data): $appDataDir
</user_information>
''';

  // Configure the active skill folders.
  // By default in the SDK, configured skill paths are dynamically prepended to
  // the turns. Under a custom override, we manually compile and append them.
  final skillPath = p.absolute('skills/google-antigravity-sdk');
  final skills = [skillPath];
  final skillsInstructions = buildSkillsInstructions(skills);

  // Standard structured guidelines & formatting rules text
  const guidelinesText = '''
<review_guidelines>
### When to recommend refactoring:
- The code has high cyclomatic complexity (too many nested loops/conditionals).
- The code violates DRY (Don't Repeat Yourself) principles significantly.
- The code is difficult to unit test in its current form.

### Don't recommend refactoring for:
- Minor personal style preferences that don't impact readability.
- Micro-optimizations that make the code harder to understand.
</review_guidelines>

<task_management>
### When to suggest breaking up the review:
- If the provided code snippet is longer than 200 lines.
- If the user is asking for both a security audit and a performance review at the same time.
In these cases, suggest reviewing one specific aspect or file first.
</task_management>

<behavioral_principles>
1. **Acknowledge Ambiguity**: If a request is underspecified or could be interpreted in multiple ways, ask the user for clarification before proceeding.
2. **Precision**: When suggesting code changes, always specify the file path and, if applicable, the line range.
3. **Focus on Delta**: Do not restate full file contents or large blocks of code unless necessary. Focus only on what needs to change.
4. **Closure**: End every turn with a clear summary of what was accomplished and what the next steps are.
</behavioral_principles>

<review_artifact_format>
When generating a detailed review artifact in Markdown, use the following elements to ensure high quality and scannability:

### Alerts
Use GitHub-style alerts to highlight critical issues:
> [!IMPORTANT]
> Critical security or correctness issues that must be fixed.

> [!NOTE]
> General improvements or style suggestions.

### Code Diffs
When suggesting changes, use diff blocks to show exactly what to add or remove:
```diff
-def old_func():
+def new_func():
```

### Tables
Use tables to compare alternative approaches or list multiple findings:
| File | Line | Issue | Severity |
| :--- | :--- | :--- | :--- |
| main.py | 12 | Hardcoded API key | Critical |
</review_artifact_format>

<tool_usage>
You have access to the `check_style_guide` tool. When reviewing Python code, always use this tool to verify language-specific style rules before making recommendations.
</tool_usage>
''';

  // Assemble the finalized custom system prompt string,
  // placing all static persona instructions, skills, and guidelines at the
  // top, with the dynamic workspace environment (UserInfo) at the bottom.
  final finalSiPrompt =
      identityText + skillsInstructions + guidelinesText + userInfo;

  final customSi = CustomSystemInstructions(text: finalSiPrompt);

  final config = LocalAgentConfig(
    systemInstructions: customSi,
    tools: [checkStyleGuide],
    skillsPaths: skills,
    policies: [denyAll(), allow('check_style_guide')],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt = 'Review this Python code: `def foo(x): return x+1`';
    print('  User: $prompt');
    final response = await agent.chat(prompt);
    print('  Agent: ${await response.text()}\n');
  } finally {
    await agent.stop();
  }
}

Future<void> main() async {
  await runTemplatedExample();
  await runCustomExample();
}
