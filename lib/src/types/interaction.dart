class HookResult {
  final bool allow;
  final String message;

  HookResult({this.allow = true, this.message = ''});
}

class QuestionResponse {
  final List<String>? selectedOptionIds;
  final String freeformResponse;
  final bool skipped;

  QuestionResponse({
    this.selectedOptionIds,
    this.freeformResponse = '',
    this.skipped = false,
  });
}

class QuestionHookResult {
  final List<QuestionResponse> responses;
  final bool cancelled;

  QuestionHookResult({required this.responses, this.cancelled = false});
}

class AskQuestionOption {
  final String id;
  final String text;

  AskQuestionOption({required this.id, required this.text});
}

class AskQuestionEntry {
  final String question;
  final List<AskQuestionOption> options;
  final bool isMultiSelect;

  AskQuestionEntry({
    required this.question,
    required this.options,
    this.isMultiSelect = false,
  });
}

class AskQuestionInteractionSpec {
  final List<AskQuestionEntry> questions;

  AskQuestionInteractionSpec({required this.questions});
}
