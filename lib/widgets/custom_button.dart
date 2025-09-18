// 📁 lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

/// Bouton personnalisé simple avec texte et action
class CustomButton extends StatelessWidget {
  final String text; // Texte affiché sur le bouton
  final VoidCallback onPressed; // Action à exécuter au clic

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed, // Déclenche l'action fournie
      child: Text(text), // Affiche le texte du bouton
    );
  }
}
