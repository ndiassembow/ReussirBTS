// 📁 lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔹 Provider qui gère le thème clair/sombre de l’application.
/// Il utilise `SharedPreferences` pour mémoriser la préférence
/// de l’utilisateur même après la fermeture de l’application.
class ThemeProvider with ChangeNotifier {
  // --- État interne ---
  bool _isDark = false; // ✅ Thème par défaut = clair

  // --- Getter ---
  bool get isDark => _isDark; // permet d’accéder à l’état du thème

  // --- Constructeur ---
  ThemeProvider() {
    _loadTheme(); // au démarrage, on charge la préférence sauvegardée
  }

  // --- Méthode : inversion du thème ---
  void toggleTheme() {
    _isDark = !_isDark; // bascule clair ↔ sombre
    _saveTheme(); // sauvegarde dans SharedPreferences
    notifyListeners(); // informe l’UI que le thème a changé
  }

  // --- Méthode privée : charger le thème sauvegardé ---
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark =
        prefs.getBool('isDark') ?? false; // récupère la valeur, défaut = clair
    notifyListeners(); // met à jour les widgets
  }

  // --- Méthode privée : sauvegarder le thème choisi ---
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark); // stocke le choix utilisateur
  }
}
