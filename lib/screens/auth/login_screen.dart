// 📁 lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // Service pour gérer Firebase Auth
import '../../app/app_routes.dart'; // Gestion centralisée des routes

/// 🔹 Écran de connexion avec animation, sauvegarde des identifiants
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // 🔹 Champs email & mot de passe
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🔹 Service d’authentification
  final AuthService _authService = AuthService();

  bool _isLoading = false; // Indique si connexion en cours
  bool _obscurePassword = true; // Masquer/afficher mot de passe
  bool _rememberMe = false; // Sauvegarder identifiants

  // 🔹 Animations
  late final AnimationController _formController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animation formulaire
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _formController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // commence légèrement en bas
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOut,
    ));

    // 🔹 Vérifier si identifiants sauvegardés
    _authService.getSavedCredentials().then((saved) {
      if (saved != null && mounted) {
        setState(() {
          _emailController.text = saved['email']!;
          _passwordController.text = saved['password']!;
          _rememberMe = true;
        });
      }
    });

    _formController.forward(); // démarrer animation
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _formController.dispose();
    super.dispose();
  }

  /// 🔹 Fonction login
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔹 Auth via AuthService (Firebase)
      final user = await _authService.login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );

      // 🔹 Sauvegarde si "Se souvenir de moi"
      if (_rememberMe) {
        await _authService.saveCredentials(email, password);
      }

      if (mounted) {
        // Redirection selon rôle
        if (user.role == 'admin') {
          Navigator.pushReplacementNamed(context, AppRoutes.adminPanel);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de connexion : $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔹 Boîte de dialogue réinitialisation mot de passe
  void _showResetPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Réinitialiser le mot de passe"),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "Entrez votre email",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez entrer un email.")),
                  );
                  return;
                }

                try {
                  await _authService.resetPassword(email);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email de réinitialisation envoyé ✅"),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur : $e")),
                    );
                  }
                }
              },
              child: const Text("Envoyer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 400.0; // largeur max pour centrer

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF10B981)], // bleu-vert
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxWidth),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Connexion",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Champ email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Champ mot de passe
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Mot de passe",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Options
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                              ),
                              const Text("Se souvenir de moi"),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _showResetPasswordDialog(),
                                child: const Text("Mot de passe oublié ?"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Bouton connexion
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: Colors.green,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      "Se connecter",
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Lien inscription
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.register),
                            child: const Text(
                              "Vous n'avez pas encore de compte ? S'inscrire",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),

                          // Retour accueil
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.splash),
                            child: const Text(
                              "Page Accueil",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
