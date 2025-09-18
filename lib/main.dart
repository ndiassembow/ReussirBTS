// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart'; // ✅ Gestion globale avec Provider

// Imports internes
import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';
import 'provider/user_provider.dart'; // ✅ Fournit les infos utilisateur
import 'provider/theme_provider.dart'; // ✅ Fournit le thème clair/sombre

/// 🔹 Flag global : indique si l'app est en mode hors-ligne
bool isOfflineMode = false;

Future<void> main() async {
  // Assure que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 Initialisation Firebase selon la plateforme
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.web,
      );
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    debugPrint('✅ Firebase initialisé avec succès !');
  } catch (e, s) {
    // 🔹 Si échec → activer le mode hors-ligne
    debugPrint('❌ Erreur initialisation Firebase : $e');
    debugPrint('$s');
    isOfflineMode = true;
    debugPrint('⚠️ Mode hors-ligne activé (fallback local JSON)');
  }

  // 🔹 Lancement de l'app avec MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(), // Gestion utilisateur
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(), // Gestion thème clair/sombre
        ),
      ],
      child: const ReussirBtsApp(),
    ),
  );
}

/// 🔹 Classe principale de l’application
class ReussirBtsApp extends StatelessWidget {
  const ReussirBtsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération du thème actuel
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Réussir BTS',
      theme: AppTheme.lightTheme, // ✅ Thème clair
      darkTheme: AppTheme.darkTheme, // ✅ Thème sombre
      themeMode: themeProvider.isDark // Choix du thème selon Provider
          ? ThemeMode.dark
          : ThemeMode.light,
      initialRoute: AppRoutes.splash, // ✅ Page d’accueil
      routes: AppRoutes.routes, // ✅ Définition des routes
      debugShowCheckedModeBanner: false, // Supprime le bandeau debug

      // 🔹 Gestion du rendu avec message global hors-ligne
      builder: (context, child) {
        if (isOfflineMode) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '⚠️ Vous êtes en mode hors-ligne. Certaines fonctionnalités peuvent être limitées.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
