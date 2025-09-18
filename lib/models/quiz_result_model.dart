// lib/models/quiz_result_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Import nécessaire

class QuizResult {
  final String id;
  final String moduleId;
  final String quizId;
  final int score;
  final int total;
  final int bonnes;
  final int fautes;
  final int duree;
  final int percent;
  final String badge;
  final DateTime date;
  final List<int> answers;

  QuizResult({
    required this.id,
    required this.moduleId,
    required this.quizId,
    required this.score,
    required this.total,
    required this.bonnes,
    required this.fautes,
    required this.duree,
    required this.percent,
    required this.badge,
    required this.date,
    this.answers = const [],
  });

  /// 🔹 Création depuis Firestore
  factory QuizResult.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return QuizResult(
      id: doc.id,
      moduleId: data['moduleId'] ?? '',
      quizId: data['quizId'] ?? '',
      score: data['score'] ?? 0,
      total: data['total'] ?? 0,
      bonnes: data['bonnes'] ?? 0,
      fautes: data['fautes'] ?? 0,
      duree: data['duree'] ?? 0,
      percent: data['percent'] ?? 0,
      badge: data['badge'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      answers: List<int>.from(data['answers'] ?? []),
    );
  }

  /// 🔹 Conversion vers Map (utile pour sauvegarde)
  Map<String, dynamic> toMap() {
    return {
      "moduleId": moduleId,
      "quizId": quizId,
      "score": score,
      "total": total,
      "bonnes": bonnes,
      "fautes": fautes,
      "duree": duree,
      "percent": percent,
      "badge": badge,
      "date": date.toIso8601String(),
      "answers": answers,
    };
  }
}
