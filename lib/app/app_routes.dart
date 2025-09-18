// lib/app/app_routes.dart

// Importation des dépendances nécessaires de Flutter et des différentes pages de l'application
import 'package:flutter/material.dart';
import 'package:reussirbts/app/splash_screen.dart';
import 'package:reussirbts/screens/auth/login_screen.dart';
import 'package:reussirbts/screens/auth/register_screen.dart';
import 'package:reussirbts/screens/dashboard.dart';
import 'package:reussirbts/screens/tabs/home_tab.dart';
import 'package:reussirbts/screens/tabs/revision_tab.dart';
import 'package:reussirbts/screens/tabs/quiz_tab.dart';
import 'package:reussirbts/screens/tabs/progress_tab.dart';
import 'package:reussirbts/screens/tabs/profile_tab.dart';
import 'package:reussirbts/screens/admin/admin_panel.dart';

class AppRoutes {
  // -------------------------------
  // Définition des routes publiques
  // -------------------------------

  // Route pour l'écran de démarrage (Splash Screen)
  static const splash = '/';

  // Route pour l'écran de connexion
  static const login = '/login';

  // Route pour l'écran d'inscription
  static const register = '/register';

  // ------------------------------------
  // Définition des routes protégées
  // (nécessitent généralement une authentification)
  // ------------------------------------

  // Route pour le tableau de bord principal
  static const dashboard = '/dashboard';

  // Route pour le panneau d'administration
  static const adminPanel = '/admin';

  // -------------------------------
  // Définition des onglets du Dashboard
  // -------------------------------

  // Onglet accueil
  static const homeTab = '/dashboard/home';

  // Onglet révision
  static const revisionTab = '/dashboard/revision';

  // Onglet quiz
  static const quizTab = '/dashboard/quiz';

  // Onglet progression
  static const progressTab = '/dashboard/progress';

  // Onglet profil utilisateur
  static const profileTab = '/dashboard/profile';

  // ---------------------------------------------------
  // Mapping des routes vers les Widgets correspondants
  // ---------------------------------------------------
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const Dashboard(),
    adminPanel: (context) => const AdminPanel(),
    homeTab: (context) => const HomeTab(),
    revisionTab: (context) => const RevisionTab(),
    quizTab: (context) => const QuizTab(),
    progressTab: (context) => const ProgressTab(),
    profileTab: (context) => const ProfileTab(),
  };
}
