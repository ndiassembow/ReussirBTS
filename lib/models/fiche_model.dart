// lib/models/fiche_model.dart
class Fiche {
  final String id;
  final String title;
  final String url; // lien Firebase Storage (PDF)
  final String? localPath; // 🔹 chemin local (PC / device)
  final String? description;
  final bool viewed; // ✅ lu ou non
  final bool watched; // ✅ regardé (utile si une fiche a une vidéo intégrée)
  final int? duration; // minutes (optionnel)
  final int? pages; // nombre de pages
  final String? level;
  final List<String> tags;
  final int order; // ✅ pour trier correctement les fiches (1,2,3...)

  Fiche({
    required this.id,
    required this.title,
    required this.url,
    this.localPath,
    this.description,
    this.viewed = false,
    this.watched = false, // 🔹 par défaut non regardé
    this.duration,
    this.pages,
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
  factory Fiche.fromMap(Map<String, dynamic> map, {required String id}) {
    return Fiche(
      id: id,
      title: (map['title'] ?? '').toString(),
      url: (map['url'] ?? '').toString(),
      localPath: map['localPath']?.toString(),
      description: map['description']?.toString(),
      viewed: map['viewed'] ?? false,
      watched: map['watched'] ?? false, // ✅ ajouté

      duration: _toNullableInt(map['duration']),
      pages: _toNullableInt(map['pages']),
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
      'viewed': viewed,
      'watched': watched, // ✅ ajouté dans la sauvegarde
      'duration': duration,
      'pages': pages,
      'level': level,
      'tags': tags,
      'order': order,
    };
  }
}
