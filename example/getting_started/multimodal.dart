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

/// Multimodal example for the unofficial Dart Antigravity SDK.
///
/// This example demonstrates:
/// - Multimodal input: passing images and documents to the agent.
/// - Multimodal output: enabling the agent to generate images.
///
/// To run:
///   dart run example/getting_started/multimodal.dart
///
/// Criteria for correct script performance:
///   1. The script exits cleanly with no unhandled exceptions.
///   2. The agent produces a non-empty description of the provided image.
///   3. The agent produces a non-empty summary of the provided document.
///   4. The agent attempts to generate an image when asked.
// ignore_for_file: avoid_print
library;

import 'dart:io';
import 'package:antigravity/antigravity.dart';

Future<void> main() async {
  // Set up paths to bundled example resources (relative to this file's location).
  final scriptDir = File(Platform.script.toFilePath()).parent;
  final resourcesDir = Directory('${scriptDir.path}/../resources');
  final imagePath = '${resourcesDir.path}/example_image.png';
  final docPath = '${resourcesDir.path}/sample_doc.txt';

  // ---------------------------------------------------------------------------
  // Multimodal Input: Image
  // ---------------------------------------------------------------------------
  print('  --- Multimodal Input: Image ---');
  {
    final config = LocalAgentConfig();
    final agent = Agent(config);
    await agent.start();
    try {
      // Use the Image subclass of MediaContent.
      final image = Image(
        mimeType: 'image/png',
        data: File(imagePath).readAsBytesSync(),
        description: 'example image',
      );
      // Prompts can be a List containing strings and MediaContent objects.
      final prompt = ['What is in this image?', image];
      print('  User: ${prompt.first}');
      final response = await agent.chat(prompt);
      print('  Agent: ${await response.text()}\n');
    } finally {
      await agent.stop();
    }
  }

  // ---------------------------------------------------------------------------
  // Multimodal Input: Document
  // ---------------------------------------------------------------------------
  print('  --- Multimodal Input: Document ---');
  {
    final config = LocalAgentConfig();
    final agent = Agent(config);
    await agent.start();
    try {
      // Use the Document subclass of MediaContent.
      final doc = Document(
        mimeType: 'text/plain',
        data: File(docPath).readAsBytesSync(),
        description: 'sample document',
      );
      final prompt = ['Summarize this document', doc];
      print('  User: ${prompt.first}');
      final response = await agent.chat(prompt);
      print('  Agent: ${await response.text()}\n');
    } finally {
      await agent.stop();
    }
  }

  // ---------------------------------------------------------------------------
  // Multimodal Output: Image Generation
  // ---------------------------------------------------------------------------
  print('  --- Multimodal Output: Image Generation ---');
  {
    final config = LocalAgentConfig(
      capabilities: CapabilitiesConfig(
        enabledTools: [BuiltinTools.generateImage],
      ),
    );
    final agent = Agent(config);
    await agent.start();
    try {
      const prompt =
          "Generate an image of a futuristic city, name it 'future_city'. "
          'Please provide the file path to the generated image.';
      print('  User: $prompt');
      final response = await agent.chat(prompt);
      print('  Agent: ${await response.text()}\n');
    } finally {
      await agent.stop();
    }
  }
}
