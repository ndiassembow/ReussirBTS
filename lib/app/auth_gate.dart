// 📁 lib/app/auth_gate.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';
import '../services/local_user_service.dart';

class AuthService {
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
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final user = AppUser(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: 'etudiant',
        niveau: niveau,
      );

      await _db.collection('users').doc(uid).set(user.toMap());

      await _saveUserLocal(user);
      return user;
    } catch (e) {
      // 🔹 En cas de hors ligne, on garde l’utilisateur en attente (sans mot de passe !)
      final fakeUid = 'pending_${DateTime.now().millisecondsSinceEpoch}';
      final user = AppUser(
        uid: fakeUid,
        name: name,
        email: email,
        phone: phone,
        school: school,
        speciality: speciality,
        role: 'etudiant',
        niveau: niveau,
      );

      await _localQueue.savePendingUserMap(user.toMap());
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
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final snap = await _db.collection('users').doc(cred.user!.uid).get();
      if (snap.exists) {
        final user = AppUser.fromMap(snap.data()!);
        await _saveUserLocal(user);
        return user;
      }

      // fallback local
      final localUser = await getLocalUserByUid(cred.user!.uid);
      if (localUser != null) return localUser;

      return AppUser(
        uid: cred.user!.uid,
        name: cred.user!.displayName ?? '',
        email: cred.user!.email ?? email,
        role: 'etudiant',
        niveau: 'BTS1',
      );
    } catch (e) {
      // 🔹 Offline fallback (sans vérifier password en clair)
      final user = await getLocalUserByEmail(email);
      if (user != null) return user;

      throw Exception("Impossible de se connecter : $e");
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
    await _clearLocalSession();
  }

  // ---------------- REPLAY PENDING USERS ----------------
  Future<void> replayPendingUsers() async {
    try {
      final pending = await _localQueue.loadPendingUsers();
      if (pending.isEmpty) return;

      final List<Map<String, dynamic>> stillPending = [];

      for (final u in pending) {
        try {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: u['email'] as String,
            password: "Temp123!", // ⚠️ temporaire, user devra reset via email
          );

          final uid = cred.user!.uid;
          await _db.collection('users').doc(uid).set({
            ...u,
            'uid': uid,
            'syncedAt': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          stillPending.add(u);
        }
      }

      if (stillPending.isEmpty) {
        await _localQueue.clearPendingUsers();
      } else {
        await _localQueue.replacePendingUsers(stillPending);
      }
    } catch (e) {
      throw Exception("❌ replayPendingUsers error: $e");
    }
  }

  // ---------------- SAUVEGARDE LOCALE ----------------
  Future<void> _saveUserLocal(AppUser user) async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');

      List<AppUser> users = await _getAllUsersLocal();
      users.removeWhere((u) => u.uid == user.uid);
      users.add(user);

      await file.writeAsString(
        jsonEncode(users.map((u) => u.toMap()).toList()),
      );
    } catch (e) {
      throw Exception("❌ _saveUserLocal error: $e");
    }
  }

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

  Future<void> _clearLocalSession() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
