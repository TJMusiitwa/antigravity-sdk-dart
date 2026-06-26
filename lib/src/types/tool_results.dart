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

/// Structured result from a `read_url_content` tool execution.
///
/// Returned in [ToolResult.structuredOutput] when the agent uses the
/// [BuiltinTools.readUrlContent] tool.
class ReadUrlContentResult {
  /// The title of the web page.
  final String title;

  /// A summarized answer derived from the page content.
  final String summary;

  /// The path to the stored content.
  final String contentPath;

  const ReadUrlContentResult({
    this.title = '',
    this.summary = '',
    this.contentPath = '',
  });

  /// Creates a [ReadUrlContentResult] from a raw harness response map.
  factory ReadUrlContentResult.fromMap(Map<String, dynamic> map) {
    return ReadUrlContentResult(
      title: (map['title'] ?? '').toString(),
      summary: (map['summary'] ?? '').toString(),
      contentPath: (map['content_path'] ?? map['contentPath'] ?? '').toString(),
    );
  }

  @override
  String toString() => summary.isNotEmpty
      ? summary
      : title.isNotEmpty
          ? title
          : contentPath;
}

/// Structured result from a `run_command` tool execution.
class RunCommandResult {
  /// The combined stdout and stderr output.
  final String output;

  const RunCommandResult({this.output = ''});

  factory RunCommandResult.fromMap(Map<String, dynamic> map) {
    return RunCommandResult(
      output:
          (map['combined_output'] ?? map['combinedOutput'] ?? '').toString(),
    );
  }

  @override
  String toString() => output;
}

/// A single entry in a `list_directory` result.
class ListDirectoryEntry {
  /// The name of the file or directory.
  final String name;

  /// Whether the entry is a directory.
  final bool isDirectory;

  /// The file size in bytes.
  final int fileSize;

  const ListDirectoryEntry({
    this.name = '',
    this.isDirectory = false,
    this.fileSize = 0,
  });

  factory ListDirectoryEntry.fromMap(Map<String, dynamic> map) {
    return ListDirectoryEntry(
      name: (map['name'] ?? '').toString(),
      isDirectory: map['is_directory'] == true || map['isDirectory'] == true,
      fileSize: int.tryParse(
              (map['file_size'] ?? map['fileSize'] ?? '0').toString()) ??
          0,
    );
  }
}

/// Structured result from a `list_directory` tool execution.
class ListDirectoryResult {
  /// The list of entries in the directory.
  final List<ListDirectoryEntry> entries;

  const ListDirectoryResult({this.entries = const []});

  factory ListDirectoryResult.fromMap(Map<String, dynamic> map) {
    final results = map['results'] as List?;
    if (results == null) {
      return const ListDirectoryResult();
    }
    final entries = results.map((r) {
      if (r is Map) {
        return ListDirectoryEntry.fromMap(Map<String, dynamic>.from(r));
      }
      return const ListDirectoryEntry();
    }).toList();
    return ListDirectoryResult(entries: entries);
  }

  @override
  String toString() => entries.map((e) => e.name).join('\n');
}

/// Structured result from a `find_file` tool execution.
class FindFileResult {
  /// The list of matched paths separated by newlines.
  final String output;

  const FindFileResult({this.output = ''});

  factory FindFileResult.fromMap(Map<String, dynamic> map) {
    return FindFileResult(
      output: (map['output'] ?? '').toString(),
    );
  }

  @override
  String toString() => output;
}

/// Structured result from a `search_directory` tool execution.
class SearchDirectoryResult {
  /// The number of matching results found.
  final int numResults;

  const SearchDirectoryResult({this.numResults = 0});

  factory SearchDirectoryResult.fromMap(Map<String, dynamic> map) {
    return SearchDirectoryResult(
      numResults: int.tryParse(
              (map['num_results'] ?? map['numResults'] ?? '0').toString()) ??
          0,
    );
  }

  @override
  String toString() => '$numResults results';
}

/// Structured result from an `edit_file` tool execution.
class EditFileResult {
  /// A summary of the edit changes.
  final String summary;

  const EditFileResult({this.summary = ''});

  factory EditFileResult.fromMap(Map<String, dynamic> map) {
    return EditFileResult(
      summary: (map['summary'] ?? '').toString(),
    );
  }

  @override
  String toString() => summary;
}
