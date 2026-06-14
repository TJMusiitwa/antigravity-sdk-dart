import 'package:dart_mappable/dart_mappable.dart';

part 'config.mapper.dart';

const String defaultModel = 'gemini-3.5-flash';
const String defaultImageGenerationModel = 'gemini-3.1-flash-image-preview';

/// Thinking level for Gemini models that support extended thinking.
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

/// Generation parameters for a model.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class GenerationConfig with GenerationConfigMappable {
  final ThinkingLevel? thinkingLevel;

  GenerationConfig({this.thinkingLevel});

  static const fromMap = GenerationConfigMapper.fromMap;
  static const fromJson = GenerationConfigMapper.fromJson;
}

/// A model with optional auth and generation overrides.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ModelEntry with ModelEntryMappable {
  final String name;
  final String? apiKey;
  final GenerationConfig generation;

  ModelEntry({required this.name, this.apiKey, GenerationConfig? generation})
    : generation = generation ?? GenerationConfig();

  static const fromMap = ModelEntryMapper.fromMap;
  static const fromJson = ModelEntryMapper.fromJson;
}

/// Model selection for each capability.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class ModelConfig with ModelConfigMappable {
  @MappableField(key: 'default')
  final ModelEntry defaultModelEntry;

  @MappableField(key: 'image_generation')
  final ModelEntry imageGenerationModelEntry;

  ModelConfig({
    ModelEntry? defaultModelEntry,
    ModelEntry? imageGenerationModelEntry,
  }) : defaultModelEntry = defaultModelEntry ?? ModelEntry(name: defaultModel),
       imageGenerationModelEntry =
           imageGenerationModelEntry ??
           ModelEntry(name: defaultImageGenerationModel);

  static const fromMap = ModelConfigMapper.fromMap;
  static const fromJson = ModelConfigMapper.fromJson;
}

/// Configuration for the Gemini model backend.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class GeminiConfig with GeminiConfigMappable {
  final String? apiKey;
  final bool vertex;
  final String? project;
  final String? location;
  final ModelConfig models;

  GeminiConfig({
    this.apiKey,
    this.vertex = false,
    this.project,
    this.location,
    ModelConfig? models,
  }) : models = models ?? ModelConfig();

  static const fromMap = GeminiConfigMapper.fromMap;
  static const fromJson = GeminiConfigMapper.fromJson;
}
