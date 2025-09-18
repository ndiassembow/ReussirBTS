// 📁 lib/widgets/network_banner.dart

import 'package:flutter/material.dart';

/// Widget affichant un bandeau rouge indiquant que l'utilisateur est hors ligne
class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red, // Couleur du bandeau
      padding: const EdgeInsets.all(8), // Padding autour du texte
      width: double.infinity, // Prend toute la largeur disponible
      child: const Text(
        'Vous êtes hors ligne', // Message affiché
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold, // Texte en gras
        ),
        textAlign: TextAlign.center, // Centré horizontalement
      ),
    );
  }
}
