import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'local_user_service.dart';
import 'firestore_service.dart';

/// 🔹 Service centralisé : Firebase Auth + Firestore + Offline (JSON + SharedPreferences)
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _fsService = FirestoreService();
  final LocalUserService _localQueue = LocalUserService();

  /// ID utilisateur courant
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // ==============================
  // 🔹 INSCRIPTION
  // ==============================
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String school,
    required String speciality,
    required String password,
    String role = "etudiant",
    String niveau = "BTS1",
  }) async {
    try {
      // Création Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // Création modèle
      final user = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: role,
        niveau: niveau,
      );

      // Sauvegarde Firestore
      await _firestore.collection("users").doc(uid).set({
        ...user.toMap(),
        "createdAt": DateTime.now().toIso8601String(),
      });

      // Sauvegarde locale
      await _saveUserLocal(user);
      return user;
    } catch (_) {
      // Fallback hors ligne
      final fakeUid = "pending_${DateTime.now().millisecondsSinceEpoch}";
      final user = AppUser(
        uid: fakeUid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: role,
        niveau: niveau,
      );

      await _localQueue.savePendingUserMap({
        ...user.toMap(),
        "createdAt": DateTime.now().toIso8601String(),
      });

      await _saveUserLocal(user);
      return user;
    }
  }

  // ==============================
  // 🔹 CONNEXION
  // ==============================
  Future<AppUser> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Récupération Firestore
      final doc =
          await _firestore.collection("users").doc(cred.user!.uid).get();
      if (!doc.exists) {
        throw Exception("Utilisateur introuvable dans Firestore.");
      }
      final user = AppUser.fromMap(doc.data()!);

      // Sauvegarde locale
      await _saveUserLocal(user);

      // Sauvegarde identifiants si demandé
      if (rememberMe) {
        await saveCredentials(email, password);
      } else {
        await clearSavedCredentials();
      }

      return user;
    } catch (_) {
      // Fallback offline
      final user = await getLocalUserByEmail(email);
      if (user != null) return user;
      throw Exception(
          "Impossible de se connecter (offline + aucun user local trouvé)");
    }
  }

  // ==============================
  // 🔹 REINITIALISATION MDP
  // ==============================
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==============================
  // 🔹 DECONNEXION
  // ==============================
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearLocalSession();
  }

  // ==============================
  // 🔹 SUPPRESSION COMPTE
  // ==============================
  Future<void> deleteAccount() async {
    final current = _auth.currentUser;
    if (current == null) throw Exception("Aucun utilisateur connecté");
    final uid = current.uid;

    try {
      await _fsService.deleteUserData(uid);
    } catch (e) {
      throw Exception("Impossible de supprimer les données Firestore: $e");
    }

    try {
      await current.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == "requires-recent-login") {
        throw Exception(
            "Ré-authentification requise pour supprimer le compte.");
      } else {
        throw Exception(
            "Erreur suppression compte Auth: ${e.message ?? e.code}");
      }
    } finally {
      await logout();
    }
  }

  // ==============================
  // 🔹 REJOUER PENDING USERS
  // ==============================
  Future<void> replayPendingUsers() async {
    final pending = await _localQueue.loadPendingUsers();
    if (pending.isEmpty) return;

    final stillPending = <Map<String, dynamic>>[];

    for (final u in pending) {
      try {
        // ⚠️ Pas de mot de passe dispo offline → admin doit réinviter
        stillPending.add(u);
      } catch (_) {
        stillPending.add(u);
      }
    }

    if (stillPending.isEmpty) {
      await _localQueue.clearPendingUsers();
    } else {
      await _localQueue.replacePendingUsers(stillPending);
    }
  }

  // ==============================
  // 🔹 STOCKAGE LOCAL UTILISATEURS
  // ==============================
  Future<void> _saveUserLocal(AppUser user) async {
    if (kIsWeb) return;
    try {
      final users = await _getAllUsersLocal();
      users.removeWhere((u) => u.uid == user.uid);
      users.add(user);

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/users.json");
      await file
          .writeAsString(jsonEncode(users.map((u) => u.toMap()).toList()));
    } catch (e) {
      print("AuthService._saveUserLocal error: $e");
    }
  }

  Future<List<AppUser>> _getAllUsersLocal() async {
    if (kIsWeb) return [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/users.json");
      if (!await file.exists()) return [];
      final List<dynamic> jsonList = jsonDecode(await file.readAsString());
      return jsonList.map((e) => AppUser.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<AppUser?> getLocalUserByUid(String uid) async {
    final users = await _getAllUsersLocal();
    try {
      return users.firstWhere((u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  Future<AppUser?> getLocalUserByEmail(String email) async {
    final users = await _getAllUsersLocal();
    try {
      return users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  // ==============================
  // 🔹 SE SOUVENIR DE MOI (SharedPreferences)
  // ==============================
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_email", email);
    await prefs.setString("saved_password", password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("saved_email");
    final password = prefs.getString("saved_password");
    if (email != null && password != null) {
      return {"email": email, "password": password};
    }
    return null;
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("saved_email");
    await prefs.remove("saved_password");
  }

  Future<void> _clearLocalSession() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/users.json");
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
