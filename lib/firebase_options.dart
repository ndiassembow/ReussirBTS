// lib/firebase_options.dart

// Import FirebaseOptions, qui permet de configurer l’application Firebase
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

// Import des constantes Flutter pour détecter la plateforme (web, Android, iOS, etc.)
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Classe qui contient toutes les configurations Firebase
/// générées automatiquement par `flutterfire configure`.
/// 👉 Permet d’initialiser Firebase correctement selon la plateforme.
class DefaultFirebaseOptions {
  /// Retourne la configuration Firebase adaptée à la plateforme courante
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web; // Cas du Web
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android; // Cas Android
      case TargetPlatform.iOS:
        return ios; // Cas iOS
      case TargetPlatform.macOS:
        return macos; // Cas macOS
      case TargetPlatform.windows:
        return windows; // Cas Windows
      case TargetPlatform.linux:
        // Pas configuré, il faut relancer `flutterfire configure`
        throw UnsupportedError(
            'Linux non configuré. Reconfigurer avec FlutterFire CLI.');
      default:
        // Cas où la plateforme n’est pas reconnue
        throw UnsupportedError('Plateforme non supportée');
    }
  }

  /// 🔹 Configuration pour le Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDVPG6iS88SMttGhK6oB-yMzIeip1qLNbE',
    appId: '1:807140710167:web:5bdca195a2577bc4450952',
    messagingSenderId: '807140710167',
    projectId: 'reussirbts',
    authDomain: 'reussirbts.firebaseapp.com',
    storageBucket: 'reussirbts.firebasestorage.app',
  );

  /// 🔹 Configuration pour Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBq-sDrk9GDjKVwB-kbWxWYADQedTPgXno',
    appId: '1:807140710167:android:d89ce773d1aefe13450952',
    messagingSenderId: '807140710167',
    projectId: 'reussirbts',
    storageBucket: 'reussirbts.firebasestorage.app',
  );

  /// 🔹 Configuration pour iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAbc9n1cmPGZDrIs1q6wy15SOfeLSL22SY',
    appId: '1:807140710167:ios:440ea7369515507e450952',
    messagingSenderId: '807140710167',
    projectId: 'reussirbts',
    storageBucket: 'reussirbts.firebasestorage.app',
    iosBundleId: 'com.example.reussirbts', // Identifiant unique iOS
  );

  /// 🔹 Configuration pour macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAbc9n1cmPGZDrIs1q6wy15SOfeLSL22SY',
    appId: '1:807140710167:ios:440ea7369515507e450952',
    messagingSenderId: '807140710167',
    projectId: 'reussirbts',
    storageBucket: 'reussirbts.firebasestorage.app',
    iosBundleId: 'com.example.reussirbts',
  );

  /// 🔹 Configuration pour Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDVPG6iS88SMttGhK6oB-yMzIeip1qLNbE',
    appId: '1:807140710167:web:c43a142858692d80450952',
    messagingSenderId: '807140710167',
    projectId: 'reussirbts',
    authDomain: 'reussirbts.firebaseapp.com',
    storageBucket: 'reussirbts.firebasestorage.app',
  );
}
