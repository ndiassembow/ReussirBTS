// 📁 lib/widgets/module_card.dart

import 'package:flutter/material.dart';
import '../models/course_model.dart';

/// Carte représentant un module/cours avec titre et nombre de contenus
class ModuleCard extends StatelessWidget {
  final Course course; // Module à afficher
  final VoidCallback onTap; // Action au clic sur la carte

  const ModuleCard({super.key, required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)), // Coins arrondis
      elevation: 3, // Ombre
      child: InkWell(
        onTap: onTap, // Gestion du clic
        child: Padding(
          padding: const EdgeInsets.all(12), // Espacement interne
          child: Row(
            children: [
              Icon(Icons.book,
                  size: 40, color: Colors.blue[700]), // Icône module
              const SizedBox(width: 12), // Espacement horizontal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4), // Petit espace
                    Text(
                      "${course.countFiches} fiches • ${course.countVideos} vidéos",
                      style: TextStyle(
                          color: Colors.grey[600]), // Info complémentaire
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
