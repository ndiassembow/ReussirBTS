// lib/screens/admin/quiz_crud_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Écran d'administration pour gérer les quizzes par module.
/// - Charge dynamiquement les modules depuis Firestore
/// - Affiche la liste des quizzes pour le module sélectionné (stream)
/// - Dialogues d'ajout / édition avec meilleur layout (évite chevauchements)
class QuizCrud extends StatefulWidget {
  const QuizCrud({super.key});

  @override
  State<QuizCrud> createState() => _QuizCrudState();
}

class _QuizCrudState extends State<QuizCrud> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Modules chargés depuis Firestore : chaque élément contient {id, title}
  List<Map<String, String>> _modules = [];
  String? _selectedModuleId;

  bool _loadingModules = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _loadingModules = true);
    try {
      final snap = await _db.collection('modules').orderBy('title').get();
      final mods = snap.docs
          .map((d) =>
              {'id': d.id, 'title': (d.data()['title'] ?? d.id).toString()})
          .toList();
      setState(() {
        _modules = mods;
        if (_modules.isNotEmpty) _selectedModuleId = _modules.first['id'];
      });
    } catch (e) {
      // Affiche un message simple : pas de crash
      debugPrint('Erreur chargement modules: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement modules: $e')),
      );
    } finally {
      setState(() => _loadingModules = false);
    }
  }

  // ---------------- Dialogues ----------------

  /// Ouvre le dialogue d'ajout / modification d'un quiz.
  /// Si [quizDoc] != null => édition
  void _openQuizDialog({DocumentSnapshot<Map<String, dynamic>>? quizDoc}) {
    // Pré-remplissage (si édition)
    final initial = quizDoc?.data() ?? {};

    // Contrôleurs créés ici (scope du dialogue)
    final titleCtrl = TextEditingController(text: initial['title'] ?? '');
    final descCtrl = TextEditingController(text: initial['description'] ?? '');
    final durationCtrl =
        TextEditingController(text: (initial['duration'] ?? '').toString());
    final orderCtrl =
        TextEditingController(text: (initial['order'] ?? '').toString());

    bool allowMultipleAttempts = initial['allowMultipleAttempts'] ?? false;
    int badgeGold = initial['badgeGold'] ?? 90;
    int badgeSilver = initial['badgeSilver'] ?? 70;
    int badgeBronze = initial['badgeBronze'] ?? 50;

    // Questions : copie locale (liste de maps)
    List<Map<String, dynamic>> questions =
        (initial['questions'] as List<dynamic>? ?? []).map((q) {
      return Map<String, dynamic>.from(q as Map);
    }).toList();

    // Si aucune question : créer une question vide par défaut (facultatif)
    // if (questions.isEmpty) _addEmptyQuestion(questions);

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(
                quizDoc == null ? '➕ Ajouter un quiz' : '✏️ Modifier le quiz'),
            content: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Durée & ordre côte à côte
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Durée (s)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: orderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ordre',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Switch tentatives multiples
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Autoriser plusieurs tentatives'),
                      value: allowMultipleAttempts,
                      onChanged: (v) =>
                          setStateDialog(() => allowMultipleAttempts = v),
                    ),
                    const SizedBox(height: 8),

                    // Seuils badges (champs séparés, avec espacement)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Seuil Or (%)',
                                border: OutlineInputBorder()),
                            controller: TextEditingController(
                                text: badgeGold.toString()),
                            onChanged: (v) =>
                                badgeGold = int.tryParse(v) ?? badgeGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Seuil Argent (%)',
                                border: OutlineInputBorder()),
                            controller: TextEditingController(
                                text: badgeSilver.toString()),
                            onChanged: (v) =>
                                badgeSilver = int.tryParse(v) ?? badgeSilver,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Seuil Bronze (%)',
                                border: OutlineInputBorder()),
                            controller: TextEditingController(
                                text: badgeBronze.toString()),
                            onChanged: (v) =>
                                badgeBronze = int.tryParse(v) ?? badgeBronze,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Liste des questions (compacte)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('📌 Questions',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),

                    if (questions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Aucune question pour le moment'),
                      ),

                    ...questions.asMap().entries.map((entry) {
                      final qIdx = entry.key;
                      final q = entry.value;
                      final qTitle = (q['question'] ?? '').toString();
                      final correct = q['correctAnswer'] ?? '';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                              qTitle.isEmpty ? 'Question ${qIdx + 1}' : qTitle),
                          subtitle:
                              Text('Bonne réponse: ${correct.toString()}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _openQuestionDialog(
                                    questions,
                                    setStateDialog,
                                    existingQuestion: q,
                                    index: qIdx,
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setStateDialog(
                                      () => questions.removeAt(qIdx));
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            _openQuestionDialog(questions, setStateDialog),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une question'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () async {
                  // validation minimum
                  if (_selectedModuleId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Sélectionne d\'abord un module')));
                    return;
                  }
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Le titre ne peut pas être vide')));
                    return;
                  }

                  final data = {
                    'title': titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'duration': int.tryParse(durationCtrl.text) ?? 0,
                    'order': int.tryParse(orderCtrl.text) ?? 0,
                    'allowMultipleAttempts': allowMultipleAttempts,
                    'badgeGold': badgeGold,
                    'badgeSilver': badgeSilver,
                    'badgeBronze': badgeBronze,
                    'questions': questions,
                    'updatedAt': FieldValue.serverTimestamp(),
                    if (quizDoc == null)
                      'createdAt': FieldValue.serverTimestamp(),
                  };

                  final ref = _db
                      .collection('modules')
                      .doc(_selectedModuleId)
                      .collection('quizzes');

                  try {
                    if (quizDoc == null) {
                      await ref.add(data);
                    } else {
                      await ref.doc(quizDoc.id).update(data);
                    }
                    Navigator.pop(context);
                    // message de confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(quizDoc == null
                              ? 'Quiz ajouté'
                              : 'Quiz modifié')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur sauvegarde: $e')),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Dialogue d'édition/ajout d'une question.
  /// [questions] est la liste partagée; [setStateDialog] permet de rafraîchir le parent.
  void _openQuestionDialog(
    List<Map<String, dynamic>> questions,
    void Function(void Function()) setStateDialog, {
    Map<String, dynamic>? existingQuestion,
    int? index,
  }) {
    final questionCtrl =
        TextEditingController(text: existingQuestion?['question'] ?? '');
    final explanationCtrl =
        TextEditingController(text: existingQuestion?['explanation'] ?? '');

    // options : on crée des TextEditingController séparés pour afficher correctement les valeurs
    final List<TextEditingController> optionCtrls = List.generate(4, (i) {
      final opt = (existingQuestion?['options'] as List<dynamic>?)
                  ?.asMap()
                  .containsKey(i) ==
              true
          ? existingQuestion!['options'][i].toString()
          : '';
      return TextEditingController(text: opt);
    });

    String correctAnswer = existingQuestion?['correctAnswer'] ?? '';

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(existingQuestion == null
              ? '➕ Ajouter question'
              : '✏️ Modifier question'),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Question', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: optionCtrls[i],
                        decoration: InputDecoration(
                          labelText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {},
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: correctAnswer.isEmpty ? null : correctAnswer,
                    decoration: const InputDecoration(
                        labelText: 'Bonne réponse',
                        border: OutlineInputBorder()),
                    items: optionCtrls
                        .map((c) => c.text)
                        .where((t) => t.trim().isNotEmpty)
                        .map((opt) =>
                            DropdownMenuItem(value: opt, child: Text(opt)))
                        .toList(),
                    onChanged: (val) => correctAnswer = val ?? '',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: explanationCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Explication', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final opts = optionCtrls.map((c) => c.text.trim()).toList();
                final qData = {
                  'question': questionCtrl.text.trim(),
                  'options': opts,
                  'correctAnswer': correctAnswer.isEmpty && opts.isNotEmpty
                      ? opts[0]
                      : correctAnswer,
                  'explanation': explanationCtrl.text.trim(),
                };

                setStateDialog(() {
                  if (index != null) {
                    questions[index] = qData;
                  } else {
                    questions.add(qData);
                  }
                });

                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    ).then((_) {
      // Dispose controllers après fermeture du dialog
      for (final c in optionCtrls) {
        c.dispose();
      }
      questionCtrl.dispose();
      explanationCtrl.dispose();
    });
  }

  // Supprimer un quiz (avec confirmation)
  Future<void> _deleteQuiz(DocumentSnapshot doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer "${doc['title'] ?? 'quiz'}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true && _selectedModuleId != null) {
      try {
        await _db
            .collection('modules')
            .doc(_selectedModuleId)
            .collection('quizzes')
            .doc(doc.id)
            .delete();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Quiz supprimé')));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
      }
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Quiz'),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir modules',
            onPressed: _loadModules,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de module
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _loadingModules
                ? const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()))
                : DropdownButtonFormField<String>(
                    value: _selectedModuleId,
                    decoration: const InputDecoration(
                        labelText: 'Module', border: OutlineInputBorder()),
                    isExpanded: true,
                    items: _modules
                        .map((m) => DropdownMenuItem(
                            value: m['id'],
                            child: Text(m['title'] ?? m['id'] ?? '')))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _selectedModuleId = val);
                    },
                  ),
          ),

          // Liste des quizzes (stream pour être réactif aux changements)
          Expanded(
            child: _selectedModuleId == null
                ? const Center(
                    child: Text('Sélectionne un module pour afficher ses quiz'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _db
                        .collection('modules')
                        .doc(_selectedModuleId)
                        .collection('quizzes')
                        .orderBy('order')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Erreur: ${snapshot.error}'));
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                            child: Text('Aucun quiz disponible'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 8),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final doc = docs[i];
                          final data = doc.data();
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              leading: const Icon(Icons.quiz,
                                  color: Colors.deepPurple),
                              title: Text(data['title'] ?? 'Sans titre'),
                              subtitle: Text(
                                  '${(data['description'] ?? '')}\nQuestions: ${((data['questions'] ?? []) as List).length}'),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        _openQuizDialog(quizDoc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteQuiz(doc),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedModuleId == null ? null : () => _openQuizDialog(),
        label: const Text('Ajouter quiz'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
