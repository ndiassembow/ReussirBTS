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
  final List<QuizModel> quizzes;

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

  // --- Helpers ---
  int get countFiches => fiches.length;
  int get countVideos => videos.length;
  int get countQuizzes => quizzes.length;

  // --- Factory depuis Firestore ---
  factory Course.fromMap(Map<String, dynamic> map, {required String id}) {
    final List<Fiche> fichesList = (map['fiches'] as List<dynamic>? ?? [])
        .map((f) => Fiche.fromMap(
              Map<String, dynamic>.from(f),
              id: f['id'] ?? '',
            ))
        .toList();

    final List<VideoItem> videosList = (map['videos'] as List<dynamic>? ?? [])
        .map((v) => VideoItem.fromMap(
              Map<String, dynamic>.from(v),
              id: v['id'] ?? '',
            ))
        .toList();

    final List<QuizModel> quizList = (map['quizzes'] as List<dynamic>? ?? [])
        .map((q) => QuizModel.fromMap(
              Map<String, dynamic>.from(q),
              id: q['id'] ?? '',
              moduleId: id,
            ))
        .toList();

    return Course(
      id: id,
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'] as String?,
      fiches: fichesList,
      videos: videosList,
      quizzes: quizList,
    );
  }

  // --- Serialize vers Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'imageUrl': imageUrl,
      'fiches': fiches.map((f) => f.toMap()).toList(),
      'videos': videos.map((v) => v.toMap()).toList(),
      'quizzes': quizzes.map((q) => q.toMap()).toList(),
    };
  }

  // --- Helpers utiles ---
  Course copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? imageUrl,
    List<Fiche>? fiches,
    List<VideoItem>? videos,
    List<QuizModel>? quizzes,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      fiches: fiches ?? this.fiches,
      videos: videos ?? this.videos,
      quizzes: quizzes ?? this.quizzes,
    );
  }

  @override
  String toString() =>
      'Course(id: $id, title: $title, fiches: $countFiches, videos: $countVideos, quizzes: $countQuizzes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Course && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
