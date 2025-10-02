// lib/screens/tabs/revision_tab.dart
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/course_model.dart';
import '../revision/module_detail_screen.dart';

/// ================= RevisionTab: Liste des modules et recherches
class RevisionTab extends StatefulWidget {
  const RevisionTab({super.key});

  @override
  State<RevisionTab> createState() => _RevisionTabState();
}

class _RevisionTabState extends State<RevisionTab> {
  // Contrôleur pour la barre de recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Service Firestore pour récupérer les données
  final FirestoreService _firestore = FirestoreService();

  // Liste des modules chargés depuis Firestore
  List<Course> _modules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModules(); // Chargement initial des modules
  }

  /// ================= Charger tous les modules depuis Firestore
  Future<void> _loadModules() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final mods = await _firestore.getModules(); // Appel au service
      setState(() {
        _modules = mods;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur chargement modules : $e";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrage des modules selon la recherche
    final filtered = _modules.where((m) {
      final q = _searchQuery.trim().toLowerCase();
      final title = m.title.toLowerCase();
      final desc = m.description.toLowerCase();
      final tags = m.tags.join(' ').toLowerCase();
      return q.isEmpty ||
          title.contains(q) ||
          desc.contains(q) ||
          tags.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Révisions"),
        centerTitle: true,
        actions: [
          // Bouton de rafraîchissement
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _loadModules,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher TEST un module, matière ou mot-clé...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          if (_loading) const LinearProgressIndicator(), // Barre de chargement
          if (_error != null) // Affichage d'erreur
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading && _modules.isEmpty
                ? const Center(
                    child: CircularProgressIndicator()) // Chargement initial
                : filtered.isEmpty
                    ? const Center(
                        child: Text('Aucun module trouvé')) // Aucun résultat
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final Course module = filtered[index];
                          final displayTitle = module.title.isNotEmpty
                              ? module.title
                              : (module.description.isNotEmpty
                                  ? module.description
                                  : module.id);

                          final fichesCount = module.fiches.length;
                          final videosCount = module.videos.length;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: module.imageUrl != null &&
                                      module.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(module.imageUrl!,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover),
                                    )
                                  : Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.book,
                                          size: 30, color: Colors.blue),
                                    ),
                              title: Text(displayTitle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Text(
                                  "$fichesCount fiches • $videosCount vidéos",
                                  style: const TextStyle(color: Colors.grey)),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () {
                                // Navigation vers l'écran de détails du module
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModuleDetailScreen(
                                      moduleData: {
                                        ...module.toMap(),
                                        'fiches': module.fiches
                                            .map((f) => f.toMap())
                                            .toList(),
                                        'videos': module.videos
                                            .map((v) => v.toMap())
                                            .toList(),
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
