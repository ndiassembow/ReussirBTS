// 📁 lib/utils/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Service pour gérer la connectivité réseau
class ConnectivityService {
  // StreamController pour diffuser l'état de connexion (online/offline)
  static final _controller = StreamController<bool>.broadcast();

  // Stream public auquel les widgets peuvent s'abonner
  static Stream<bool> get connectivityStream => _controller.stream;

  /// Initialisation : écoute les changements de connectivité
  static void initialize() {
    Connectivity().onConnectivityChanged.listen((result) {
      // true si connecté à internet, false sinon
      _controller.add(result != ConnectivityResult.none);
    });
  }

  /// Vérifie si l'appareil est actuellement en ligne
  static Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
