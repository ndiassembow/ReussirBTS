// lib/screens/admin/course_crud_screen.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/fiche_model.dart';
import '../../models/video_model.dart';

/// Écran d’administration : Gestion des fiches et vidéos par module
class CourseCrud extends StatefulWidget {
  const CourseCrud({super.key});

  @override
  State<CourseCrud> createState() => _CourseCrudState();
}

class _CourseCrudState extends State<CourseCrud> {
  final FirestoreService _firestore = FirestoreService();

  bool _loading = true;
  List<String> _modules = [];
  String? _selectedModule;

  List<Fiche> _fiches = [];
  List<VideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  /// Chargement des modules
  Future<void> _loadModules() async {
    setState(() => _loading = true);
    try {
      final modules = await _firestore.getModules();
      _modules = modules.map((m) => m.id).toList();
      if (_modules.isNotEmpty) _selectedModule = _modules.first;
      await _loadContent();
    } catch (e) {
      debugPrint("Erreur lors du chargement des modules : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Chargement des fiches et vidéos du module sélectionné
  Future<void> _loadContent() async {
    if (_selectedModule == null) return;

    setState(() => _loading = true);
    try {
      final fiches = await _firestore.getFichesForModule(_selectedModule!);
      final videos = await _firestore.getVideosForModule(_selectedModule!);

      setState(() {
        _fiches = fiches;
        _videos = videos;
      });
    } catch (e) {
      debugPrint("Erreur chargement contenu : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Ouvre un formulaire (ajout / édition) d’une fiche ou d’une vidéo
  Future<void> _openDialog({String? docId, String type = "fiche"}) async {
    final isFiche = type == "fiche";

    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final pagesController = TextEditingController();
    String level = "BTS1";

    // Pré-remplissage si modification
    if (docId != null) {
      if (isFiche) {
        final fiche = _fiches.firstWhere((f) => f.id == docId);
        titleController.text = fiche.title;
        urlController.text = fiche.url;
        pagesController.text = fiche.pages?.toString() ?? "";
        level = fiche.level ?? "BTS1";
      } else {
        final video = _videos.firstWhere((v) => v.id == docId);
        titleController.text = video.title;
        urlController.text = video.url;
        level = video.level ?? "BTS1";
      }
    }

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                docId == null
                    ? "Ajouter ${isFiche ? 'fiche' : 'vidéo'}"
                    : "Modifier ${isFiche ? 'fiche' : 'vidéo'}",
              ),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Titre",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: isFiche ? "URL PDF" : "URL vidéo",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      if (isFiche) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: pagesController,
                          decoration: const InputDecoration(
                            labelText: "Pages",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: level,
                        decoration: const InputDecoration(
                          labelText: "Niveau",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: "BTS1", child: Text("BTS1")),
                          DropdownMenuItem(value: "BTS2", child: Text("BTS2")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => level = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedModule == null) return;

                    final id = docId ??
                        DateTime.now().millisecondsSinceEpoch.toString();

                    if (isFiche) {
                      final fiche = Fiche(
                        id: id,
                        title: titleController.text.trim(),
                        url: urlController.text.trim(),
                        pages: int.tryParse(pagesController.text.trim()) ?? 0,
                        level: level,
                        tags: [],
                      );

                      if (docId == null) {
                        await _firestore.addFiche(_selectedModule!, fiche);
                      } else {
                        await _firestore.updateFiche(_selectedModule!, fiche);
                      }
                    } else {
                      final video = VideoItem(
                        id: id,
                        title: titleController.text.trim(),
                        url: urlController.text.trim(),
                        duration: 0,
                        level: level,
                        tags: [],
                      );

                      if (docId == null) {
                        await _firestore.addVideo(_selectedModule!, video);
                      } else {
                        await _firestore.updateVideo(_selectedModule!, video);
                      }
                    }

                    Navigator.pop(context);
                    await _loadContent();
                  },
                  child: Text(docId == null ? "Ajouter" : "Modifier"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Supprimer une fiche ou vidéo
  Future<void> _deleteItem(String id, String type) async {
    if (_selectedModule == null) return;

    if (type == "fiche") {
      await _firestore.deleteFiche(_selectedModule!, id);
    } else {
      await _firestore.deleteVideo(_selectedModule!, id);
    }
    await _loadContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion Fiches & Vidéos"),
        actions: [
          if (_modules.isNotEmpty)
            DropdownButton<String>(
              value: _selectedModule,
              items: _modules
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedModule = val);
                  _loadContent();
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("📘 Fiches", style: TextStyle(fontSize: 18)),
                ),
                ..._fiches.map(
                  (f) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.article),
                      title: Text(f.title),
                      subtitle: Text("Fiche • ${f.level}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _openDialog(docId: f.id, type: "fiche"),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(f.id, "fiche"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("🎬 Vidéos", style: TextStyle(fontSize: 18)),
                ),
                ..._videos.map(
                  (v) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.video_library),
                      title: Text(v.title),
                      subtitle: Text("Vidéo • ${v.level}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () =>
                                _openDialog(docId: v.id, type: "video"),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(v.id, "video"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: "fiche",
            icon: const Icon(Icons.article),
            label: const Text("Ajouter fiche"),
            onPressed: () => _openDialog(type: "fiche"),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "video",
            icon: const Icon(Icons.video_library),
            label: const Text("Ajouter vidéo"),
            onPressed: () => _openDialog(type: "video"),
          ),
        ],
      ),
    );
  }
}
