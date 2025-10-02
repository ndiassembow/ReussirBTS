// lib/models/quiz_model.dart
import 'question_model.dart';

class QuizModel {
  final String id;
  final String title;
  final String moduleId;
  final List<QuestionModel> questions;
  final Map<String, int> badgeThresholds;

  QuizModel({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.questions,
    this.badgeThresholds = const {
      'Bronze': 50,
      'Argent': 70,
      'Or': 90,
    },
  });

  factory QuizModel.fromMap(
    Map<String, dynamic> map, {
    required String id,
    required String moduleId,
  }) {
    return QuizModel(
      id: id,
      title: (map['title'] ?? 'Quiz').toString(),
      moduleId: map['moduleId']?.toString() ?? moduleId,
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'moduleId': moduleId,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }

  /// 🔹 copyWith pour modifier uniquement certains champs
  QuizModel copyWith({
    String? id,
    String? title,
    String? moduleId,
    List<QuestionModel>? questions,
  }) {
    return QuizModel(
      id: id ?? this.id,
      title: title ?? this.title,
      moduleId: moduleId ?? this.moduleId,
      questions: questions ?? this.questions,
    );
  }
}
