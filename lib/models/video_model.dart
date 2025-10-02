// lib/models/video_model.dart
class VideoItem {
  final String id;
  final String title;
  final String url; // 🔥 Firebase Storage (MP4) ou YouTube (si externe)
  final String? localPath; // 🔹 chemin local (PC / device)
  final String? description;
  final bool watched; // ✅ ajouté pour suivi de progression
  final int? duration; // secondes (ou minutes si tu standardises)
  final String? level;
  final List<String> tags;
  final int order; // ✅ pour trier correctement les vidéos

  VideoItem({
    required this.id,
    required this.title,
    required this.url,
    this.localPath,
    this.description,
    this.watched = false,
    this.duration,
    this.level,
    this.tags = const [],
    this.order = 0,
  });

  // --- Helpers ---
  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (v is String) {
      return v
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  // --- Factory ---
  factory VideoItem.fromMap(Map<String, dynamic> map, {required String id}) {
    return VideoItem(
      id: id,
      title: (map['title'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      localPath: map['localPath']?.toString(),
      description: map['description']?.toString(),
      watched: map['watched'] ?? false,
      duration: _toNullableInt(map['duration']),
      level: map['level']?.toString(),
      tags: _toStringList(map['tags']),
      order: _toNullableInt(map['order']) ?? 0,
    );
  }

  // --- Serialize ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'localPath': localPath,
      'description': description,
      'watched': watched,
      'duration': duration,
      'level': level,
      'tags': tags,
      'order': order,
    };
  }
}
