import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';

import 'types/exceptions.dart';

part 'models.mapper.dart';

// =============================================================================
// Constants
// =============================================================================

/// Default generative text model used when no model target is explicitly specified.
const String defaultModel = 'gemini-3.8-flash';

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
  /// Minimal thinking.
  minimal('minimal'),

  /// Low thinking.
  low('low'),

  /// Medium thinking.
  medium('medium'),

  /// High thinking.
  high('high'),

  /// Enables the highest reasoning capability level on compatible models.
  @MappableValue('extra_high')
  extraHigh('extra_high');

  /// The wire value of this level.
  final String value;

  /// Creates a [ThinkingLevel] with the given wire [value].
  const ThinkingLevel(this.value);

  /// Returns the [ThinkingLevel] whose wire value is [val].
  ///
  /// Returns [ThinkingLevel.minimal] if [val] is not recognized.
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
  /// Standard processing tier.
  standard('standard'),

  /// Prioritized inference tier.
  priority('priority'),

  /// Flex processing tier.
  flex('flex');

  /// The wire value of this tier.
  final String value;

  /// Creates a [ServiceTier] with the given wire [value].
  const ServiceTier(this.value);

  /// Returns the [ServiceTier] whose wire value is [val].
  ///
  /// Returns [ServiceTier.standard] if [val] is not recognized.
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
  /// A text generation model.
  text('text'),

  /// An image generation model.
  image('image');

  /// The wire value of this model type.
  final String value;

  /// Creates a [ModelType] with the given wire [value].
  const ModelType(this.value);
}

/// Base class for model endpoint authentication & routing.
@MappableClass(
  discriminatorKey: 'type',
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
)
abstract class ModelEndpoint with ModelEndpointMappable {
  /// Custom base URL for the model API, or null for the default.
  ///
  /// When set, [validateEndpoint] skips credential checks.
  final String? baseUrl;

  /// Extra HTTP headers sent with model requests.
  final Map<String, String>? httpHeaders;

  /// Returns the base URL as a strongly-typed Dart [Uri].
  Uri? get baseUri => baseUrl != null ? Uri.tryParse(baseUrl!) : null;

  /// Creates a [ModelEndpoint] with an optional [baseUrl] and
  /// [httpHeaders].
  ModelEndpoint({this.baseUrl, this.httpHeaders});

  /// Validates the configuration of the endpoint.
  void validateEndpoint();
}

/// Upper bound for [GeminiModelOptions.maxOutputTokens] (protobuf int32 max).
const int maxGeminiOutputTokens = 2147483647;

/// Gemini-specific model options.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class GeminiModelOptions with GeminiModelOptionsMappable {
  /// Thinking level for models that support extended thinking.
  final ThinkingLevel? thinkingLevel;

  /// Service tier for inference.
  final ServiceTier? serviceTier;

  /// Maximum number of output tokens the model may generate per step.
  ///
  /// Must be in `(0, 2147483647]` when specified. When null, the harness
  /// default (65,536 tokens) applies. Set a larger value for decodes longer
  /// than 64k tokens.
  final int? maxOutputTokens;

  /// Creates [GeminiModelOptions].
  ///
  /// Throws an [AntigravityValidationException] if [maxOutputTokens] is
  /// outside `(0, 2147483647]`.
  GeminiModelOptions({
    this.thinkingLevel,
    this.serviceTier,
    this.maxOutputTokens,
  }) {
    final tokens = maxOutputTokens;
    if (tokens != null && (tokens <= 0 || tokens > maxGeminiOutputTokens)) {
      throw AntigravityValidationException(
        'maxOutputTokens must be greater than 0 and at most '
        '$maxGeminiOutputTokens, got $tokens',
      );
    }
  }
}

/// Endpoint for the Gemini Developer API.
@MappableClass(
  discriminatorValue: 'gemini',
  caseStyle: CaseStyle.snakeCase,
  ignoreNull: true,
)
class GeminiAPIEndpoint extends ModelEndpoint with GeminiAPIEndpointMappable {
  /// Gemini API key.
  ///
  /// When null, the `GEMINI_API_KEY` environment variable must be set unless
  /// [baseUrl] is given.
  final String? apiKey;

  /// Gemini-specific model options.
  final GeminiModelOptions? options;

  /// Creates a [GeminiAPIEndpoint].
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
  /// Google Cloud project ID for Standard Mode.
  final String? project;

  /// Google Cloud location for Standard Mode.
  final String? location;

  /// API key for Vertex AI Express Mode.
  final String? apiKey;

  /// Gemini-specific model options.
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
  }) : project = (baseUrl != null && baseUrl.isNotEmpty)
           ? project
           : ((apiKey == null || apiKey.isEmpty)
                 ? (project ?? Platform.environment['GOOGLE_CLOUD_PROJECT'])
                 : project),
       location = (baseUrl != null && baseUrl.isNotEmpty)
           ? location
           : ((apiKey == null || apiKey.isEmpty)
                 ? (location ?? Platform.environment['GOOGLE_CLOUD_LOCATION'])
                 : location);

  @override
  void validateEndpoint() {
    if (baseUrl != null) {
      return; // External API, validation is done by the external API.
    }

    final hasRegionalAuth =
        (project != null && project!.isNotEmpty) &&
        (location != null && location!.isNotEmpty);
    final hasAnyRegionalArg =
        (project != null && project!.isNotEmpty) ||
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
  /// Model name, such as [defaultModel].
  final String? name;

  /// Purposes this model serves. Defaults to `[ModelType.text]`.
  final List<ModelType> types;

  /// Endpoint used to reach the model.
  ModelEndpoint? endpoint;

  /// Creates a [ModelTarget].
  ///
  /// [types] defaults to `[ModelType.text]` when null.
  ModelTarget({this.name, List<ModelType>? types, this.endpoint})
    : types = types ?? [ModelType.text];
}
