import 'package:dart_mappable/dart_mappable.dart';
import 'exceptions.dart';

part 'capabilities.mapper.dart';

/// Identifiers for common connection-provided builtin tools.
@MappableEnum()
enum BuiltinTools {
  @MappableValue('list_directory')
  listDirectory('list_directory'),
  @MappableValue('search_directory')
  searchDirectory('search_directory'),
  @MappableValue('find_file')
  findFile('find_file'),
  @MappableValue('view_file')
  viewFile('view_file'),
  @MappableValue('create_file')
  createFile('create_file'),
  @MappableValue('edit_file')
  editFile('edit_file'),
  @MappableValue('run_command')
  runCommand('run_command'),
  @MappableValue('ask_question')
  askQuestion('ask_question'),
  @MappableValue('start_subagent')
  startSubagent('start_subagent'),
  @MappableValue('generate_image')
  generateImage('generate_image'),
  @MappableValue('search_web')
  searchWeb('search_web'),
  @MappableValue('read_url_content')
  readUrlContent('read_url_content'),
  @MappableValue('finish')
  finish('finish');

  final String value;
  const BuiltinTools(this.value);

  static List<BuiltinTools> readOnly() {
    return [
      listDirectory,
      searchDirectory,
      findFile,
      viewFile,
      readUrlContent,
      finish
    ];
  }

  static List<BuiltinTools> nondestructive() {
    return [
      listDirectory,
      searchDirectory,
      findFile,
      viewFile,
      createFile,
      editFile,
      askQuestion,
      startSubagent,
      generateImage,
      searchWeb,
      readUrlContent,
      finish,
    ];
  }

  static List<BuiltinTools> fileTools() {
    return [viewFile, createFile, editFile];
  }

  static List<BuiltinTools> allTools() {
    return BuiltinTools.values;
  }
}

/// General agent capability configuration.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class CapabilitiesConfig with CapabilitiesConfigMappable {
  final bool enableSubagents;
  final List<BuiltinTools>? enabledTools;
  final List<BuiltinTools>? disabledTools;
  final int? compactionThreshold;
  String? finishToolSchemaJson;

  CapabilitiesConfig({
    this.enableSubagents = true,
    this.enabledTools,
    this.disabledTools,
    this.compactionThreshold,
    this.finishToolSchemaJson,
  }) {
    if (enabledTools != null && disabledTools != null) {
      throw AntigravityValidationException(
        'enabledTools and disabledTools are mutually exclusive.',
      );
    }
  }

  factory CapabilitiesConfig.fromMap(Map<String, dynamic> map) =>
      CapabilitiesConfigMapper.fromMap(map);
  factory CapabilitiesConfig.fromJson(String json) =>
      CapabilitiesConfigMapper.fromJson(json);
}
