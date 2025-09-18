// 📁 lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../provider/user_provider.dart';
import '../../utils/validators.dart';

/// Écran d'inscription utilisateur (toujours rôle "étudiant").
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // 🔹 Contrôleurs des champs
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _specialityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // 🔹 Rôle forcé et niveau sélectionné
  String _role = 'etudiant';
  String _niveau = 'BTS1';

  // 🔹 État de chargement / hors ligne
  bool _loading = false;
  bool _offline = false;

  // 🔹 Messages d’erreurs pour validation
  String? _nameError,
      _emailError,
      _phoneError,
      _schoolError,
      _specialityError,
      _passwordError,
      _confirmError;

  // 🔹 Contrôleurs d’animation
  late final AnimationController _formController;
  late final AnimationController _btsController;
  late final AnimationController _footerController;

  @override
  void initState() {
    super.initState();

    // Validation en temps réel sur chaque champ
    _nameCtrl.addListener(_validateField);
    _emailCtrl.addListener(_validateField);
    _phoneCtrl.addListener(_validateField);
    _schoolCtrl.addListener(_validateField);
    _specialityCtrl.addListener(_validateField);
    _passwordCtrl.addListener(_validateField);
    _confirmCtrl.addListener(_validateField);

    // Initialisation des animations
    _formController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _btsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _footerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    // Lancement séquentiel des animations
    _formController.forward().then((_) {
      _btsController.forward().then((_) {
        _footerController.forward();
      });
    });
  }

  @override
  void dispose() {
    // Libération mémoire
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _schoolCtrl.dispose();
    _specialityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _formController.dispose();
    _btsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  /// Validation des champs avec utilitaires
  void _validateField() {
    setState(() {
      _nameError = Validators.fullName(_nameCtrl.text);
      _emailError = Validators.email(_emailCtrl.text);
      _phoneError = Validators.phone(_phoneCtrl.text);
      _schoolError = Validators.minLengthNoRepeat(_schoolCtrl.text, 4);
      _specialityError = Validators.minLengthNoRepeat(_specialityCtrl.text, 4);
      _passwordError = Validators.password(_passwordCtrl.text);
      _confirmError = _confirmCtrl.text != _passwordCtrl.text
          ? 'Les mots de passe ne correspondent pas'
          : null;
    });
  }

  /// Action : Inscrire l’utilisateur
  void _register() async {
    _validateField();

    // Stop si erreurs
    if (_nameError != null ||
        _emailError != null ||
        _phoneError != null ||
        _schoolError != null ||
        _specialityError != null ||
        _passwordError != null ||
        _confirmError != null) return;

    setState(() => _loading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        school: _schoolCtrl.text.trim(),
        speciality: _specialityCtrl.text.trim(),
        password: _passwordCtrl.text,
        offline: _offline,
        role: _role, // 🔹 toujours "etudiant"
        niveau: _niveau, // 🔹 BTS1 ou BTS2
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Inscription réussie ! Vérifiez votre email."),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Widget utilitaire pour cartes animées
  Widget buildAnimatedCard({
    required Widget child,
    required AnimationController controller,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: controller.value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - controller.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const maxWidth = 500.0;

    /// Carte réutilisable
    Widget buildCard({required Widget child}) {
      return Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🔹 Logo
                  Icon(Icons.school,
                      size: width < 600 ? 100 : 150, color: Colors.white),
                  const SizedBox(height: 16),

                  // 🔹 Titre
                  Text("Réussir BTS",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: width < 600 ? 32 : 48,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),

                  // 🔹 Sous-titre
                  Text("Inscrivez-vous pour accéder aux cours et quiz",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: width < 600 ? 16 : 20),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),

                  // 🔹 Formulaire animé
                  buildAnimatedCard(
                    controller: _formController,
                    child: buildCard(
                      child: Column(
                        children: [
                          // Champs du formulaire
                          CustomInput(
                              label: "Nom complet",
                              controller: _nameCtrl,
                              errorText: _nameError),
                          CustomInput(
                              label: "Email",
                              controller: _emailCtrl,
                              errorText: _emailError),
                          CustomInput(
                              label: "Téléphone",
                              controller: _phoneCtrl,
                              errorText: _phoneError),
                          CustomInput(
                              label: "École",
                              controller: _schoolCtrl,
                              errorText: _schoolError),
                          CustomInput(
                              label: "Spécialité",
                              controller: _specialityCtrl,
                              errorText: _specialityError),
                          const SizedBox(height: 12),

                          // Sélection du niveau
                          DropdownButtonFormField<String>(
                            value: _niveau,
                            decoration:
                                const InputDecoration(labelText: 'Niveau'),
                            items: const [
                              DropdownMenuItem(
                                  value: 'BTS1', child: Text('BTS 1')),
                              DropdownMenuItem(
                                  value: 'BTS2', child: Text('BTS 2')),
                            ],
                            onChanged: (v) => setState(() => _niveau = v!),
                          ),
                          const SizedBox(height: 12),

                          // Mots de passe
                          CustomInput(
                              label: "Mot de passe",
                              controller: _passwordCtrl,
                              isPassword: true,
                              errorText: _passwordError),
                          CustomInput(
                              label: "Confirmer mot de passe",
                              controller: _confirmCtrl,
                              isPassword: true,
                              errorText: _confirmError),
                          const SizedBox(height: 24),

                          // Bouton inscription ou loader
                          _loading
                              ? const CircularProgressIndicator()
                              : CustomButton(
                                  text: "S'inscrire", onPressed: _register),
                          const SizedBox(height: 24),

                          // Ligne séparation
                          Row(
                            children: const [
                              Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("ou continuer avec"),
                              ),
                              Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Autres boutons d’authentification
                          CustomButton(
                              text: "📧 Continuer avec Email",
                              onPressed: _register),
                          const SizedBox(height: 12),

                          CustomButton(
                            text: "🔵 Continuer avec Google",
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Google Auth pas encore activé")),
                            ),
                          ),
                          const SizedBox(height: 12),

                          CustomButton(
                            text: " Continuer avec Apple",
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Apple Auth pas encore activé")),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Liens
                          TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, '/login'),
                              child: const Text(
                                  "Vous avez déjà un compte ? Se connecter",
                                  style: TextStyle(
                                      decoration: TextDecoration.underline))),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/'),
                            child: const Text("Page Accueil",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔹 Section BTS
                  buildAnimatedCard(
                    controller: _btsController,
                    child: buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("À propos du BTS",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 8),
                          Text(
                            "Le BTS est un diplôme national qui permet de se former rapidement "
                            "dans un domaine professionnel précis et d'acquérir des compétences recherchées.",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 🔹 Mentions légales
                  buildAnimatedCard(
                    controller: _footerController,
                    child: buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Mentions légales",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 8),
                          Text(
                            "Politique de confidentialité : nous respectons vos données et votre vie privée.\n\n"
                            "Conditions d'utilisation : en utilisant cette application, vous acceptez nos règles.\n\n"
                            "Contact : devopsdesigngest@gmail.com",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
