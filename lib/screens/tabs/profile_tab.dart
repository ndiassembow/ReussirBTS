// 📁 lib/screens/tabs/profile_tab.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../provider/user_provider.dart';
import '../../provider/theme_provider.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;
  AppUser? _user;
  String? _error;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<String?> _tryReadPhotoUrl(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return (doc.data() ?? const {})['photoUrl'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadUser() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        _user = userProvider.user;
        _photoUrl = (_user?.photoUrl?.isNotEmpty ?? false)
            ? _user!.photoUrl
            : await _tryReadPhotoUrl(_user!.uid);
        setState(() => _isLoading = false);
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = "Utilisateur non connecté.";
          _isLoading = false;
        });
        return;
      }

      final fetchedUser = await FirestoreService().getUser(uid);
      if (fetchedUser != null) {
        userProvider.setUser(fetchedUser);
        _user = fetchedUser;
        _photoUrl = (fetchedUser.photoUrl?.isNotEmpty ?? false)
            ? fetchedUser.photoUrl
            : await _tryReadPhotoUrl(uid);
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _error = "Utilisateur introuvable.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Erreur de chargement : $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) return;

      // Taille max 5 Mo
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image trop lourde (max 5 Mo).")));
        return;
      }

// ===== Supprimer avatar =====
      Future<void> _removeAvatar() async {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Supprimer la photo ?"),
            content: const Text("Cette action retirera ta photo de profil."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Annuler")),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Supprimer"),
              ),
            ],
          ),
        );

        if (confirm != true) return;

        try {
          // Supprimer tous les formats possibles
          for (final ext in ['jpg', 'jpeg', 'png']) {
            await FirebaseStorage.instance
                .ref('avatars/$uid.$ext')
                .delete()
                .catchError((_) {});
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'photoUrl': FieldValue.delete()});

          final updated = _user!.copyWith(photoUrl: '');
          context.read<UserProvider>().setUser(updated);
          setState(() {
            _user = updated;
            _photoUrl = null;
          });

          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Photo supprimée.")));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur suppression photo : $e")));
        }
      }

      // Extension
      final ext = (file.extension ?? '').toLowerCase();
      final allowed = ['png', 'jpg', 'jpeg'];
      if (!allowed.contains(ext)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Format non supporté (png/jpg/jpeg)")));
        return;
      }

      final ref = FirebaseStorage.instance.ref().child('avatars/$uid.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': url, 'photoUpdatedAt': DateTime.now()});

      final updated = _user!.copyWith(photoUrl: url);
      context.read<UserProvider>().setUser(updated);
      setState(() {
        _user = updated;
        _photoUrl = url;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Photo mise à jour ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur upload : $e")));
    }
  }

  Future<void> _removeAvatar() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer la photo ?"),
        content: const Text("Cette action retirera ta photo de profil."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseStorage.instance
          .ref('avatars/$uid.jpg')
          .delete()
          .catchError((_) {});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': FieldValue.delete()});

      final updated = _user!.copyWith(photoUrl: '');
      context.read<UserProvider>().setUser(updated);
      setState(() {
        _user = updated;
        _photoUrl = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Photo supprimée.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur suppression photo : $e")));
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Supprimer ton compte définitivement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService().deleteAccount();
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur suppression : $e")));
      }
    }
  }

  void _openEditDialog() {
    if (_user == null) return;
    showDialog(
      context: context,
      builder: (_) => EditProfileDialog(user: _user!),
    ).then((_) async {
      final u = context.read<UserProvider>().user;
      if (mounted && u != null) {
        setState(() {
          _user = u;
          _photoUrl =
              (u.photoUrl?.isNotEmpty ?? false) ? u.photoUrl : _photoUrl;
        });
      }
    });
  }

  void _openPasswordDialog() {
    showDialog(context: context, builder: (_) => const ChangePasswordDialog());
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    if (_user == null)
      return const Center(child: Text("Aucune donnée utilisateur."));

    final colors = isDark
        ? [const Color(0xFF0F172A), const Color(0xFF111827)]
        : [const Color(0xFF2563EB), const Color(0xFF10B981)];

    final bgColor = isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        backgroundImage: (_photoUrl?.isNotEmpty ?? false)
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: (_photoUrl?.isEmpty ?? true)
                            ? Icon(Icons.person,
                                size: 56,
                                color: isDark
                                    ? Colors.grey[700]
                                    : Colors.grey[400])
                            : null,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoundIconButton(
                              icon: Icons.edit,
                              tooltip: "Changer la photo",
                              onTap: _pickAndUploadPhoto),
                          const SizedBox(width: 8),
                          if (_photoUrl?.isNotEmpty ?? false)
                            _RoundIconButton(
                                icon: Icons.delete,
                                tooltip: "Supprimer la photo",
                                onTap: _removeAvatar),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_user!.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_user!.email, style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => themeProvider.toggleTheme(),
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(isDark ? "Mode sombre" : "Mode clair",
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ===== BODY =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  _InfoCard(
                      title: "Téléphone",
                      value: _user?.phone ?? '',
                      icon: Icons.phone_iphone,
                      dark: isDark,
                      onTap: _openEditDialog),
                  _InfoCard(
                      title: "Établissement",
                      value: _user?.school ?? '',
                      icon: Icons.school_outlined,
                      dark: isDark,
                      onTap: _openEditDialog),
                  _InfoCard(
                      title: "Spécialité",
                      value: _user?.speciality ?? '',
                      icon: Icons.badge_outlined,
                      dark: isDark,
                      onTap: _openEditDialog),
                  _InfoCard(
                      title: "Niveau",
                      value: _user?.niveau ?? '',
                      icon: Icons.grade,
                      dark: isDark,
                      onTap: _openEditDialog),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _openEditDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text("Modifier mon profil"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openPasswordDialog,
                    icon: const Icon(Icons.lock_reset),
                    label: const Text("Changer le mot de passe"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete),
                    label: const Text("Supprimer mon compte"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted)
                        Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Déconnexion"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Widgets =====

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _RoundIconButton(
      {required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          width: 40,
          height: 40,
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _InfoCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.dark,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF0B1220) : Colors.white;
    final fg = dark ? Colors.white : Colors.black87;

    return Card(
      color: bg,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: dark ? Colors.white10 : Colors.blue.withOpacity(.1),
          child: Icon(icon, color: fg),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
        subtitle: Text((value.isEmpty ? "Non renseigné" : value),
            style: TextStyle(color: fg.withOpacity(.8))),
        trailing: Icon(Icons.chevron_right, color: fg),
      ),
    );
  }
}

// ===== ChangePasswordDialog =====

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;

  Future<void> changePassword() async {
    final oldPwd = oldCtrl.text.trim();
    final newPwd = newCtrl.text.trim();
    final confirmPwd = confirmCtrl.text.trim();

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Les mots de passe ne correspondent pas")));
      return;
    }
    if (newPwd.isEmpty || oldPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez remplir tous les champs")));
      return;
    }

    try {
      setState(() => loading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "Utilisateur non connecté";
      final email = user.email;
      if (email == null) throw "Email introuvable";

      final cred = EmailAuthProvider.credential(email: email, password: oldPwd);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPwd);

      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mot de passe mis à jour ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur : $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Changer mon mot de passe"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: oldCtrl,
            decoration: const InputDecoration(labelText: "Ancien mot de passe"),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: newCtrl,
            decoration:
                const InputDecoration(labelText: "Nouveau mot de passe"),
            obscureText: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: confirmCtrl,
            decoration: const InputDecoration(
                labelText: "Confirmer le nouveau mot de passe"),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler")),
        ElevatedButton(
          onPressed: loading ? null : changePassword,
          child: Text(loading ? "..." : "Changer"),
        ),
      ],
    );
  }
}

// ===== EditProfileDialog =====

class EditProfileDialog extends StatefulWidget {
  final AppUser user;
  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController schoolCtrl;
  late final TextEditingController specialityCtrl;
  late final TextEditingController niveauCtrl;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user.name);
    phoneCtrl = TextEditingController(text: widget.user.phone);
    schoolCtrl = TextEditingController(text: widget.user.school);
    specialityCtrl = TextEditingController(text: widget.user.speciality);
    niveauCtrl = TextEditingController(text: widget.user.niveau);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    schoolCtrl.dispose();
    specialityCtrl.dispose();
    niveauCtrl.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    final newName = nameCtrl.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le nom ne peut pas être vide")));
      return;
    }

    setState(() => loading = true);
    final updatedUser = widget.user.copyWith(
      name: newName,
      phone: phoneCtrl.text.trim(),
      school: schoolCtrl.text.trim(),
      speciality: specialityCtrl.text.trim(),
      niveau: niveauCtrl.text.trim(),
    );

    try {
      await FirestoreService().updateUser(updatedUser);
      if (!mounted) return;

      context.read<UserProvider>().setUser(updatedUser);
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Profil mis à jour ✅")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur sauvegarde : $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifier mon profil"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field("Nom", nameCtrl),
            _field("Téléphone", phoneCtrl, keyboard: TextInputType.phone),
            _field("Établissement", schoolCtrl),
            _field("Spécialité", specialityCtrl),
            _field("Niveau", niveauCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler")),
        ElevatedButton(
          onPressed: loading ? null : saveChanges,
          child: Text(loading ? "Enregistrement..." : "Enregistrer"),
        ),
      ],
    );
  }
}
