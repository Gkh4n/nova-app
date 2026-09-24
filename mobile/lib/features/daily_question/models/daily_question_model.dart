class DailyQuestionModel {
  const DailyQuestionModel({
    required this.id,
    required this.text,
    required this.answerCount,
    required this.answeredByMe,
  });

  final int id;
  final String text;
  final int answerCount;
  final bool answeredByMe;

  factory DailyQuestionModel.fromJson(Map<String, dynamic> json) => DailyQuestionModel(
        id: json['id'] as int,
        text: json['text'] as String,
        answerCount: json['answer_count'] as int? ?? 0,
        answeredByMe: json['answered_by_me'] as bool? ?? false,
      );
}
