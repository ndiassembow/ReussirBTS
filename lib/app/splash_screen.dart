// lib/screens/splash_screen.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../utils/connectivity_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final Animation<double> _bgAnim;
  StreamSubscription<bool>? _connSub;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();

    // Fond animé léger (boucles lentes pour l'effet pro)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgController, curve: Curves.easeInOut);

    // Écoute réseau en direct
    _connSub = ConnectivityService.connectivityStream.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });

    // Check initial du réseau
    ConnectivityService.isOnline().then((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  void _openBottomSheet({
    required String title,
    required List<Widget> children,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkBanner() {
    if (_isOnline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.redAccent,
      child: const SafeArea(
        bottom: false,
        child: Text(
          'Vous êtes hors ligne — certaines fonctionnalités peuvent être limitées.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Section Hero avec CTA
  Widget _heroSection() {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: isWide ? 6 : 10,
                child: Column(
                  crossAxisAlignment: isWide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Réussir BTS',
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ton hub d’apprentissage moderne : révisions intelligentes, micro-learnings, quiz adaptatifs, suivi de progression.',
                      textAlign: isWide ? TextAlign.left : TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color.onSurface.withOpacity(0.75),
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment:
                          isWide ? WrapAlignment.start : WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/login'),
                          icon: const Icon(Icons.login),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: const Text('Se connecter'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          icon: const Icon(Icons.person_add_alt),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          label: const Text("Créer un compte"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isWide
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        _badge('Révisions rapides', Icons.timer),
                        const SizedBox(width: 8),
                        _badge('Suivi personnalisé', Icons.insights),
                        const SizedBox(width: 8),
                        _badge('100% gratuit', Icons.favorite),
                      ],
                    ),
                  ],
                ),
              ),
              if (isWide) const SizedBox(width: 24),
              if (isWide)
                Expanded(
                  flex: 5,
                  child: _heroIllustration(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroIllustration() {
    final radius = BorderRadius.circular(24);
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image d’illustration (optionnelle)
            Image.asset(
              AppConstants.splashImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.05),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _glassCard(
                child: Row(
                  children: const [
                    Icon(Icons.flash_on, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Commence par une session de micro-learning de 10 min.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Section fonctionnalités
  Widget _featuresSection() {
    final tiles = [
      _featureTile(
        icon: Icons.menu_book_rounded,
        title: 'Modules structurés',
        desc:
            'Accès rapide aux cours, fiches et vidéos. Organisation claire par matières et niveaux.',
      ),
      _featureTile(
        icon: Icons.bolt,
        title: 'Micro-learning',
        desc:
            'Capsules rapides (8–10 min) pour réviser efficacement tes notions clés.',
      ),
      _featureTile(
        icon: Icons.quiz_outlined,
        title: 'Quiz intelligents',
        desc:
            'Questions ciblées, correction instantanée et historique des résultats.',
      ),
      _featureTile(
        icon: Icons.bar_chart_rounded,
        title: 'Suivi de progression',
        desc:
            'Visualise tes scores, tendances et objectifs. Reste motivé jour après jour.',
      ),
      _featureTile(
        icon: Icons.shield_outlined,
        title: 'Données sécurisées',
        desc:
            'Synchronisation quand tu es en ligne + fallback local hors-ligne.',
      ),
      _featureTile(
        icon: Icons.emoji_events,
        title: 'Préparation optimale',
        desc:
            'Tous les outils pour réussir ton BTS : cours, quiz, suivi et conseils méthodologiques.',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Pourquoi Réussir BTS ?'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (_, c) {
              final w = c.maxWidth;
              int crossAxis = 1;
              if (w > 1200)
                crossAxis = 3;
              else if (w > 800) crossAxis = 2;
              return GridView.count(
                crossAxisCount: crossAxis,
                shrinkWrap: true,
                childAspectRatio: 1.35,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: tiles,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _featureTile(
      {required IconData icon, required String title, required String desc}) {
    final cardColor = Theme.of(context).colorScheme.surface;
    return _elevCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconCircle(icon),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.75),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      color: cardColor,
    );
  }

  Widget _microCard(String title, String duration) {
    return SizedBox(
      width: 220,
      child: _elevCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // CTA simple pour amener au login/inscription
            Navigator.pushNamed(context, '/login');
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flash_on, size: 28),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(duration,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(.7),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Statistiques (look "pro")
  Widget _statsSection() {
    final stats = [
      _stat('+35', 'Questions de quiz'),
      _stat('98%', 'Satisfaction'),
      _stat('10 min', 'Sessions rapides'),
      _stat('3', 'Plateformes'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(.08),
              Theme.of(context).colorScheme.secondary.withOpacity(.08),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            final isWide = w > 900;
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              runSpacing: 16,
              children: stats
                  .map((s) => SizedBox(
                        width: isWide ? (w / 5) : 160,
                        child: _glassCard(child: s),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.75),
              )),
        ],
      ),
    );
  }

  // Section Description BTS
  Widget _btsDescriptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: _elevCard(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Le BTS, c’est quoi ?'),
              const SizedBox(height: 8),
              Text(
                "Le Brevet de Technicien Supérieur (BTS) est un diplôme d’État en deux ans, très orienté pratique et professionnalisation. "
                "Il prépare efficacement à l’insertion professionnelle ou à la poursuite d’études (Bachelor, Licence, etc.). "
                "Avec Réussir BTS, tu retrouves les notions clés, des entraînements ciblés et un suivi de progression pour maximiser tes chances.",
                style: TextStyle(
                  height: 1.35,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.85),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _chip('Comptabilité'),
                  _chip('Maths appli'),
                  _chip('Eco-Gestion'),
                  _chip('Culture Éco'),
                  _chip('Projet tutoré'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section FAQ
  Widget _faqSection() {
    final faqs = [
      {
        'q': 'Comment l’app peut m’aider à réussir mon BTS ?',
        'a':
            'En te proposant des cours résumés, des quiz intelligents et un suivi de progression clair pour rester motivé.',
      },
      {
        'q': 'Combien de temps faut-il réviser chaque jour ?',
        'a':
            'Nous recommandons 10 à 15 minutes de micro-learning quotidien pour progresser efficacement.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('FAQ'),
          const SizedBox(height: 8),
          _elevCard(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final f = faqs[i];
                return ExpansionTile(
                  title: Text(
                    f['q']!,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  childrenPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        f['a']!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // CTA final
  Widget _ctaSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _elevCard(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(.12),
                Theme.of(context).colorScheme.secondary.withOpacity(.12),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                'Prêt·e à booster tes révisions ?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crée un compte en 30 secondes ou connecte-toi pour reprendre là où tu t’étais arrêté·e.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.8),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("S'inscrire"),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Footer avec liens (À propos, Politique, Contact)
  Widget _footerSection() {
    final onSurfaceMuted =
        Theme.of(context).colorScheme.onSurface.withOpacity(.7);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(.5),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(.4),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Réussir BTS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _footerLink(
                      label: 'À propos',
                      onTap: () => _openBottomSheet(
                        title: 'À propos',
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            "Réussir BTS est une application pensée pour des révisions modernes et efficaces. "
                            "Notre objectif : te fournir le bon contenu au bon moment, avec une expérience fluide sur toutes les plateformes.",
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Version : 1.0.0",
                            style: TextStyle(color: onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    _footerLink(
                      label: 'Politique de confidentialité',
                      onTap: () => _openBottomSheet(
                        title: 'Politique de confidentialité',
                        children: const [
                          SizedBox(height: 8),
                          Text(
                            "Nous respectons ta vie privée. Les données collectées servent à l’authentification, la sauvegarde des progrès et l’amélioration du service. "
                            "En mode hors-ligne, certaines informations sont stockées localement sur ton appareil.",
                          ),
                          SizedBox(height: 8),
                          Text(
                            "En te connectant, tu acceptes notre politique de confidentialité.",
                          ),
                        ],
                      ),
                    ),
                    _footerLink(
                      label: 'Conditions d’utilisation',
                      onTap: () => _openBottomSheet(
                        title: "Conditions d’utilisation",
                        children: const [
                          SizedBox(height: 8),
                          Text(
                            "L’application est fournie en l’état. Les contenus pédagogiques sont destinés à l’entraînement. "
                            "Il est interdit de copier ou redistribuer sans autorisation.",
                          ),
                        ],
                      ),
                    ),
                    _footerLink(
                      label: 'Contact',
                      onTap: () => _openBottomSheet(
                        title: 'Contact',
                        children: const [
                          SizedBox(height: 8),
                          Text("Email : devopsdesigngest@gmail.com"),
                          SizedBox(height: 6),
                          Text("Réponse sous 48h ouvrées."),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              '© ${DateTime.now().year} Réussir BTS — Tous droits réservés.',
              textAlign: TextAlign.center,
              style: TextStyle(color: onSurfaceMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerLink({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ---------- Helpers UI ----------

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon),
    );
  }

  Widget _elevCard({required Widget child, Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(.25),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(.3),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  // Fond animé avec blobs/gradients doux (sans package externe)
  Widget _animatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnim,
      builder: (_, __) {
        final t = _bgAnim.value;
        return Stack(
          children: [
            // Gradient principal
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F7FF), Color(0xFFEFF3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Blobs décoratifs
            Positioned(
              top: 80 + 20 * (t - 0.5),
              left: -120,
              child: _blob(const Color(0xFFB3C7FF), 260),
            ),
            Positioned(
              bottom: -100,
              right: -80 + 25 * (0.5 - t),
              child: _blob(const Color(0xFFAAD9D9), 220),
            ),
            Positioned(
              top: 300,
              right: -140,
              child: _blob(const Color(0xFFE5B8FF), 280),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(Color color, double size) {
    return Transform.rotate(
      angle: 0.5,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(.28),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _animatedBackground(),
          // Contenu scrollable
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                snap: false,
                elevation: 0,
                backgroundColor:
                    Theme.of(context).colorScheme.surface.withOpacity(.9),
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding:
                      EdgeInsetsDirectional.only(start: 16, bottom: 12),
                  title: Text('Réussir BTS'),
                ),
              ),
              SliverToBoxAdapter(child: _networkBanner()),
              SliverToBoxAdapter(child: _heroSection()),
              SliverToBoxAdapter(child: _featuresSection()),
              // SliverToBoxAdapter(child: _microlearningSection()),
              SliverToBoxAdapter(child: _statsSection()),
              SliverToBoxAdapter(child: _btsDescriptionSection()),
              SliverToBoxAdapter(child: _faqSection()),
              SliverToBoxAdapter(child: _ctaSection()),
              SliverToBoxAdapter(child: _footerSection()),
            ],
          ),
        ],
      ),
    );
  }
}
