// lib/services/auth_service.dart
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

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _fsService = FirestoreService();
  final LocalUserService _localQueue = LocalUserService();

  /// 🔹 Getter pour ID de l'utilisateur courant
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// 🔹 Inscription
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String school,
    required String speciality,
    required String password,
    String role = 'etudiant',
    String niveau = 'BTS1',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = cred.user!.uid;

      final user = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: role,
        password: password,
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'school': school,
        'speciality': speciality,
        'role': role,
        'niveau': niveau,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _saveUserLocal(user);
      return user;
    } catch (_) {
      // Fallback offline
      final fakeUid = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final user = AppUser(
        uid: fakeUid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: role,
        password: password,
      );

      await _localQueue.savePendingUserMap({
        'name': name,
        'email': email,
        'phone': phone,
        'school': school,
        'speciality': speciality,
        'password': password,
        'role': role,
        'niveau': niveau,
        'createdAt': DateTime.now().toIso8601String(),
      });

      await _saveUserLocal(user);
      return user;
    }
  }

  /// 🔹 Connexion
  Future<AppUser> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final localUser = await getLocalUserByUid(cred.user!.uid);

      if (rememberMe) await saveCredentials(email, password);

      return localUser ??
          AppUser(
            uid: cred.user!.uid,
            name: cred.user!.displayName ?? '',
            email: cred.user!.email ?? email,
            phone: '',
            school: '',
            speciality: '',
            role: 'etudiant',
            password: password,
          );
    } catch (_) {
      // Fallback offline
      final user = await getLocalUserByEmail(email);
      if (user != null && user.password == password) return user;
      throw Exception(
          "Impossible de se connecter (offline + aucun user local trouvé)");
    }
  }

  /// 🔹 Réinitialisation mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Impossible d’envoyer l’email de réinitialisation : $e");
    }
  }

  /// 🔹 Déconnexion
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearLocalSession();
  }

  /// 🔹 Supprimer compte
  Future<void> deleteAccount() async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Aucun utilisateur connecté');
    final uid = current.uid;

    try {
      await _fsService.deleteUserData(uid);
    } catch (e) {
      throw Exception('Impossible de supprimer les données Firestore: $e');
    }

    try {
      await current.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'Ré-authentification requise pour supprimer le compte.');
      } else {
        throw Exception(
            'Erreur suppression compte Auth: ${e.message ?? e.code}');
      }
    } catch (e) {
      throw Exception('Erreur suppression compte Auth: $e');
    } finally {
      await logout();
    }
  }

  /// 🔹 Rejouer les utilisateurs hors-ligne
  Future<void> replayPendingUsers() async {
    final pending = await _localQueue.loadPendingUsers();
    if (pending.isEmpty) return;

    final List<Map<String, dynamic>> stillPending = [];
    for (final u in pending) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: u['email'], password: u['password']);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
          ...u,
          'uid': cred.user!.uid,
          'syncedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        stillPending.add(u);
      }
    }

    if (stillPending.isEmpty)
      await _localQueue.clearPendingUsers();
    else
      await _localQueue.replacePendingUsers(stillPending);
  }

  /// 🔹 Stockage local des utilisateurs
  Future<void> _saveUserLocal(AppUser user) async {
    if (kIsWeb) return;
    try {
      final users = await _getAllUsersLocal();
      users.removeWhere((u) => u.uid == user.uid);
      users.add(user);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      await file
          .writeAsString(jsonEncode(users.map((u) => u.toMap()).toList()));
    } catch (e) {
      print('AuthService._saveUserLocal error: $e');
    }
  }

  Future<List<AppUser>> _getAllUsersLocal() async {
    if (kIsWeb) return [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (!await file.exists()) return [];
      final List<dynamic> jsonList = jsonDecode(await file.readAsString());
      return jsonList.map((e) => AppUser.fromMap(e)).toList();
    } catch (e) {
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

  /// 🔹 “Se souvenir de moi” via SharedPreferences
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
    await prefs.setString('saved_password', password);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('saved_email');
    final password = prefs.getString('saved_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> _clearLocalSession() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
