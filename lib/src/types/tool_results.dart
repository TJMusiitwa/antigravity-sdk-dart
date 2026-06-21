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

/// Structured tool result types returned by the local harness backend.
///
/// These mirror the Python SDK's `connections/local/types.py` and let callers
/// inspect harness tool output with proper typing rather than raw [Map]s.
library;

/// Structured result from a `generate_image` tool execution.
///
/// Returned in [ToolResult.structuredOutput] when the agent uses the
/// [BuiltinTools.generateImage] tool.
///
/// Example:
/// ```dart
/// final output = result.structuredOutput;
/// if (output is GenerateImageResult) {
///   print('Image: ${output.imageName} (${output.aspectRatio})');
/// }
/// ```
class GenerateImageResult {
  /// The name of the generated image artifact (without extension).
  final String imageName;

  /// The aspect ratio used for image generation (e.g. `'16:9'`, `'1:1'`).
  ///
  /// Empty string if no aspect ratio was specified.
  final String aspectRatio;

  const GenerateImageResult({
    this.imageName = '',
    this.aspectRatio = '',
  });

  /// Creates a [GenerateImageResult] from a raw harness response map.
  factory GenerateImageResult.fromMap(Map<String, dynamic> map) {
    return GenerateImageResult(
      imageName: (map['image_name'] ?? map['imageName'] ?? '').toString(),
      aspectRatio: (map['aspect_ratio'] ?? map['aspectRatio'] ?? '').toString(),
    );
  }

  @override
  String toString() => imageName;
}

/// Structured result from a `search_web` tool execution.
///
/// Returned in [ToolResult.structuredOutput] when the agent uses the
/// [BuiltinTools.searchWeb] tool.
class SearchWebResult {
  /// A summarized answer derived from web search results.
  final String summary;

  const SearchWebResult({this.summary = ''});

  /// Creates a [SearchWebResult] from a raw harness response map.
  factory SearchWebResult.fromMap(Map<String, dynamic> map) {
    return SearchWebResult(
      summary: (map['summary'] ?? '').toString(),
    );
  }

  @override
  String toString() => summary;
}
