import 'package:dart_mappable/dart_mappable.dart';

part 'system_instructions.mapper.dart';

@MappableClass()
class SystemInstructionSection with SystemInstructionSectionMappable {
  final String content;
  final String title;

  SystemInstructionSection({
    required this.content,
    this.title = 'user_system_instructions',
  });

  static const fromMap = SystemInstructionSectionMapper.fromMap;
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
  final String text;

  CustomSystemInstructions({required this.text});

  @override
  Map<String, dynamic> toMap() => {
        'custom': {
          'part': [
            {'text': text},
          ],
        },
      };
}

/// Appends sections to default system instructions.
@MappableClass(caseStyle: CaseStyle.snakeCase, discriminatorValue: 'appended')
class TemplatedSystemInstructions extends SystemInstructions
    with TemplatedSystemInstructionsMappable {
  final String? identity;
  final List<SystemInstructionSection> sections;

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
