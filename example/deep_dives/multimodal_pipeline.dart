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

/// Multimodal input and output with the Agent API in Dart.
///
/// Demonstrates a generator/discriminator pipeline using two independent
/// Agent instances:
///
///   1. **Generator** — creates an image using the built-in generate_image
///      tool and saves it to disk.
///
///   2. **Discriminator** — a completely separate Agent with no shared
///      history. Receives only the raw image bytes (no filename) via
///      multimodal Content input and describes what it sees.
///
/// Run with:
///   dart run example/deep_dives/multimodal_pipeline.dart
// ignore_for_file: avoid_print
library;

import 'dart:async';
import 'dart:io';
import 'package:antigravity/antigravity.dart';

void _header(String title) {
  print('\n${'=' * 60}');
  print('  $title');
  print('=' * 60);
}

Future<void> _streamResponse(ChatResponse response) async {
  await for (final chunk in response.textStream) {
    stdout.write(chunk);
    await stdout.flush();
  }
  print('');
}

File? _findGeneratedImage(String name) {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final dir = Directory('$home/.gemini/antigravity/brain');
  if (!dir.existsSync()) return null;

  try {
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains(name) && f.path.endsWith('.png'))
        .toList();

    if (files.isEmpty) return null;

    // Return the most recently modified one.
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.first;
  } catch (e) {
    print('Error searching generated images: $e');
    return null;
  }
}

Future<void> main() async {
  // ----------------------------------------------------------------
  // Phase 1: Generator — create an image
  // ----------------------------------------------------------------
  _header("Phase 1: Generator — creating image");

  final genConfig = LocalAgentConfig(
    systemInstructions:
        "You are an image generation assistant. When asked to generate an image, "
        "use the 'generate_image' tool. After the image is created, tell the "
        "user the image name and a one-line confirmation. Do not describe the image.",
    capabilities: CapabilitiesConfig(
      enabledTools: [BuiltinTools.generateImage],
    ),
    policies: [
      Policy(
        tool: BuiltinTools.generateImage.value,
        decision: Decision.approve,
        name: "allow-gen",
      ),
    ],
  );

  const prompt = "Generate an image of a white and orange Birman cat sitting "
      "in front of a fish-shaped birthday cake with lit candles. "
      "Name it 'birman_birthday'.";
  print('>>> $prompt\n');

  final generator = Agent(genConfig);
  await generator.start();

  try {
    final response = await generator.chat(prompt);
    await _streamResponse(response);
  } finally {
    await generator.stop();
  }

  // ----------------------------------------------------------------
  // Phase 2: Discriminator — describe the generated image
  // ----------------------------------------------------------------
  _header("Phase 2: Discriminator — describing image");

  final imageFile = _findGeneratedImage("birman_birthday");
  if (imageFile == null) {
    print("ERROR: Could not find generated image on disk.");
    print("The generate_image tool saves images as <name>_<ts>.png");
    print("under ~/.gemini/antigravity/brain/<conversation>/");
    return;
  }

  print("  Found image: ${imageFile.path}");
  print("  Size: ${imageFile.lengthSync()} bytes");

  final discConfig = LocalAgentConfig(
    systemInstructions:
        "You are a visual analysis assistant. You will receive an image with no "
        "prior context. Describe exactly what you see: subject matter, colors, "
        "lighting, mood, and any notable details. Be specific and vivid.",
  );

  // Load raw bytes — no filename leaks to the discriminator.
  final imageBytes = imageFile.readAsBytesSync();
  final image = Image(
    data: imageBytes,
    mimeType: "image/png",
    description: "Birman cat cake",
  );

  final List<dynamic> discPrompt = [
    "What do you see in this image? Describe it in detail.",
    image,
  ];
  print(">>> Sending raw image bytes to fresh agent...\n");

  final discriminator = Agent(discConfig);
  await discriminator.start();

  try {
    final response = await discriminator.chat(discPrompt);
    await _streamResponse(response);
  } finally {
    await discriminator.stop();
  }
}
