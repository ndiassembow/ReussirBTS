// 📁 lib/screens/revision/module_detail_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/firestore_service.dart';
import '../../models/video_model.dart';
import '../../models/fiche_model.dart';

/// Écran affichant les détails d'un module : vidéos et fiches
class ModuleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> moduleData;

  const ModuleDetailScreen({super.key, required this.moduleData});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<VideoItem> _videos = [];
  List<Fiche> _fiches = [];
  bool _loading = true;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _listenConnectivity();
    _loadData();
  }

  /// 🔹 Surveille l'état de la connexion internet
  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((status) {
      setState(() => _online = status != ConnectivityResult.none);
    });
  }

  /// 🔹 Charge d’abord les données locales (moduleData), puis tente Firestore
  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final moduleId = widget.moduleData['id'] ?? '';

      // --- 1) Données locales transmises depuis RevisionTab ---
      final localVideos = (widget.moduleData['videos'] as List?)
              ?.map((v) => VideoItem.fromMap(Map<String, dynamic>.from(v),
                  id: v['id'] ?? ''))
              .toList() ??
          [];
      final localFiches = (widget.moduleData['fiches'] as List?)
              ?.map((f) => Fiche.fromMap(Map<String, dynamic>.from(f),
                  id: f['id'] ?? ''))
              .toList() ??
          [];

      setState(() {
        _videos = localVideos;
        _fiches = localFiches;
      });

      // --- 2) Tentative de rafraîchissement depuis Firestore ---
      final vids = await _firestore.getVideosForModule(moduleId);
      final fics = await _firestore.getFichesForModule(moduleId);

      setState(() {
        _videos = vids.isNotEmpty ? vids : localVideos;
        _fiches = fics.isNotEmpty ? fics : localFiches;
        _loading = false;
      });
    } catch (e) {
      print("Erreur Firestore: $e");
      setState(() => _loading = false);
    }
  }

  /// 🔹 Ouvre un lien externe (web ou mobile)
  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);

    if (kIsWeb) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, webOnlyWindowName: "_blank");
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 🔹 Télécharge et ouvre une ressource (PDF ou MP4)
  Future<void> _downloadResource(String url, String filename) async {
    if (kIsWeb) return _openUrl(url);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/$filename";
      await Dio().download(url, savePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Téléchargé : $filename")),
      );
      await OpenFile.open(savePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur téléchargement : $e")),
      );
    }
  }

  /// 🔹 Ouvre une vidéo (local ou URL)
  Future<void> _openVideo(VideoItem v) async {
    if (kIsWeb) {
      await _openUrl(v.url);
      return;
    }

    if (v.localPath != null && v.localPath!.isNotEmpty) {
      final path = v.localPath!.startsWith("file://")
          ? v.localPath!.replaceFirst("file://", "")
          : v.localPath!;
      if (await File(path).exists()) {
        await OpenFile.open(path);
        return;
      }
    }

    await _openUrl(v.url);
  }

  /// 🔹 Ouvre une fiche (PDF local ou URL)
  Future<void> _openFiche(Fiche f) async {
    if (kIsWeb) {
      await _openUrl(f.url);
      return;
    }

    if (f.localPath != null && f.localPath!.isNotEmpty) {
      final path = f.localPath!.startsWith("file://")
          ? f.localPath!.replaceFirst("file://", "")
          : f.localPath!;
      if (await File(path).exists()) {
        await OpenFile.open(path);
        return;
      }
    }

    await _openUrl(f.url);
  }

  /// 🔹 Widget pour une tuile vidéo
  Widget _buildVideoTile(VideoItem v, String moduleTitle) {
    final mins = ((v.duration ?? 0) / 60).ceil();
    final levelText = v.level != null ? " • ${v.level}" : "";

    return ListTile(
      leading: const Icon(Icons.play_circle_fill, size: 36, color: Colors.blue),
      title: Text(v.title),
      subtitle: Text("$mins min$levelText"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (v.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Télécharger',
              onPressed: () =>
                  _downloadResource(v.url, '${moduleTitle}_${v.id}.mp4'),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Ouvrir',
            onPressed: () => _openVideo(v),
          ),
        ],
      ),
      onTap: () => _openVideo(v),
    );
  }

  /// 🔹 Widget pour une tuile fiche
  Widget _buildFicheTile(Fiche f, String moduleTitle) {
    final levelText = f.level != null ? " • ${f.level}" : "";

    return ListTile(
      leading: const Icon(Icons.description, size: 32, color: Colors.green),
      title: Text(f.title),
      subtitle: Text('${f.pages ?? "?"} pages$levelText'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (f.url.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Télécharger',
              onPressed: () =>
                  _downloadResource(f.url, '${moduleTitle}_${f.id}.pdf'),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Ouvrir',
            onPressed: () => _openFiche(f),
          ),
        ],
      ),
      onTap: () => _openFiche(f),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moduleTitle = widget.moduleData['title'] ?? 'Module';
    final moduleSubtitle = widget.moduleData['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(moduleTitle),
            if (moduleSubtitle.isNotEmpty)
              Text(moduleSubtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recharger',
              onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_online)
                  Container(
                    width: double.infinity,
                    color: Colors.orange,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      '⚠️ Hors ligne — lecture limitée',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8)),
                          child: const TabBar(
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.black54,
                            tabs: [
                              Tab(icon: Icon(Icons.videocam), text: 'Vidéos'),
                              Tab(
                                  icon: Icon(Icons.insert_drive_file),
                                  text: 'Fiches'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _videos.isEmpty
                                  ? const Center(child: Text("Aucune vidéo"))
                                  : ListView.builder(
                                      itemCount: _videos.length,
                                      itemBuilder: (context, i) =>
                                          _buildVideoTile(
                                              _videos[i], moduleTitle),
                                    ),
                              _fiches.isEmpty
                                  ? const Center(child: Text("Aucune fiche"))
                                  : ListView.builder(
                                      itemCount: _fiches.length,
                                      itemBuilder: (context, i) =>
                                          _buildFicheTile(
                                              _fiches[i], moduleTitle),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
