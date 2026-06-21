import 'package:dart_mappable/dart_mappable.dart';

import 'capabilities.dart';

part 'config.mapper.dart';

/// Capabilities configuration for subagents.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class SubagentCapabilities with SubagentCapabilitiesMappable {
  final List<BuiltinTools>? enabledTools;
  final List<BuiltinTools>? disabledTools;

  SubagentCapabilities({this.enabledTools, this.disabledTools}) {
    if (enabledTools != null && disabledTools != null) {
      throw ArgumentError(
        'enabledTools and disabledTools should be mutually exclusive.',
      );
    }
  }

  static const fromMap = SubagentCapabilitiesMapper.fromMap;
  static const fromJson = SubagentCapabilitiesMapper.fromJson;
}

/// Configuration for a static subagent.
@MappableClass(caseStyle: CaseStyle.snakeCase, ignoreNull: true)
class SubagentConfig with SubagentConfigMappable {
  final String name;
  final String description;
  final dynamic systemInstructions; // String or List<SystemInstructionSection>
  final SubagentCapabilities? capabilities;

  /// Optional list of additional custom tools (string names of tools registered
  /// on the main agent) to enable.
  final List<String> tools;

  SubagentConfig({
    required this.name,
    required this.description,
    this.systemInstructions,
    this.capabilities,
    List<String>? tools,
  }) : tools = tools ?? [];

  static const fromMap = SubagentConfigMapper.fromMap;
  static const fromJson = SubagentConfigMapper.fromJson;
}
