// 📁 lib/utils/validators.dart

/// Classe utilitaire pour la validation des champs de formulaire
class Validators {
  /// ✅ Champ obligatoire
  static String? notEmpty(String? v, {String msg = "Champ requis"}) {
    if (v == null || v.trim().isEmpty) return msg;
    return null;
  }

  /// ✅ Email format standard
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return "Email requis";
    final re = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
    if (!re.hasMatch(v.trim())) return "Email invalide";
    return null;
  }

  /// ✅ Mot de passe : min 8 caractères, au moins une lettre et un chiffre
  static String? password(String? v) {
    if (v == null || v.isEmpty) return "Mot de passe requis";
    if (v.length < 8) return "Min. 8 caractères";
    final hasLetter = RegExp(r"[A-Za-z]").hasMatch(v);
    final hasDigit = RegExp(r"\d").hasMatch(v);
    if (!hasLetter || !hasDigit) return "Doit contenir lettres et chiffres";
    return null;
  }

  /// ✅ Nom complet : deux mots minimum, ≥4 lettres chacun, pas de répétition simple
  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return "Nom requis";
    final parts = v.trim().split(' ');
    if (parts.length < 2) return "Veuillez saisir prénom et nom";
    for (var p in parts) {
      if (p.length < 4) return "Chaque nom doit avoir ≥4 lettres";
      if (_hasSimpleRepetition(p)) return "Nom invalide (répétition)";
    }
    return null;
  }

  /// ✅ Vérifie le téléphone : chiffres et + seulement, 7-15 caractères
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return "Téléphone requis";
    final re = RegExp(r'^\+?\d{7,15}$');
    if (!re.hasMatch(v.trim())) return "Téléphone invalide";
    return null;
  }

  /// ✅ Texte avec longueur minimale et pas de répétition simple
  static String? minLengthNoRepeat(String? v, int minLength) {
    if (v == null || v.trim().isEmpty) return "Champ requis";
    final t = v.trim();
    if (t.length < minLength) return "Min. $minLength caractères";
    if (_hasSimpleRepetition(t)) return "Texte invalide (répétition)";
    return null;
  }

  /// 🔹 Helper pour détecter répétitions simples comme AAAA, TTTT, AAAB, AABB
  static bool _hasSimpleRepetition(String s) {
    if (s.isEmpty) return false;
    final lower = s.toLowerCase();
    final firstChar = lower[0];
    if (lower.split('').every((c) => c == firstChar)) return true; // AAAA
    final set = lower.split('').toSet();
    if (set.length <= 2 && lower.length >= 4) return true; // AAAB, AABB
    return false;
  }
}
