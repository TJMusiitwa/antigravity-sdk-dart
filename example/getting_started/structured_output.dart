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

/// Example demonstrating native structured output from an agent.
///
/// This example shows how to configure the agent to return a strongly-typed,
/// validated JSON payload (modelled via a plain Dart [Map] schema) instead of
/// raw, unstructured conversational text.
///
/// When and Why to Use Structured Output:
/// - **Programmatic Downstream Consumption**: When agent output feeds databases,
///   APIs, or workflows directly (e.g. populating a task manager).
/// - **Strict Schema Validation**: To ensure type safety, required fields, and
///   data constraints on model outputs without fragile regex parsing.
/// - **Native Guidance**: A configured [responseSchema] natively guides the
///   underlying model to match the schema perfectly.
///
/// In this example the agent retrieves raw meeting notes via a custom mock tool
/// and distils them into a structured [MeetingSummary] with action items.
///
/// To run:
///   dart run example/getting_started/structured_output.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent calls fetch_unstructured_meeting_notes to retrieve notes.
///   3. The structured output contains action items with assignees and tasks.
///   4. Each action item includes assignee, task, and deadline fields.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// Schema definition (equivalent to Pydantic models in Python)
// ---------------------------------------------------------------------------

/// JSON Schema for a single action item.
const _actionItemSchema = {
  'type': 'object',
  'properties': {
    'assignee': {
      'type': 'string',
      'description': 'The person assigned to the action item.',
    },
    'task': {
      'type': 'string',
      'description': 'A description of the task to be completed.',
    },
    'deadline': {
      'type': 'string',
      'description': 'The date by which the task should be completed.',
    },
  },
  'required': ['assignee', 'task', 'deadline'],
};

/// JSON Schema for the overall meeting summary.
const meetingSummarySchema = {
  'type': 'object',
  'properties': {
    'action_items': {
      'type': 'array',
      'items': _actionItemSchema,
      'description': 'A list of action items generated from the meeting.',
    },
  },
  'required': ['action_items'],
};

// ---------------------------------------------------------------------------
// Mock tool
// ---------------------------------------------------------------------------

final fetchMeetingNotesTool = Tool(
  name: 'fetch_unstructured_meeting_notes',
  description: 'Retrieves the raw unstructured notes for a given meeting ID.',
  schema: {
    'type': 'object',
    'properties': {
      'meeting_id': {
        'type': 'string',
        'description': 'The meeting ID to retrieve notes for.',
      },
    },
    'required': ['meeting_id'],
  },
  handler: (args, _) async {
    final meetingId = args['meeting_id'] as String;
    if (meetingId == 'meeting-2026-05') {
      return 'Discussed launch timeline for project X. Alice agreed to update '
          'the textproto tests by Monday. Bob mentioned he will run the final '
          'E2E benchmarks tomorrow. I will push the release build once the '
          'tests are green.';
    }
    return 'Error: Meeting notes not found.';
  },
);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  print('  --- Starting main ---');

  final config = LocalAgentConfig(
    tools: [fetchMeetingNotesTool],
    responseSchema: meetingSummarySchema,
  );

  final agent = Agent(config);
  await agent.start();

  try {
    const prompt =
        "Use the fetch_unstructured_meeting_notes tool to retrieve notes for "
        "'meeting-2026-05' and return the meeting summary with the appropriate "
        "action item list. Ensure each action item includes 'assignee', "
        "'task', and 'deadline'.";

    print('\n  Sending prompt to agent…');
    final response = await agent.chat(prompt);

    print('\n  Extracting structured meeting action items…');

    // Retrieve the structured JSON output from the completed response.
    final data = await response.structuredOutput() as Map<String, dynamic>?;

    if (data == null) {
      final rawText = await response.text();
      print('\n  Failed to extract structured summary natively.');
      print('  Final Text Response: $rawText');
      return;
    }

    print('\n  === Structured Meeting Action Items ===');
    for (final item in (data['action_items'] as List<dynamic>)) {
      final m = item as Map<String, dynamic>;
      print('  - Assignee: ${m['assignee']}');
      print('    Task:     ${m['task']}');
      print('    Deadline: ${m['deadline']}\n');
    }
  } finally {
    await agent.stop();
  }
}
