// 📁 lib/app/auth_gate.dart

// Importation des bibliothèques nécessaires
import 'dart:convert'; // Pour encoder/décoder les données en JSON
import 'dart:io'; // Pour manipuler les fichiers locaux (sauf sur Web)

import 'package:flutter/foundation.dart'
    show kIsWeb; // Détection de la plateforme Web
import 'package:path_provider/path_provider.dart'; // Pour obtenir le chemin du stockage local
import 'package:firebase_auth/firebase_auth.dart'; // Authentification Firebase
import 'package:cloud_firestore/cloud_firestore.dart'; // Base de données Firestore

// Importation des modèles et services internes
import '../models/user_model.dart';
import '../services/local_user_service.dart';

class AuthService {
  // Instances des services Firebase et service local
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalUserService _localQueue = LocalUserService();

  // ---------------- SIGN UP (INSCRIPTION) ----------------
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String school,
    required String speciality,
    required String password,
    String niveau = 'BTS1',
  }) async {
    try {
      // Création d’un compte Firebase
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // Création d’un objet utilisateur
      final user = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: 'etudiant',
        password: password,
        niveau: niveau,
      );

      // Sauvegarde de l’utilisateur dans Firestore
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'school': school,
        'speciality': speciality,
        'role': 'etudiant',
        'niveau': niveau,
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Sauvegarde locale
      await _saveUserLocal(user);
      return user;
    } catch (e) {
      // Si échec, sauvegarde en mode hors ligne (utilisateur en attente)
      final fakeUid = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final user = AppUser(
        uid: fakeUid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: 'etudiant',
        password: password,
        niveau: niveau,
      );

      // Stockage des infos en attente dans la file locale
      await _localQueue.savePendingUserMap({
        'name': name,
        'email': email,
        'phone': phone,
        'school': school,
        'speciality': speciality,
        'password': password,
        'role': 'etudiant',
        'niveau': niveau,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _saveUserLocal(user);
      return user;
    }
  }

  // ---------------- LOGIN (CONNEXION) ----------------
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      // Connexion via Firebase
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupération des données utilisateur dans Firestore
      final snap = await _db.collection('users').doc(cred.user!.uid).get();
      if (snap.exists) {
        final data = snap.data()!;
        final user = AppUser.fromMap(data);
        await _saveUserLocal(user);
        return user;
      }

      // Sinon, récupération depuis la mémoire locale
      final localUser = await getLocalUserByUid(cred.user!.uid);
      if (localUser != null) return localUser;

      // Sinon, création d’un utilisateur minimal
      return AppUser(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? '',
        email: cred.user!.email ?? email,
        phone: '',
        school: '',
        speciality: '',
        role: 'etudiant',
        password: password,
        niveau: 'BTS1',
      );
    } catch (e) {
      // Vérification locale si pas de connexion
      final user = await getLocalUserByEmail(email);
      if (user != null && user.password == password) {
        return user;
      }
      throw Exception("Impossible de se connecter");
    }
  }

  // ---------------- RESET PASSWORD ----------------
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Impossible d’envoyer l’email de réinitialisation : $e");
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearLocalSession(); // Nettoyage des données locales
  }

  // ---------------- REPLAY PENDING USERS ----------------
  // Réessaye de synchroniser les utilisateurs créés hors ligne
  Future<void> replayPendingUsers() async {
    try {
      final pending = await _localQueue.loadPendingUsers();
      if (pending.isEmpty) return;

      final List<Map<String, dynamic>> stillPending = [];

      for (final u in pending) {
        try {
          // Nouvelle tentative de création dans Firebase
          final cred = await _auth.createUserWithEmailAndPassword(
            email: u['email'] as String,
            password: u['password'] as String,
          );
          final uid = cred.user!.uid;

          // Sauvegarde dans Firestore
          await _db.collection('users').doc(uid).set({
            'uid': uid,
            'name': u['name'],
            'email': u['email'],
            'phone': u['phone'],
            'school': u['school'],
            'speciality': u['speciality'],
            'role': 'etudiant',
            'niveau': u['niveau'],
            'createdAt': u['createdAt'],
            'syncedAt': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Si échec, l’utilisateur reste en attente
          stillPending.add(u);
        }
      }

      // Mise à jour de la file locale
      if (stillPending.isEmpty) {
        await _localQueue.clearPendingUsers();
      } else {
        await _localQueue.replacePendingUsers(stillPending);
      }
    } catch (e) {
      throw Exception("❌ replayPendingUsers error: $e");
    }
  }

  // ---------------- SAUVEGARDE LOCALE JSON ----------------
  Future<void> _saveUserLocal(AppUser user) async {
    if (kIsWeb) return; // Pas de sauvegarde locale sur Web
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');

      // Lecture des utilisateurs existants
      List<AppUser> users = await _getAllUsersLocal();

      // Mise à jour (remplacement si doublon)
      users.removeWhere((u) => u.uid == user.uid);
      users.add(user);

      // Sauvegarde dans un fichier JSON
      await file.writeAsString(
        jsonEncode(users.map((u) => u.toMap()).toList()),
      );
    } catch (e) {
      throw Exception("❌ _saveUserLocal error: $e");
    }
  }

  // Récupération de tous les utilisateurs sauvegardés localement
  Future<List<AppUser>> _getAllUsersLocal() async {
    if (kIsWeb) return [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (!await file.exists()) return [];

      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);

      return jsonList.map((e) => AppUser.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // Recherche locale par UID
  Future<AppUser?> getLocalUserByUid(String uid) async {
    final users = await _getAllUsersLocal();
    try {
      return users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // Recherche locale par Email
  Future<AppUser?> getLocalUserByEmail(String email) async {
    final users = await _getAllUsersLocal();
    try {
      return users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  // Suppression de la session locale
  Future<void> _clearLocalSession() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/session.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
