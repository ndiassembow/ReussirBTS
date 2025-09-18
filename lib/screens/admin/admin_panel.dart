// lib/screens/admin/admin_panel.dart

import 'package:flutter/material.dart';

// Import des écrans de gestion (CRUD)
import 'student_crud_screen.dart';
import 'quiz_crud_screen.dart';
import 'course_crud_screen.dart';

/// 🔹 Écran principal du panneau d’administration
/// Il permet de gérer :
/// - Les étudiants
/// - Les quiz
/// - Les cours (fiches + vidéos)
class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

/// État du panneau Admin, avec gestion des onglets (TabBar)
class _AdminPanelState extends State<AdminPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController; // Contrôleur pour gérer les onglets

  @override
  void initState() {
    super.initState();
    // Initialise le TabController avec 3 onglets
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Libère le TabController quand l’écran est fermé
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre du haut (AppBar)
      appBar: AppBar(
        title: const Text(
          "Panneau Admin",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,

        // Onglets de navigation
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Texte onglet actif
          unselectedLabelColor: Colors.white70, // Texte onglets inactifs
          indicatorColor: Colors.amber, // Couleur du soulignement
          indicatorWeight: 3, // Épaisseur du soulignement
          tabs: const [
            Tab(icon: Icon(Icons.person), text: "Étudiants"),
            Tab(icon: Icon(Icons.quiz), text: "Quiz"),
            Tab(icon: Icon(Icons.library_books), text: "Cours"),
          ],
        ),
      ),

      // Contenu de chaque onglet
      body: TabBarView(
        controller: _tabController,
        children: const [
          StudentCrud(), // Gestion des étudiants
          QuizCrud(), // Gestion des quiz
          CourseCrud(), // Gestion des cours (fiches + vidéos)
        ],
      ),
    );
  }
}
