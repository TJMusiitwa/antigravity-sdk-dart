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

/// Mode for establishing a connection to an agent session.
@MappableEnum(caseStyle: CaseStyle.upperCase)
enum SessionContinuationMode {
  /// Resume a previous conversation using its conversation identifier.
  ///
  /// Fails if the conversation cannot be found.
  @MappableValue('RESUME')
  resume('RESUME'),

  /// Resume a previous conversation if it exists, or create a new one.
  @MappableValue('CREATE_OR_RESUME')
  createOrResume('CREATE_OR_RESUME'),

  /// Always create a new conversation session.
  @MappableValue('CREATE_ONLY')
  createOnly('CREATE_ONLY'),

  /// Default unspecified fallback mode.
  @MappableValue('SESSION_CONTINUATION_MODE_UNSPECIFIED')
  unspecified('SESSION_CONTINUATION_MODE_UNSPECIFIED');

  final String value;
  const SessionContinuationMode(this.value);
}
