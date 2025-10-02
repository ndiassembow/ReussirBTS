// 📁 lib/screens/admin/student_crud_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Écran d'administration pour gérer les étudiants
class StudentCrud extends StatelessWidget {
  const StudentCrud({super.key});

  /// 🔹 Ouvre une boîte de dialogue (ajout / édition étudiant)
  Future<void> _openStudentDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    // --- Contrôleurs texte
    final nameCtrl = TextEditingController(text: data?['name'] ?? '');
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: data?['phone'] ?? '');
    final schoolCtrl = TextEditingController(text: data?['school'] ?? '');
    final specialityCtrl =
        TextEditingController(text: data?['speciality'] ?? '');
    final passwordCtrl = TextEditingController(); // ⚠️ seulement si création

    // --- Valeurs par défaut
    String role = data?['role'] ?? 'etudiant';
    String niveau = data?['niveau'] ?? 'BTS1';

    // --- Afficher le dialogue
    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              title: Text(
                docId == null ? "➕ Ajouter étudiant" : "✏️ Modifier étudiant",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField("Nom complet", nameCtrl),
                    _buildTextField("Email", emailCtrl,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField("Téléphone", phoneCtrl,
                        keyboardType: TextInputType.phone),
                    _buildTextField("École", schoolCtrl),
                    _buildTextField("Spécialité", specialityCtrl),

                    // Le mot de passe uniquement si création
                    if (docId == null)
                      _buildTextField("Mot de passe", passwordCtrl,
                          isPassword: true),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: role,
                            decoration: const InputDecoration(
                              labelText: "Rôle",
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: "etudiant", child: Text("Étudiant")),
                              DropdownMenuItem(
                                  value: "admin", child: Text("Admin")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => role = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: niveau,
                            decoration: const InputDecoration(
                              labelText: "Niveau",
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 10),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: "BTS1", child: Text("BTS 1")),
                              DropdownMenuItem(
                                  value: "BTS2", child: Text("BTS 2")),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => niveau = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(docId == null ? "Ajouter" : "Modifier"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () async {
                    final usersCol =
                        FirebaseFirestore.instance.collection("users");

                    if (docId == null) {
                      // 🔹 Création étudiant
                      try {
                        final cred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text.trim(),
                        );

                        final uid = cred.user!.uid;
                        final dataToSave = {
                          "uid": uid,
                          "name": nameCtrl.text.trim(),
                          "email": emailCtrl.text.trim(),
                          "phone": phoneCtrl.text.trim(),
                          "school": schoolCtrl.text.trim(),
                          "speciality": specialityCtrl.text.trim(),
                          "role": role,
                          "niveau": niveau,
                          "createdAt": FieldValue.serverTimestamp(),
                        };

                        await usersCol.doc(uid).set(dataToSave);

                        // Optionnel : envoi email de vérification
                        try {
                          await cred.user!.sendEmailVerification();
                        } catch (_) {}
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur: ${e.message}")),
                        );
                      }
                    } else {
                      // 🔹 Mise à jour
                      final dataToUpdate = {
                        "name": nameCtrl.text.trim(),
                        "email": emailCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim(),
                        "school": schoolCtrl.text.trim(),
                        "speciality": specialityCtrl.text.trim(),
                        "role": role,
                        "niveau": niveau,
                      };
                      await usersCol.doc(docId).update(dataToUpdate);
                    }

                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Champ texte réutilisable
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  /// 🔹 Suppression étudiant
  Future<void> _deleteStudent(String docId) async {
    await FirebaseFirestore.instance.collection("users").doc(docId).delete();
    // ⚠️ Optionnel : supprimer aussi le compte Firebase Auth via Cloud Functions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍🎓 Gestion Étudiants"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Aucun étudiant disponible"));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
                left: 12, right: 12, top: 12, bottom: 80), // ⚠️ marge en bas
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(data['name'] ?? "Sans nom"),
                  subtitle: Text(
                    "${data['email']} • ${data['niveau']} • ${data['role']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openStudentDialog(
                          context,
                          docId: doc.id,
                          data: data,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteStudent(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 12), // 🔹 espace FAB
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text("Ajouter étudiant"),
          backgroundColor: Colors.indigo,
          onPressed: () => _openStudentDialog(context),
        ),
      ),
    );
  }
}
