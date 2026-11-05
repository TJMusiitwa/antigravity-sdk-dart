import 'package:dart_mappable/dart_mappable.dart';

part 'system_instructions.mapper.dart';

/// A named section to append to the system instructions.
@MappableClass()
class SystemInstructionSection with SystemInstructionSectionMappable {
  /// Text of the section.
  final String content;

  /// Title of the section. Defaults to `user_system_instructions`.
  final String title;

  /// Creates a [SystemInstructionSection].
  SystemInstructionSection({
    required this.content,
    this.title = 'user_system_instructions',
  });

  /// Decodes a [SystemInstructionSection] from a map.
  static const fromMap = SystemInstructionSectionMapper.fromMap;

  /// Decodes a [SystemInstructionSection] from a JSON string.
  static const fromJson = SystemInstructionSectionMapper.fromJson;
}

/// Sealed representation of system instructions.
@MappableClass(discriminatorKey: 'type')
sealed class SystemInstructions with SystemInstructionsMappable {
  SystemInstructions();
}

/// Completely replaces system instructions.
@MappableClass(discriminatorValue: 'custom')
class CustomSystemInstructions extends SystemInstructions
    with CustomSystemInstructionsMappable {
  /// Full system instruction text that replaces all default instructions.
  final String text;

  /// Optional prompt-section title. When set, the harness renders [text] under
  /// `<title>` tags instead of the generic `<System>` section. Null or empty
  /// means no title is sent.
  final String? title;

  /// Creates a [CustomSystemInstructions] from [text] and an optional [title].
  CustomSystemInstructions({required this.text, this.title});

  @override
  Map<String, dynamic> toMap() => {
    'custom': {
      'part': [
        {
          'text': text,
          if (title case final title? when title.isNotEmpty) 'title': title,
        },
      ],
    },
  };
}

/// Appends sections to default system instructions.
@MappableClass(caseStyle: CaseStyle.snakeCase, discriminatorValue: 'appended')
class TemplatedSystemInstructions extends SystemInstructions
    with TemplatedSystemInstructionsMappable {
  /// Custom agent identity that overrides the default one.
  ///
  /// Sent as `custom_identity`. When null, the default identity is kept.
  final String? identity;

  /// Sections appended to the default system instructions.
  ///
  /// Sent as `appended_sections`.
  final List<SystemInstructionSection> sections;

  /// Creates a [TemplatedSystemInstructions].
  ///
  /// [sections] defaults to an empty list.
  TemplatedSystemInstructions({
    this.identity,
    List<SystemInstructionSection>? sections,
  }) : sections = sections ?? [];

  @override
  Map<String, dynamic> toMap() => {
    'appended': {
      if (identity != null) 'custom_identity': identity,
      'appended_sections': sections.map((s) => s.toMap()).toList(),
    },
  };
}
