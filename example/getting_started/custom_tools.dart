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

/// Example demonstrating custom tools and stateful tools with [ToolContext].
///
/// This example shows:
/// 1. How to define a simple custom tool.
/// 2. How to define a stateful tool using [ToolContext] to maintain state
///    across turns.
///
/// To run:
///   dart run example/getting_started/custom_tools.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent calls the lookup_fruit_sku tool and returns an SKU value.
///   3. The agent calls the record_fruit tool across multiple turns,
///      maintaining running totals.
///   4. The agent produces meaningful text responses for each turn.
// ignore_for_file: avoid_print
library;

import 'package:antigravity/antigravity.dart';

// ---------------------------------------------------------------------------
// 1. A simple stateless tool
// ---------------------------------------------------------------------------
final lookupFruitSku = Tool(
  name: 'lookup_fruit_sku',
  description: 'Looks up the SKU for a given fruit.',
  schema: {
    'type': 'object',
    'properties': {
      'fruit_name': {'type': 'string', 'description': 'The name of the fruit.'},
    },
    'required': ['fruit_name'],
  },
  handler: (args, _) async {
    final skus = {
      'apple': 'SKU-APP-123',
      'banana': 'SKU-BAN-456',
      'orange': 'SKU-ORA-789',
    };
    var name = (args['fruit_name'] as String).toLowerCase();
    if (name.endsWith('s') && !skus.containsKey(name)) {
      name = name.substring(0, name.length - 1);
    }
    final sku = skus[name] ?? 'SKU-GEN-000';
    return 'SKU for ${args['fruit_name']} is $sku. '
        'Order ID for restocking: ORD-$sku-NEW';
  },
);

// ---------------------------------------------------------------------------
// 2. A stateful tool — maintains fruit counts across turns via ToolContext
// ---------------------------------------------------------------------------
final recordFruit = Tool(
  name: 'record_fruit',
  description: 'Records the count of fruits by SKU.',
  schema: {
    'type': 'object',
    'properties': {
      'sku': {'type': 'string', 'description': 'The SKU of the fruit.'},
      'count': {
        'type': 'integer',
        'description': 'The number of fruits to record.',
      },
    },
    'required': ['sku', 'count'],
  },
  handler: (args, ctx) async {
    final sku = args['sku'] as String;
    final count = args['count'] as int;

    // Retrieve current state or initialize if not present.
    final currentCounts = Map<String, int>.from(
      (ctx?.getState('fruit_counts') as Map<String, dynamic>? ?? {}),
    );
    currentCounts[sku] = (currentCounts[sku] ?? 0) + count;
    ctx?.setState('fruit_counts', currentCounts);

    final total = currentCounts[sku]!;
    return 'Recorded $count units for $sku. Total count is now $total.';
  },
);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
Future<void> main() async {
  final config = LocalAgentConfig(
    tools: [lookupFruitSku, recordFruit],
    systemInstructions:
        'You keep track of fruit inventory. To record fruits, '
        'you MUST first look up the fruit\'s SKU using lookup_fruit_sku, and '
        'then use that SKU with record_fruit.',
    policies: [
      // Deny everything by default so only the tools below are allowed.
      denyAll(),
      allow('lookup_fruit_sku'),
      allow('record_fruit'),
    ],
  );

  final agent = Agent(config);
  await agent.start();

  try {
    print('  === Custom Tools Demo ===');

    // Test simple stateless tool.
    const prompt1 = 'What is the SKU for apples? We need to order more.';
    print('\n  User: $prompt1');
    final response1 = await agent.chat(prompt1);
    print('  Agent: ${await response1.text()}');

    // Test stateful tool.
    print('\n  === Stateful Tool (Fruit Counter) Demo ===');

    final turns = [
      'I have 5 apples.',
      'And I just got 3 bananas.',
      'Oh, and another 2 apples.',
    ];

    for (final userInput in turns) {
      print('\n  User: $userInput');
      final response = await agent.chat(userInput);
      print('  Agent: ${await response.text()}');
    }
  } finally {
    await agent.stop();
  }
}
