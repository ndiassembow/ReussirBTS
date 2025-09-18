// 📁 lib/widgets/microlearning_card.dart

import 'package:flutter/material.dart';

/// Carte représentant un microlearning avec titre et durée
class MicrolearningCard extends StatelessWidget {
  final String title; // Titre du microlearning
  final int duration; // Durée en minutes
  final VoidCallback onTap; // Action au clic

  const MicrolearningCard({
    super.key,
    required this.title,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Largeur fixe de la carte
      child: Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // Coins arrondis
        elevation: 2, // Ombre
        child: InkWell(
          onTap: onTap, // Gestion du clic
          child: Padding(
            padding: const EdgeInsets.all(12), // Espacement interne
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flash_on,
                    color: Colors.orange, size: 32), // Icône microlearning
                const SizedBox(height: 12), // Espacement vertical
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(), // Push la durée en bas
                Text(
                  "$duration min",
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14), // Affichage de la durée
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
