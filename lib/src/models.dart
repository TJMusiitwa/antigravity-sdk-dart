import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import 'types/exceptions.dart';

part 'models.mapper.dart';

// =============================================================================
// Constants
// =============================================================================

/// Default generative text model used when no model target is explicitly specified.
const String defaultModel = 'gemini-3.7-flash';

/// Default image generation model used by built-in image creation tools.
const String defaultImageGenerationModel = 'gemini-3.1-flash-lite-image';

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
  high('high'),

  /// Enables the highest reasoning capability level on compatible models.
  @MappableValue('extra_high')
  extraHigh('extra_high');

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

/// Service tier for Gemini model inference.
///
/// Controls the compute queue priority and rate limit fallback behavior.
/// See https://ai.google.dev/gemini-api/docs/priority-inference for details.
@MappableEnum(defaultValue: ServiceTier.standard)
enum ServiceTier {
  standard('standard'),
  priority('priority'),
  flex('flex');

  final String value;
  const ServiceTier(this.value);

  static ServiceTier fromString(String val) {
    try {
      return ServiceTierMapper.fromValue(val);
    } catch (_) {
      return ServiceTier.standard;
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

  /// Returns the base URL as a strongly-typed Dart [Uri].
  Uri? get baseUri => baseUrl != null ? Uri.tryParse(baseUrl!) : null;

  ModelEndpoint({this.baseUrl, this.httpHeaders});

  /// Validates the configuration of the endpoint.
  void validateEndpoint();
}

/// Gemini-specific model options.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class GeminiModelOptions with GeminiModelOptionsMappable {
  final ThinkingLevel? thinkingLevel;
  final ServiceTier? serviceTier;

  GeminiModelOptions({this.thinkingLevel, this.serviceTier});
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
      throw AntigravityValidationException(
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
  final String? apiKey;
  final GeminiModelOptions? options;

  /// Creates a new [VertexEndpoint] targeting Google Vertex AI.
  ///
  /// Supports two authentication modes:
  /// 1. Express Mode: Pass [apiKey] directly to authenticate with Vertex AI Express Mode.
  /// 2. Standard Mode: Pass [project] and [location] (or load from `GOOGLE_CLOUD_PROJECT`
  ///    and `GOOGLE_CLOUD_LOCATION` environment variables).
  VertexEndpoint({
    super.baseUrl,
    super.httpHeaders,
    String? project,
    String? location,
    this.apiKey,
    this.options,
  })  : project = (apiKey == null || apiKey.isEmpty)
            ? (project ?? Platform.environment['GOOGLE_CLOUD_PROJECT'])
            : project,
        location = (apiKey == null || apiKey.isEmpty)
            ? (location ?? Platform.environment['GOOGLE_CLOUD_LOCATION'])
            : location;

  @override
  void validateEndpoint() {
    if (baseUrl != null) {
      return; // External API, validation is done by the external API.
    }

    final hasRegionalAuth = (project != null && project!.isNotEmpty) &&
        (location != null && location!.isNotEmpty);
    final hasAnyRegionalArg = (project != null && project!.isNotEmpty) ||
        (location != null && location!.isNotEmpty);
    final hasExpressAuth = apiKey != null && apiKey!.isNotEmpty;

    if (hasAnyRegionalArg && hasExpressAuth) {
      throw AntigravityValidationException(
        'Cannot specify both apiKey (Express Mode) and project/location (Standard Mode) on VertexEndpoint.',
      );
    }

    if (!(hasRegionalAuth || hasExpressAuth)) {
      throw AntigravityValidationException(
        'For Vertex AI, either (project and location) or apiKey must be set.',
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
