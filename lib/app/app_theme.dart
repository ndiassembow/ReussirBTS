// lib/app/app_theme.dart

// Importation du package Flutter Material pour utiliser les composants visuels
import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Palette de couleurs principales de l'application
  static const Color primaryColor =
      Color(0xFF2563EB); // Bleu doux (couleur principale)
  static const Color secondaryColor =
      Color(0xFFF3F4F6); // Gris clair (fond neutre)
  static const Color accentColor =
      Color(0xFF10B981); // Vert doux (accent / succès)
  static const Color errorColor = Color(0xFFDC2626); // Rouge (erreurs)

  // 🌞 Définition du thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      // Mode clair activé
      brightness: Brightness.light,

      // Police par défaut
      fontFamily: 'Roboto',

      // Couleur principale
      primaryColor: primaryColor,

      // Couleur de fond générale
      scaffoldBackgroundColor: Colors.white,

      // Schéma de couleurs global
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),

      // Densité visuelle (s'adapte selon la plateforme)
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // 🎨 Thème des textes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
        bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
      ),

      // 🎨 Thème des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Couleur de fond
          foregroundColor: Colors.white, // Couleur du texte
          minimumSize: const Size.fromHeight(48), // Hauteur minimale
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)), // Bords arrondis
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor), // Bordure bleue
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 🎨 Thème des champs de saisie (Input)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // 🎨 Thème des cartes (Card)
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // 🎨 Icônes & AppBar
      iconTheme: const IconThemeData(color: primaryColor, size: 24),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }

  // 🌙 Définition du thème sombre
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      // Couleur principale
      primaryColor: primaryColor,

      // Couleur de fond générale sombre
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),

      // Schéma de couleurs global sombre
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        error: errorColor,
      ),

      // 🎨 Thème des textes en mode sombre
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white70),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey),
      ),

      // 🎨 Boutons en mode sombre
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // 🎨 Cartes en mode sombre
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 🎨 AppBar en mode sombre
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
