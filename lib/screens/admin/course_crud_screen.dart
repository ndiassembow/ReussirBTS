// lib/screens/admin/course_crud_screen.dart

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/fiche_model.dart';
import '../../models/video_model.dart';

/// 🔹 Écran d’administration : Gestion des fiches & vidéos d’un module
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

  /// Charger la liste des modules
  Future<void> _loadModules() async {
    setState(() => _loading = true);
    try {
      final modules = await _firestore.getModules();
      _modules = modules.map((m) => m.id).toList();

      if (_modules.isNotEmpty) {
        _selectedModule = _modules.first;
        await _loadContent();
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement modules : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Charger fiches + vidéos du module sélectionné
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
      debugPrint("❌ Erreur chargement contenu : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Formulaire d’ajout ou modification
  Future<void> _openDialog({String? docId, String type = "fiche"}) async {
    final isFiche = type == "fiche";

    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();
    String level = "BTS1";

    // Pré-remplissage en cas de modification
    if (docId != null) {
      if (isFiche) {
        final fiche = _fiches.firstWhere((f) => f.id == docId);
        titleCtrl.text = fiche.title;
        urlCtrl.text = fiche.url;
        pagesCtrl.text = fiche.pages?.toString() ?? "";
        level = fiche.level ?? "BTS1";
      } else {
        final video = _videos.firstWhere((v) => v.id == docId);
        titleCtrl.text = video.title;
        urlCtrl.text = video.url;
        level = video.level ?? "BTS1";
      }
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              docId == null
                  ? "➕ Ajouter ${isFiche ? 'fiche' : 'vidéo'}"
                  : "✏️ Modifier ${isFiche ? 'fiche' : 'vidéo'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField("Titre", titleCtrl),
                  const SizedBox(height: 12),
                  _buildTextField(isFiche ? "URL PDF" : "URL Vidéo", urlCtrl),
                  if (isFiche) ...[
                    const SizedBox(height: 12),
                    _buildTextField("Pages", pagesCtrl,
                        keyboardType: TextInputType.number),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedModule == null) return;

                  final id =
                      docId ?? DateTime.now().millisecondsSinceEpoch.toString();

                  if (isFiche) {
                    final fiche = Fiche(
                      id: id,
                      title: titleCtrl.text.trim(),
                      url: urlCtrl.text.trim(),
                      pages: int.tryParse(pagesCtrl.text.trim()) ?? 0,
                      level: level,
                      tags: [],
                    );

                    docId == null
                        ? await _firestore.addFiche(_selectedModule!, fiche)
                        : await _firestore.updateFiche(_selectedModule!, fiche);
                  } else {
                    final video = VideoItem(
                      id: id,
                      title: titleCtrl.text.trim(),
                      url: urlCtrl.text.trim(),
                      duration: 0,
                      level: level,
                      tags: [],
                    );

                    docId == null
                        ? await _firestore.addVideo(_selectedModule!, video)
                        : await _firestore.updateVideo(_selectedModule!, video);
                  }

                  if (context.mounted) Navigator.pop(context);
                  await _loadContent();
                },
                child: Text(docId == null ? "Ajouter" : "Modifier"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Supprimer un élément
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
              underline: const SizedBox(),
              items: _modules
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
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
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("📘 Fiches",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._fiches.map((f) => _buildCard(
                      icon: Icons.article,
                      title: f.title,
                      subtitle: "Fiche • ${f.level}",
                      onEdit: () => _openDialog(docId: f.id, type: "fiche"),
                      onDelete: () => _deleteItem(f.id, "fiche"),
                    )),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("🎬 Vidéos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ..._videos.map((v) => _buildCard(
                      icon: Icons.video_library,
                      title: v.title,
                      subtitle: "Vidéo • ${v.level}",
                      onEdit: () => _openDialog(docId: v.id, type: "video"),
                      onDelete: () => _deleteItem(v.id, "video"),
                    )),
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
          const SizedBox(height: 12),
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

  // ------------------------------
  // Widgets réutilisables
  // ------------------------------
  Widget _buildTextField(String label, TextEditingController ctrl,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
