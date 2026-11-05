/// Result of a decision hook execution.
class HookResult {
  /// Whether execution should proceed.
  final bool allow;

  /// Optional explanation or response message.
  final String message;

  /// Modified tool arguments, or null to keep the originals.
  ///
  /// These are shallow-merged into the existing arguments (overwriting the
  /// given keys) before execution.
  final Map<String, dynamic>? modifiedArgs;

  /// Creates a [HookResult]. By default, execution is allowed.
  HookResult({this.allow = true, this.message = '', this.modifiedArgs});

  /// Returns a copy of this result with the given fields replaced.
  HookResult copyWith({
    bool? allow,
    String? message,
    Map<String, dynamic>? modifiedArgs,
  }) {
    return HookResult(
      allow: allow ?? this.allow,
      message: message ?? this.message,
      modifiedArgs: modifiedArgs ?? this.modifiedArgs,
    );
  }
}

/// Individual response for an [AskQuestionEntry].
class QuestionResponse {
  /// IDs of the selected options.
  final List<String>? selectedOptionIds;

  /// Freeform text response.
  final String freeformResponse;

  /// Whether the question was skipped.
  final bool skipped;

  /// Creates a [QuestionResponse].
  QuestionResponse({
    this.selectedOptionIds,
    this.freeformResponse = '',
    this.skipped = false,
  });
}

/// Result of an interaction, containing a list of responses.
class QuestionHookResult {
  /// Responses to the questions.
  final List<QuestionResponse> responses;

  /// Whether the interaction was cancelled.
  final bool cancelled;

  /// Creates a [QuestionHookResult].
  QuestionHookResult({required this.responses, this.cancelled = false});
}

/// Option for an [AskQuestionEntry].
class AskQuestionOption {
  /// Option ID, referenced by [QuestionResponse.selectedOptionIds].
  final String id;

  /// Display text of the option.
  final String text;

  /// Creates an [AskQuestionOption].
  AskQuestionOption({required this.id, required this.text});
}

/// A single question with predefined options.
class AskQuestionEntry {
  /// Question text.
  final String question;

  /// Predefined options to choose from.
  final List<AskQuestionOption> options;

  /// Whether more than one option can be selected.
  final bool isMultiSelect;

  /// Creates an [AskQuestionEntry].
  AskQuestionEntry({
    required this.question,
    required this.options,
    this.isMultiSelect = false,
  });
}

/// Interaction spec for an ask-question dialog.
class AskQuestionInteractionSpec {
  /// Questions to ask.
  final List<AskQuestionEntry> questions;

  /// Creates an [AskQuestionInteractionSpec].
  AskQuestionInteractionSpec({required this.questions});
}
