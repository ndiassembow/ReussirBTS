// 📁 lib/services/local_user_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service local pour gérer une file d’attente d’utilisateurs en attente.
/// 🔹 Stocke les données avec `SharedPreferences`
/// 🔹 Utilisé quand l’utilisateur est hors ligne ou en attente de synchro
class LocalUserService {
  static const _pendingKey = 'pending_users_queue'; // clé de stockage locale

  /// Charge la liste des utilisateurs en attente (depuis SharedPreferences).
  Future<List<Map<String, dynamic>>> loadPendingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Ajoute un utilisateur à la file d’attente.
  /// 🚫 Ne stocke jamais de mot de passe en clair.
  Future<void> savePendingUserMap(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadPendingUsers();

    // Supprimer toute trace éventuelle de mot de passe
    final sanitized = Map<String, dynamic>.from(userMap)..remove('password');

    list.add(sanitized);
    await prefs.setString(_pendingKey, jsonEncode(list));
  }

  /// Remplace toute la file d’attente par une nouvelle liste d’utilisateurs.
  Future<void> replacePendingUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();

    // Nettoyer chaque entrée avant de sauvegarder
    final sanitized = users.map((u) {
      final copy = Map<String, dynamic>.from(u);
      copy.remove('password');
      return copy;
    }).toList();

    await prefs.setString(_pendingKey, jsonEncode(sanitized));
  }

  /// Vide complètement la file d’attente des utilisateurs.
  Future<void> clearPendingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }
}
