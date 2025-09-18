// 📁 lib/screens/tabs/home_tab.dart
import 'package:flutter/material.dart';

/// 🏠 HomeTab : écran principal des modules BTS
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Controller pour la barre de recherche
  final TextEditingController _searchCtrl = TextEditingController();

  // Listes des modules et des modules filtrés
  List<Map<String, String>> _modules = [];
  List<Map<String, String>> _filtered = [];
  bool _loading = true; // Indique si les modules sont en cours de chargement

  @override
  void initState() {
    super.initState();
    _loadModules(); // Charger les modules au démarrage
    _searchCtrl
        .addListener(() => _search(_searchCtrl.text)); // Filtrage en temps réel
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 🔹 Simule le chargement des modules (peut être remplacé par un fetch depuis Firebase)
  Future<void> _loadModules() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simule un délai
    final modules = [
      {
        "title": "Économie Générale (Niveau 1)",
        "description":
            "Introduction aux notions fondamentales d’économie : offre, demande, marché, inflation, croissance et développement. Cours adapté aux réalités économiques du Sénégal et de l’Afrique de l’Ouest."
      },
      {
        "title": "Comptabilité Générale (Niveau 1)",
        "description":
            "Bases de la comptabilité : bilan, compte de résultat, journal, grand livre. Étude des entreprises sénégalaises comme cas pratiques."
      },
      {
        "title": "Droit des Affaires (Niveau 2)",
        "description":
            "Introduction au droit OHADA, contrats commerciaux, sociétés, procédures collectives. Mise en contexte avec des exemples de jurisprudence sénégalaise."
      },
      {
        "title": "Mathématiques Financières (Niveau 2)",
        "description":
            "Calculs d’intérêts simples et composés, actualisation, annuités, amortissements. Application aux crédits bancaires courants au Sénégal."
      },
      {
        "title": "Communication Professionnelle (Niveau 1)",
        "description":
            "Méthodes de rédaction administrative, techniques de communication orale et écrite adaptées au contexte professionnel sénégalais."
      },
      {
        "title": "Gestion des Ressources Humaines (Niveau 2)",
        "description":
            "Gestion du personnel, recrutement, formation et droit du travail sénégalais. Cas pratiques sur les PME locales."
      },
    ];

    // Met à jour l'état avec les modules chargés
    setState(() {
      _modules = modules;
      _filtered = modules;
      _loading = false;
    });
  }

  /// 🔹 Filtre les modules selon la requête de recherche
  void _search(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _modules;
      } else {
        _filtered = _modules
            .where((m) => m["title"]!.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  // 🔹 Navigation rapide vers les différents hubs
  void _goQuizHub() => Navigator.pushNamed(context, '/dashboard/quiz');
  void _goRevisionHub() => Navigator.pushNamed(context, '/dashboard/revision');
  void _goProgressHub() => Navigator.pushNamed(context, '/dashboard/progress');

  /// 🔹 Ouvre l'écran de détail du module
  void _openModule(Map<String, String> m) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleDetail(module: m),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _loadModules, // Permet de recharger les modules
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ===== HEADER avec recherche =====
            SliverToBoxAdapter(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary
                          ]
                        : const [Color(0xFF2563EB), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.school,
                          color: theme.colorScheme.onPrimary, size: 36),
                      const SizedBox(width: 10),
                      Text("Réussir BTS",
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 10),
                    Text("Modules BTS Sénégal – Niveaux 1 et 2.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onPrimary.withOpacity(.9))),
                    const SizedBox(height: 14),
                    // Barre de recherche
                    TextField(
                      controller: _searchCtrl,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Rechercher un module…",
                        hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(.7)),
                        filled: true,
                        fillColor: isDark
                            ? theme.colorScheme.surfaceVariant
                            : Colors.white,
                        prefixIcon: Icon(Icons.search,
                            color: theme.colorScheme.onSurface.withOpacity(.7)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== LIENS RAPIDES =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
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
              ),
            ),

            // ===== TITRE DES MODULES =====
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text("Modules",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    )),
              ),
            ),

            // ===== LISTE DES MODULES =====
            if (_loading)
              const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()))
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text("Aucun module trouvé",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onBackground)),
              )))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final m = _filtered[i];
                    return ListTile(
                      leading: Icon(Icons.menu_book,
                          color: theme.colorScheme.primary),
                      title: Text(m["title"]!,
                          style:
                              TextStyle(color: theme.colorScheme.onBackground)),
                      subtitle: Text(m["description"]!,
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(.7))),
                      trailing: Icon(Icons.chevron_right,
                          color: theme.colorScheme.onBackground),
                      onTap: () => _openModule(m),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 🔹 Widget lien rapide
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(.2) : color.withOpacity(.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Détail du module (texte descriptif)
class ModuleDetail extends StatelessWidget {
  final Map<String, String> module;
  const ModuleDetail({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(module["title"]!)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(module["title"]!,
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onBackground)),
            const SizedBox(height: 12),
            Text(module["description"]!,
                style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onBackground, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
