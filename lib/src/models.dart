import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

// =============================================================================
// Constants
// =============================================================================

const String defaultModel = 'gemini-3.5-flash';
const String defaultImageGenerationModel = 'gemini-3.1-flash-image-preview';

// =============================================================================
// Model types
// =============================================================================

/// Thinking level for Gemini models that support extended thinking.
///
/// Controls the amount of reasoning the model performs before responding.
/// See https://ai.google.dev/gemini-api/docs/thinking#thinking-levels for details.
@MappableEnum(defaultValue: ThinkingLevel.minimal)
enum ThinkingLevel {
  minimal('minimal'),
  low('low'),
  medium('medium'),
  high('high');

  final String value;
  const ThinkingLevel(this.value);

  static ThinkingLevel fromString(String val) {
    try {
      return ThinkingLevelMapper.fromValue(val);
    } catch (_) {
      return ThinkingLevel.minimal;
    }
  }
}

/// Discriminator for model purpose.
@MappableEnum()
enum ModelType {
  text('text'),
  image('image');

  final String value;
  const ModelType(this.value);
}

/// Base class for model endpoint authentication & routing.
@MappableClass(
  discriminatorKey: 'type',
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
)
abstract class ModelEndpoint with ModelEndpointMappable {
  final String? baseUrl;
  final Map<String, String>? httpHeaders;

  ModelEndpoint({this.baseUrl, this.httpHeaders});

  /// Validates the configuration of the endpoint.
  void validateEndpoint();
}

/// Gemini-specific model options.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class GeminiModelOptions with GeminiModelOptionsMappable {
  final ThinkingLevel? thinkingLevel;

  GeminiModelOptions({this.thinkingLevel});
}

/// Endpoint for the Gemini Developer API.
@MappableClass(
  discriminatorValue: 'gemini',
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
)
class GeminiAPIEndpoint extends ModelEndpoint with GeminiAPIEndpointMappable {
  final String? apiKey;
  final GeminiModelOptions? options;

  GeminiAPIEndpoint({
    super.baseUrl,
    super.httpHeaders,
    this.apiKey,
    this.options,
  });

  @override
  void validateEndpoint() {
    if (baseUrl != null) {
      return; // External API, validation is done by the external API.
    }

    if (apiKey == null && Platform.environment['GEMINI_API_KEY'] == null) {
      throw ArgumentError(
        'A Gemini API key is required. Set it via GEMINI_API_KEY environment '
        'variable or via LocalAgentConfig(apiKey: ...).',
      );
    }
  }
}

/// Endpoint for the Vertex AI backend.
@MappableClass(
  discriminatorValue: 'vertex',
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
)
class VertexEndpoint extends ModelEndpoint with VertexEndpointMappable {
  final String? project;
  final String? location;
  final GeminiModelOptions? options;

  VertexEndpoint({
    super.baseUrl,
    super.httpHeaders,
    this.project,
    this.location,
    this.options,
  });

  @override
  void validateEndpoint() {
    if (project == null || location == null) {
      throw ArgumentError(
        'For Vertex AI, a GCP project and location, or an API key (Express '
        'Mode), must be set.',
      );
    }
  }
}

/// Configuration for a single model.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ModelTarget with ModelTargetMappable {
  final String? name;
  final List<ModelType> types;
  ModelEndpoint? endpoint;

  ModelTarget({this.name, List<ModelType>? types, this.endpoint})
      : types = types ?? [ModelType.text];
}
