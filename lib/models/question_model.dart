// question_model.dart
class QuestionModel {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation; // 🔹 Explication feedback
  final int? durationSeconds; // 🔹 Temps limite par question

  QuestionModel({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    this.durationSeconds,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      question: (map['question'] ?? '').toString(),
      options: List<String>.from(map['options'] ?? []),
      correctIndex: map['correctIndex'] is int
          ? map['correctIndex']
          : int.tryParse(map['correctIndex']?.toString() ?? '0') ?? 0,
      explanation: map['explanation']?.toString(),
      durationSeconds: map['durationSeconds'] is int
          ? map['durationSeconds']
          : int.tryParse(map['durationSeconds']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'durationSeconds': durationSeconds,
    };
  }
}
