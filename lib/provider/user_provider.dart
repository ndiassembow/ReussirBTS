// 📁 lib/provider/user_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// 🔹 Provider qui gère l’utilisateur courant (inscription, connexion, logout, récupération)
class UserProvider with ChangeNotifier {
  // --- Instances Firebase ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- État interne ---
  AppUser? _user; // utilisateur courant
  AppUser? get user => _user; // getter public

  // ===========================
  // ===== INSCRIPTION =====
  // ===========================
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String school,
    required String speciality,
    required String password,
    required bool offline, // option pour dev/offline
    String role = 'etudiant',
    String niveau = 'BTS1',
  }) async {
    try {
      // 🔹 Création du compte dans Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // 🔹 Création du modèle AppUser
      AppUser newUser = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: role,
        password:
            password, // ⚠️ attention : stocker en clair seulement pour dev/test
        niveau: niveau,
      );

      // 🔹 Sauvegarde dans Firestore
      await _firestore.collection("users").doc(uid).set(newUser.toMap());

      // 🔹 Mise à jour du provider
      _user = newUser;
      notifyListeners(); // informe l’UI
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Erreur d'inscription";
    }
  }

  // ===========================
  // ===== CONNEXION =====
  // ===========================
  Future<void> login(String email, String password) async {
    try {
      // 🔹 Connexion Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // 🔹 Récupération du profil utilisateur Firestore
      final doc = await _firestore.collection("users").doc(uid).get();
      if (doc.exists) {
        _user = AppUser.fromMap(doc.data()!);
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Erreur de connexion";
    }
  }

  // ===========================
  // ===== DECONNEXION =====
  // ===========================
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // ===========================
  // ===== CHARGER L’UTILISATEUR COURANT =====
  // ===========================
  Future<void> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final doc =
          await _firestore.collection("users").doc(firebaseUser.uid).get();
      if (doc.exists) {
        _user = AppUser.fromMap(doc.data()!);
        notifyListeners();
      }
    }
  }

  // 🔹 Setter direct pour mettre à jour l’utilisateur
  void setUser(AppUser user) {
    _user = user;
    notifyListeners();
  }
}
