// lib/screens/dashboard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reussirbts/provider/user_provider.dart';
import 'package:reussirbts/utils/connectivity_service.dart';
import 'package:reussirbts/widgets/network_banner.dart';

// Import des onglets principaux
import 'tabs/home_tab.dart';
import 'tabs/quiz_tab.dart';
import 'tabs/revision_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/profile_tab.dart';
import 'admin/admin_panel.dart';

/// ================= Dashboard: page principale avec navigation par onglets
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0; // Onglet sélectionné
  bool _isOnline = true; // Statut connectivité

  // Liste des onglets
  final List<Widget> _tabs = const [
    HomeTab(),
    QuizTab(),
    RevisionTab(),
    ProgressTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _loadLastIndex(); // Charger le dernier onglet ouvert
    _listenConnectivity(); // Écouter les changements de réseau
  }

  /// ================= Charger le dernier onglet sélectionné
  Future<void> _loadLastIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt('lastTabIndex') ?? 0;
    });
  }

  /// ================= Sauvegarder l'onglet sélectionné
  Future<void> _saveLastIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastTabIndex', index);
  }

  /// ================= Écoute de la connectivité réseau
  void _listenConnectivity() {
    ConnectivityService.connectivityStream.listen((status) {
      setState(() {
        _isOnline = status;
      });
    });
  }

  /// ================= Gestion du bouton retour
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false; // Ne quitte pas l'app, revient à l'accueil
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBody: true,
        body: Column(
          children: [
            if (!_isOnline) const NetworkBanner(), // Bannière hors ligne
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  final offsetAnim = Tween<Offset>(
                    begin: const Offset(0.05, 0.05),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offsetAnim, child: child),
                  );
                },
                child: _tabs[_currentIndex], // Onglet courant
              ),
            ),
          ],
        ),
        // Barre de navigation inférieure
        bottomNavigationBar: _GlassBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            _saveLastIndex(i); // Sauvegarde l'index
          },
        ),
        // Bouton flottant pour les admins uniquement
        floatingActionButton: userProvider.user?.role == 'admin'
            ? FloatingActionButton.extended(
                backgroundColor: Colors.blueAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanel()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Admin"),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }
}

/// ================= Barre de navigation inférieure avec effet "verre"
class _GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _GlassBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      {'icon': Icons.home, 'label': 'Accueil'},
      {'icon': Icons.quiz, 'label': 'Quiz'},
      {'icon': Icons.book, 'label': 'Révision'},
      {'icon': Icons.bar_chart, 'label': 'Progression'},
      {'icon': Icons.person, 'label': 'Profil'},
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white.withOpacity(0.75),
            elevation: 0,
            currentIndex: currentIndex,
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.black54,
            showUnselectedLabels: true,
            onTap: onTap,
            items: [
              for (int i = 0; i < items.length; i++)
                BottomNavigationBarItem(
                  icon: _AnimatedNavIcon(
                    icon: items[i]['icon'] as IconData,
                    isActive: currentIndex == i,
                  ),
                  label: items[i]['label'] as String,
                )
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= Animation des icônes dans la barre de navigation
class _AnimatedNavIcon extends StatefulWidget {
  final IconData icon;
  final bool isActive;

  const _AnimatedNavIcon({
    required this.icon,
    required this.isActive,
    super.key,
  });

  @override
  State<_AnimatedNavIcon> createState() => _AnimatedNavIconState();
}

class _AnimatedNavIconState extends State<_AnimatedNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      ),
      child: RotationTransition(
        turns: Tween<double>(begin: 0.0, end: 0.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.blueAccent.withOpacity(0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            widget.icon,
            color: widget.isActive ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
