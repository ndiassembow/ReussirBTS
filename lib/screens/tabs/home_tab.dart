// 📁 lib/screens/tabs/home_tab.dart
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/fiche_model.dart';
import '../../models/video_model.dart';
import '../../services/firestore_service.dart';

/// 🏠 HomeTab : écran principal des modules BTS
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FirestoreService _db = FirestoreService();

  List<Course> _modules = [];
  List<Course> _filtered = [];
  bool _loading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadModules();
    _searchCtrl.addListener(() => _search(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Charge les modules Firestore
  Future<void> _loadModules() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final modules = await _db.getModules();
      if (!mounted) return;
      setState(() {
        _modules = modules;
        _filtered = modules;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Erreur lors du chargement des modules : $e';
        _modules = [];
        _filtered = [];
      });
    }
  }

  /// Filtre recherche
  void _search(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _modules;
      } else {
        _filtered = _modules.where((m) {
          final t = m.title.toLowerCase();
          final d = m.description.toLowerCase();
          return t.contains(query) || d.contains(query);
        }).toList();
      }
    });
  }

  // Liens rapides
  void _goQuizHub() => Navigator.pushNamed(context, '/dashboard/quiz');
  void _goRevisionHub() => Navigator.pushNamed(context, '/dashboard/revision');
  void _goProgressHub() => Navigator.pushNamed(context, '/dashboard/progress');

  /// Détail d’un module
  void _openModule(Course m) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModuleDetail(module: m)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Réussir BTS'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadModules,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          // 👈 padding bas augmenté pour éviter que le menu cache les cartes
          children: [
            // Recherche
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Rechercher un module…",
                prefixIcon:
                    Icon(Icons.search, color: theme.colorScheme.onSurface),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick links
            Row(children: [
              _QuickLink(
                  title: "Quiz",
                  icon: Icons.quiz_outlined,
                  onTap: _goQuizHub,
                  color: Colors.indigo),
              const SizedBox(width: 12),
              _QuickLink(
                  title: "Révision",
                  icon: Icons.menu_book_outlined,
                  onTap: _goRevisionHub,
                  color: Colors.green),
              const SizedBox(width: 12),
              _QuickLink(
                  title: "Progression",
                  icon: Icons.bar_chart_rounded,
                  onTap: _goProgressHub,
                  color: Colors.orange),
            ]),
            const SizedBox(height: 20),

            Text("Modules",
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground)),
            const SizedBox(height: 12),

            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_errorMessage.isNotEmpty)
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error)),
              ))
            else if (_filtered.isEmpty)
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Aucun module trouvé",
                    style: TextStyle(color: theme.colorScheme.onBackground)),
              ))
            else
              ..._filtered.map((m) => Card(
                    child: ListTile(
                      leading: Icon(Icons.menu_book,
                          color: theme.colorScheme.primary),
                      title: Text(m.title,
                          style:
                              TextStyle(color: theme.colorScheme.onBackground)),
                      subtitle: Text(m.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(.7))),
                      trailing: Icon(Icons.chevron_right,
                          color: theme.colorScheme.onBackground),
                      onTap: () => _openModule(m),
                    ),
                  )),

            // 🔥 NOUVELLES SECTIONS ICI
            const SizedBox(height: 24),
            Text("Autres espaces",
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground)),
            const SizedBox(height: 12),

            _EmptySectionCard(
              title: "MICROLEARNING",
              icon: Icons.flash_on,
              color: Colors.cyan,
              message: "Cette section ne dispose pas encore de contenu.",
            ),

            const SizedBox(height: 16),

            _EmptySectionCard(
              title: "EXAMEN BTS",
              icon: Icons.school,
              color: Colors.deepPurple,
              message: "Cette section ne dispose pas encore de contenu.",
            ),

            const SizedBox(height: 40), // 👈 espace supplémentaire en bas
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.title,
      required this.icon,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 76,
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📄 Détail module (titre + desc + fiches + vidéos)
class ModuleDetail extends StatefulWidget {
  final Course module;
  const ModuleDetail({super.key, required this.module});

  @override
  State<ModuleDetail> createState() => _ModuleDetailState();
}

class _ModuleDetailState extends State<ModuleDetail> {
  final FirestoreService _db = FirestoreService();
  bool _loading = true;
  String _errorMessage = '';
  List<Fiche> _fiches = [];
  List<VideoItem> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final fiches = await _db.getFichesForModule(widget.module.id);
      final videos = await _db.getVideosForModule(widget.module.id);

      if (!mounted) return;
      setState(() {
        _fiches = fiches;
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Erreur lors du chargement : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadContent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            Text(widget.module.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground)),
            const SizedBox(height: 12),
            Text(widget.module.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground, height: 1.5)),
            const SizedBox(height: 20),
            if (_loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (_errorMessage.isNotEmpty)
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorMessage,
                    style: TextStyle(color: theme.colorScheme.error)),
              ))
            else ...[
              if (_fiches.isNotEmpty) ...[
                Text("📑 Fiches de synthèse",
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                ..._fiches.map((f) => Card(
                      child: ListTile(
                        leading: Icon(Icons.description,
                            color: theme.colorScheme.primary),
                        title: Text(f.title),
                        subtitle: Text(f.description ?? '',
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          f.pages != null ? "${f.pages}p" : "",
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],
              if (_videos.isNotEmpty) ...[
                Text("🎥 Vidéos",
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 8),
                ..._videos.map((v) => Card(
                      child: ListTile(
                        leading: Icon(Icons.play_circle_fill,
                            color: theme.colorScheme.secondary),
                        title: Text(v.title),
                        subtitle: Text(
                          [
                            if (v.description != null) v.description,
                            if (v.duration != null) "${v.duration} min",
                            if (v.level != null) "Niveau ${v.level}",
                          ].where((e) => e != null && e.isNotEmpty).join(" • "),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          v.watched ? Icons.check_circle : Icons.play_arrow,
                          color: v.watched ? Colors.green : Colors.grey,
                        ),
                      ),
                    )),
              ],
            ]
          ],
        ),
      ),
    );
  }
}

/// 🎨 Widget réutilisable pour les sections vides
class _EmptySectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String message;

  const _EmptySectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$title — Bientôt disponible")),
        );
      },
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(.8), color.withOpacity(.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 26,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(message,
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
