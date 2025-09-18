// lib/models/course_model.dart
import 'fiche_model.dart';
import 'video_model.dart';
import 'quiz_model.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String? imageUrl;
  final List<Fiche> fiches;
  final List<VideoItem> videos;
  final List<QuizModel> quizzes; // 🔹 Quizzes liés au module

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.tags = const [],
    this.imageUrl,
    this.fiches = const [],
    this.videos = const [],
    this.quizzes = const [],
  });

  // --- Helpers (computed counts) ---
  int get countFiches => fiches.length;
  int get countVideos => videos.length;
  int get countQuizzes => quizzes.length;

  // --- Factory ---
  factory Course.fromMap(Map<String, dynamic> map, {required String id}) {
    final fichesList = (map['fiches'] as List<dynamic>? ?? [])
        .map((f) => Fiche.fromMap(
              Map<String, dynamic>.from(f),
              id: f['id'] ?? '',
            ))
        .toList();

    final videosList = (map['videos'] as List<dynamic>? ?? [])
        .map((v) => VideoItem.fromMap(
              Map<String, dynamic>.from(v),
              id: v['id'] ?? '',
            ))
        .toList();

    final quizList = (map['quizzes'] as List<dynamic>? ?? [])
        .map((q) => QuizModel.fromMap(
              Map<String, dynamic>.from(q),
              id: q['id'] ?? '',
              moduleId: id, // 🔹 FIX : passage obligatoire du moduleId
            ))
        .toList();

    return Course(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      tags: List<String>.from(map['tags'] ?? const []),
      imageUrl: map['imageUrl'] as String?,
      fiches: fichesList,
      videos: videosList,
      quizzes: quizList,
    );
  }

  // --- Serialize ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'imageUrl': imageUrl,
      'fiches': fiches.map((f) => f.toMap()).toList(),
      'videos': videos.map((v) => v.toMap()).toList(),
      'quizzes': quizzes.map((q) => q.toMap()).toList(),
    };
  }
}
