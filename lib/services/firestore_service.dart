// 📁 lib/services/firestore_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/fiche_model.dart';
import '../models/video_model.dart';

/// Service pour interagir avec Firestore et gérer le cache local.
/// 🔹 Gère les utilisateurs, modules, fiches et vidéos.
/// 🔹 Assure un fallback hors-ligne avec `path_provider`.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===================== HELPERS =====================
  /// Convertit une valeur dynamique en `int`.
  int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Extrait un ordre numérique depuis un ID (ex: "fiche12" -> 12).
  int _extractOrderFromId(String id) {
    if (id.isEmpty) return 0;
    final m = RegExp(r'\d+').firstMatch(id);
    return m != null ? int.tryParse(m.group(0)!) ?? 0 : 0;
  }

  /// Définit l'ordre à partir des données Firestore (ou fallback sur ID).
  int _orderFromDocData(Map<String, dynamic> data, String id) {
    if (data.containsKey('order')) {
      return _toInt(data['order'], _extractOrderFromId(id));
    }
    return _extractOrderFromId(id);
  }

  // ===================== USERS =====================
  /// Récupère un utilisateur par son UID (Firestore + fallback local).
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromMap(doc.data()!);
      }
    } catch (e) {
      print('FirestoreService.getUser firestore error: $e');
    }

    // fallback offline
    if (!kIsWeb) {
      final users = await _getAllUsersLocal();
      try {
        return users.firstWhere((u) => u.uid == uid);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Sauvegarde un utilisateur (local + Firestore).
  Future<void> saveUser(AppUser user) async {
    // Local
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/users.json');
        List<AppUser> users = await _getAllUsersLocal();
        users.removeWhere((u) => u.uid == user.uid);
        users.add(user);
        await file
            .writeAsString(jsonEncode(users.map((u) => u.toMap()).toList()));
      } catch (e) {
        print('FirestoreService.saveUser local error: $e');
      }
    }

    // Firestore
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('FirestoreService.saveUser firestore error: $e');
    }
  }

  Future<void> updateUser(AppUser user) async => await saveUser(user);

  /// Supprime toutes les données liées à un utilisateur (quiz + profil).
  Future<void> deleteUserData(String uid) async {
    try {
      final resultsSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('quizResults')
          .get();

      final batch = _db.batch();
      for (final doc in resultsSnap.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_db.collection('users').doc(uid));
      await batch.commit();
    } catch (e) {
      print('FirestoreService.deleteUserData error: $e');
      rethrow;
    }
  }

  /// Récupère tous les utilisateurs stockés en local.
  Future<List<AppUser>> _getAllUsersLocal() async {
    if (kIsWeb) return [];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/users.json');
      if (!await file.exists()) return [];
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList.map((e) => AppUser.fromMap(e)).toList();
    } catch (e) {
      print('FirestoreService._getAllUsersLocal error: $e');
      return [];
    }
  }

  /// Vérifie si un utilisateur est admin.
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists && (doc.data()?['role'] as String?) == 'admin';
    } catch (e) {
      print('FirestoreService.isAdmin error: $e');
      return false;
    }
  }

  // ===================== MODULES =====================
  /// Récupère tous les modules (Firestore + cache local).
  Future<List<Course>> getModules({bool forceRefresh = false}) async {
    List<Course> cachedModules = [];

    // Lire depuis cache
    if (!kIsWeb) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/modules.json');
        if (await file.exists()) {
          final jsonStr = await file.readAsString();
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          cachedModules =
              jsonList.map((e) => Course.fromMap(e, id: e['id'])).toList();
          if (!forceRefresh) return cachedModules;
        }
      } catch (e) {
        print('FirestoreService.getModules cache read error: $e');
      }
    }

    // Lire depuis Firestore
    try {
      final snap = await _db.collection('modules').get();
      List<Course> modules = [];

      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        final moduleId = doc.id;

        final fiches = await getFichesForModule(moduleId);
        final videos = await getVideosForModule(moduleId);

        final moduleMap = Map<String, dynamic>.from(data);
        moduleMap['fiches'] =
            fiches.map((f) => f.toMap()..['id'] = f.id).toList();
        moduleMap['videos'] =
            videos.map((v) => v.toMap()..['id'] = v.id).toList();

        modules.add(Course.fromMap(moduleMap, id: moduleId));
      }

      // Écrire cache
      if (!kIsWeb) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/modules.json');
          await file.writeAsString(jsonEncode(
              modules.map((m) => m.toMap()..['id'] = m.id).toList()));
        } catch (e) {
          print('FirestoreService.getModules cache write error: $e');
        }
      }

      return modules;
    } catch (e) {
      print('FirestoreService.getModules firestore error: $e');
      return cachedModules;
    }
  }

  // ===================== MODULE CONTENT =====================
  /// Récupère les fiches d’un module.
  Future<List<Fiche>> getFichesForModule(String moduleId) async {
    try {
      final snap = await _db
          .collection('modules')
          .doc(moduleId)
          .collection('fichesSynthese')
          .get();

      final pairs = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        final order = _orderFromDocData(m, d.id);
        final fiche = Fiche.fromMap(m, id: d.id);
        return {'order': order, 'fiche': fiche};
      }).toList();

      pairs.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      return pairs.map((p) => p['fiche'] as Fiche).toList();
    } catch (e) {
      print("FirestoreService.getFichesForModule error: $e");
      return [];
    }
  }

  /// Récupère les vidéos d’un module.
  Future<List<VideoItem>> getVideosForModule(String moduleId) async {
    try {
      final snap = await _db
          .collection('modules')
          .doc(moduleId)
          .collection('videos')
          .get();

      final pairs = snap.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        final order = _orderFromDocData(m, d.id);
        final video = VideoItem.fromMap(m, id: d.id);
        return {'order': order, 'video': video};
      }).toList();

      pairs.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      return pairs.map((p) => p['video'] as VideoItem).toList();
    } catch (e) {
      print("FirestoreService.getVideosForModule error: $e");
      return [];
    }
  }

  // ===================== CRUD =====================
  // ---- MODULES ----
  Future<String> addModule(Course course) async {
    final ref = _db.collection('modules').doc(course.id);
    await ref.set(course.toMap());
    return ref.id;
  }

  Future<void> updateModule(Course course) async {
    await _db.collection('modules').doc(course.id).update(course.toMap());
  }

  Future<void> deleteModule(String moduleId) async {
    await _db.collection('modules').doc(moduleId).delete();
  }

  // ---- FICHES ----
  Future<void> addFiche(String moduleId, Fiche fiche) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('fichesSynthese')
        .doc(fiche.id)
        .set(fiche.toMap());
  }

  Future<void> updateFiche(String moduleId, Fiche fiche) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('fichesSynthese')
        .doc(fiche.id)
        .update(fiche.toMap());
  }

  Future<void> deleteFiche(String moduleId, String ficheId) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('fichesSynthese')
        .doc(ficheId)
        .delete();
  }

  // ---- VIDEOS ----
  Future<void> addVideo(String moduleId, VideoItem video) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('videos')
        .doc(video.id)
        .set(video.toMap());
  }

  Future<void> updateVideo(String moduleId, VideoItem video) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('videos')
        .doc(video.id)
        .update(video.toMap());
  }

  Future<void> deleteVideo(String moduleId, String videoId) async {
    await _db
        .collection('modules')
        .doc(moduleId)
        .collection('videos')
        .doc(videoId)
        .delete();
  }
}
