// 📁 lib/widgets/custom_input.dart

import 'package:flutter/material.dart';

/// Champ de saisie personnalisable avec label, icône, erreur et mot de passe
class CustomInput extends StatelessWidget {
  final String label; // Libellé du champ
  final TextEditingController controller; // Contrôleur du texte
  final String? errorText; // Message d'erreur à afficher
  final bool isPassword; // Masquer le texte si mot de passe
  final bool enabled; // Champ activé ou désactivé
  final IconData? icon; // Icône facultative

  const CustomInput({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.isPassword = false,
    this.enabled = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16), // Espacement sous le champ
      child: TextFormField(
        controller: controller,
        obscureText: isPassword, // Masquer le texte si password
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null, // Icône si fournie
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // Coins arrondis
            borderSide: const BorderSide(),
          ),
          errorText: errorText, // Affiche le message d'erreur
          filled: !enabled, // Remplir si désactivé
          fillColor:
              enabled ? null : Colors.grey.shade200, // Fond gris si désactivé
        ),
      ),
    );
  }
}
