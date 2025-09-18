// lib/screens/admin/student_crud_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Écran de gestion des étudiants (CRUD complet)
class StudentCrud extends StatelessWidget {
  const StudentCrud({super.key});

  /// 🔹 Boîte de dialogue pour ajouter ou modifier un étudiant
  Future<void> _openStudentDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? data,
  }) async {
    // Champs texte contrôlés
    final nameController =
        TextEditingController(text: data != null ? data['name'] : '');
    final emailController =
        TextEditingController(text: data != null ? data['email'] : '');
    final phoneController =
        TextEditingController(text: data != null ? data['phone'] : '');
    final schoolController =
        TextEditingController(text: data != null ? data['school'] : '');
    final specialityController =
        TextEditingController(text: data != null ? data['speciality'] : '');
    final passwordController =
        TextEditingController(text: data != null ? data['password'] : '');

    // Valeurs par défaut
    String role = data != null ? data['role'] ?? 'etudiant' : 'etudiant';
    String niveau = data != null ? data['niveau'] ?? 'BTS1' : 'BTS1';

    // ✅ Boîte de dialogue modale
    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                docId == null
                    ? "➕ Ajouter un étudiant"
                    : "✏️ Modifier étudiant",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Champs texte
                    _buildTextField("Nom complet", nameController),
                    _buildTextField("Email", emailController,
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField("Téléphone", phoneController,
                        keyboardType: TextInputType.phone),
                    _buildTextField("École", schoolController),
                    _buildTextField("Spécialité", specialityController),

                    // Le mot de passe est uniquement demandé à la création
                    if (docId == null)
                      _buildTextField("Mot de passe", passwordController,
                          isPassword: true),

                    const SizedBox(height: 12),

                    // Dropdowns rôle et niveau
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: role,
                            decoration: const InputDecoration(
                              labelText: "Rôle",
                              border: OutlineInputBorder(),
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
              actions: [
                // Bouton annuler
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),

                // Bouton sauvegarder
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(docId == null ? "Ajouter" : "Modifier"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final collection =
                        FirebaseFirestore.instance.collection("users");

                    if (docId == null) {
                      // 🔹 Création nouvel étudiant
                      try {
                        final cred = await FirebaseAuth.instance
                            .createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim(),
                        );

                        final uid = cred.user!.uid;

                        final dataToSave = {
                          "uid": uid,
                          "name": nameController.text.trim(),
                          "email": emailController.text.trim(),
                          "phone": phoneController.text.trim(),
                          "school": schoolController.text.trim(),
                          "speciality": specialityController.text.trim(),
                          "password": passwordController.text
                              .trim(), // ⚠️ stocké en clair (à éviter en prod)
                          "role": role,
                          "niveau": niveau,
                          "createdAt": FieldValue.serverTimestamp(),
                        };

                        await collection.doc(uid).set(dataToSave);
                      } on FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur: ${e.message}")),
                        );
                      }
                    } else {
                      // 🔹 Mise à jour étudiant existant
                      final dataToUpdate = {
                        "name": nameController.text.trim(),
                        "email": emailController.text.trim(),
                        "phone": phoneController.text.trim(),
                        "school": schoolController.text.trim(),
                        "speciality": specialityController.text.trim(),
                        "role": role,
                        "niveau": niveau,
                      };

                      await collection.doc(docId).update(dataToUpdate);
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 🔹 Widget réutilisable pour champ texte
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isPassword = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  /// 🔹 Suppression étudiant (par ID)
  Future<void> _deleteStudent(String docId) async {
    await FirebaseFirestore.instance.collection("users").doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👨‍🎓 Gestion Étudiants"),
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 Flux en temps réel depuis Firestore
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
            return const Center(
              child: Text("Aucun étudiant disponible",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            );
          }

          // ✅ Liste des étudiants
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    data['name'] ?? "Sans nom",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "${data['email']} • ${data['niveau']} • ${data['role']}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton modifier
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openStudentDialog(
                          context,
                          docId: doc.id,
                          data: data,
                        ),
                      ),
                      // Bouton supprimer
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
      // Bouton flottant pour ajouter un étudiant
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Ajouter étudiant"),
        backgroundColor: Colors.indigo,
        onPressed: () => _openStudentDialog(context),
      ),
    );
  }
}
