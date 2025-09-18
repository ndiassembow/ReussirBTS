// lib/screens/tabs/quiz_tab.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/quiz_model.dart';
import '../../models/question_model.dart';
import '../../models/quiz_result_model.dart';

/// ================= QuizTab: liste modules + quizzes + historique
class QuizTab extends StatefulWidget {
  const QuizTab({super.key});

  @override
  State<QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<QuizTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<_ModuleSimple>> _modulesFuture;
  final User? user = FirebaseAuth.instance.currentUser;

  // AJOUT : fonction pour récupérer les tentatives d’un quiz spécifique
  Widget _buildQuizAttempts(String userId, String quizId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("users/$userId/quizHistory")
          .where("quizId", isEqualTo: quizId)
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final results = snapshot.data!.docs
            .map((doc) => QuizResult.fromFirestore(doc))
            .toList();
        if (results.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Text(
              "📜 Mes tentatives",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ...results.map((r) => Card(
                  child: ListTile(
                    title: Text("Score: ${r.score}/${r.total}"),
                    subtitle: Text(
                        "Badge: ${r.badge} | ${r.percent}% | ${r.date.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.visibility),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizReviewScreen(result: r),
                        ),
                      );
                    },
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _modulesFuture = _loadModulesAndQuizzes();
  }

  Future<List<_ModuleSimple>> _loadModulesAndQuizzes() async {
    final modulesSnap = await _firestore.collection('modules').get();
    final List<_ModuleSimple> modules = [];

    for (final mDoc in modulesSnap.docs) {
      final moduleId = mDoc.id;
      final title = (mDoc.data()['title'] ?? 'Module').toString();

      final quizzesSnap = await _firestore
          .collection('modules/$moduleId/quizzes')
          .orderBy('order', descending: false)
          .get();

      final quizzes = quizzesSnap.docs.map((qDoc) {
        final data = qDoc.data();
        try {
          return QuizModel.fromMap(Map<String, dynamic>.from(data),
              id: qDoc.id, moduleId: moduleId);
        } catch (_) {
          final questions = (data['questions'] as List<dynamic>? ?? [])
              .map((qq) => QuestionModel.fromMap(Map<String, dynamic>.from(qq)))
              .toList();
          return QuizModel(
              id: qDoc.id,
              title: (data['title'] ?? 'Quiz').toString(),
              moduleId: moduleId,
              questions: questions);
        }
      }).toList();

      modules.add(_ModuleSimple(id: moduleId, title: title, quizzes: quizzes));
    }
    return modules;
  }

  Future<int?> _getUserBestScore(String quizId) async {
    if (user == null) return null;
    final doc = await _firestore
        .collection('users/${user!.uid}/quizHistory')
        .doc(quizId)
        .get();
    if (doc.exists) return (doc.data()?['score'] as num?)?.toInt();
    return null;
  }

  Widget _buildHistory(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection("users/$userId/quizHistory")
          .orderBy("date", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final results = snapshot.data!.docs
            .map((doc) => QuizResult.fromFirestore(doc))
            .toList();
        if (results.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Text(
              "📜 Historique de mes quiz",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...results.map((r) => Card(
                  child: ListTile(
                    title: Text("${r.quizId} : ${r.score}/${r.total}"),
                    subtitle: Text(
                        "Badge: ${r.badge} | ${r.percent}% | ${r.date.toLocal().toString().split(' ')[0]}"),
                    trailing: const Icon(Icons.history),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizReviewScreen(result: r),
                        ),
                      );
                    },
                  ),
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📘 Quiz')),
      body: FutureBuilder<List<_ModuleSimple>>(
        future: _modulesFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError)
            return Center(child: Text('Erreur: ${snap.error}'));

          final modules = snap.data ?? [];
          if (modules.isEmpty) return const Center(child: Text('Aucun module'));

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Choisis un module puis un quiz. Les réponses sont verrouillées une fois choisies. Le score est calculé uniquement à la fin.',
                ),
              ),
              const SizedBox(height: 12),
              ...modules.map((m) => Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(m.title),
                      subtitle: Text('${m.quizzes.length} quiz'),
                      children: m.quizzes.map((q) {
                        return FutureBuilder<int?>(
                          future: _getUserBestScore(q.id),
                          builder: (context, s) {
                            final best =
                                s.connectionState == ConnectionState.done
                                    ? s.data
                                    : null;
                            return ExpansionTile(
                              // 🔹 CHANGEMENT : ExpansionTile au lieu de ListTile simple
                              leading:
                                  const Icon(Icons.quiz, color: Colors.blue),
                              title: Text(q.title),
                              subtitle:
                                  best != null ? Text('Meilleur: $best') : null,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.play_arrow,
                                      color: Colors.green),
                                  title: const Text("Lancer le quiz"),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            QuizPlayScreen(quiz: q)),
                                  ),
                                ),
                                if (user != null)
                                  _buildQuizAttempts(
                                      user!.uid, q.id), // 🔹 AJOUT ICI
                              ],
                            );
                          },
                        );
                      }).toList(),
                    ),
                  )),
              if (user != null) _buildHistory(user!.uid),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleSimple {
  final String id;
  final String title;
  final List<QuizModel> quizzes;
  _ModuleSimple({required this.id, required this.title, required this.quizzes});
}

/// ================= QuizPlayScreen
class QuizPlayScreen extends StatefulWidget {
  final QuizModel quiz;
  const QuizPlayScreen({super.key, required this.quiz});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int currentIndex = 0;
  late List<int> userAnswers; // -1 = pas répondu
  bool finished = false;
  bool saving = false;
  Timer? questionTimer;
  int remainingSeconds = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userAnswers = List<int>.filled(widget.quiz.questions.length, -1);
    _startTimer();
  }

  void _startTimer() {
    final q = widget.quiz.questions[currentIndex];
    remainingSeconds = q.durationSeconds ?? 0;
    questionTimer?.cancel();
    if (remainingSeconds > 0) {
      questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (remainingSeconds <= 0) {
          t.cancel();
          if (userAnswers[currentIndex] == -1) {
            setState(() => userAnswers[currentIndex] = -2); // -2 = temps écoulé
          }
        } else {
          setState(() => remainingSeconds--);
        }
      });
    }
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    super.dispose();
  }

  bool get allAnswered => !userAnswers.any((ans) => ans == -1);

  int _computeScore() {
    int s = 0;
    for (var i = 0; i < widget.quiz.questions.length; i++) {
      final q = widget.quiz.questions[i];
      final ans = userAnswers[i];
      if (ans != -1 && ans == q.correctIndex) s++;
    }
    return s;
  }

  String _computeBadge(int score, int total) {
    final thresholds = widget.quiz.badgeThresholds;
    final percent = total == 0 ? 0 : (score * 100) / total;
    if (percent >= (thresholds['Or'] ?? 90)) return 'Or 🥇';
    if (percent >= (thresholds['Argent'] ?? 70)) return 'Argent 🥈';
    if (percent >= (thresholds['Bronze'] ?? 50)) return 'Bronze 🥉';
    return 'Aucun';
  }

  Future<void> _saveResult(int score, int total, String badge) async {
    if (user == null) return;
    final result = QuizResult(
      id: widget.quiz.id,
      moduleId: widget.quiz.moduleId,
      quizId: widget.quiz.id,
      score: score,
      total: total,
      bonnes: score,
      fautes: total - score,
      duree: 0,
      percent: total == 0 ? 0 : ((score * 100) / total).round(),
      badge: badge,
      date: DateTime.now(),
      answers: userAnswers,
    );
    await _firestore
        .collection('users/${user!.uid}/quizHistory')
        .doc(widget.quiz.id)
        .set(result.toMap(), SetOptions(merge: true));
  }

  Future<void> _finishQuiz() async {
    setState(() => finished = true);
    final total = widget.quiz.questions.length;
    final score = _computeScore();
    final badge = _computeBadge(score, total);

    setState(() => saving = true);
    try {
      await _saveResult(score, total, badge);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur sauvegarde: $e')));
    } finally {
      setState(() => saving = false);
    }
  }

  void _nextQuestion() {
    if (currentIndex < widget.quiz.questions.length - 1) {
      setState(() => currentIndex++);
      _startTimer();
    }
  }

  void _prevQuestion() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _startTimer();
    }
  }

  void _replay() {
    setState(() {
      userAnswers = List<int>.filled(widget.quiz.questions.length, -1);
      currentIndex = 0;
      finished = false;
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body:
            const Center(child: Text('Ce quiz ne contient pas de questions.')),
      );
    }

    final q = widget.quiz.questions[currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: finished
            ? _buildResultSummary()
            : Column(
                children: [
                  if (q.durationSeconds != null && q.durationSeconds! > 0)
                    Text('⏱ Temps restant: $remainingSeconds s',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: _buildQuestionView()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                              onPressed:
                                  currentIndex > 0 ? _prevQuestion : null,
                              child: const Text('⬅️ Précédent'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: (currentIndex < widget.quiz.questions.length - 1)
                            ? ElevatedButton(
                                onPressed: userAnswers[currentIndex] != -1
                                    ? _nextQuestion
                                    : null,
                                child: const Text('Suivant ➡️'),
                              )
                            : ElevatedButton(
                                onPressed: allAnswered ? _finishQuiz : null,
                                child: const Text('✅ Terminer'),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildQuestionView() {
    final q = widget.quiz.questions[currentIndex];
    final answer = userAnswers[currentIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${currentIndex + 1} / ${widget.quiz.questions.length}',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: (currentIndex + 1) / widget.quiz.questions.length),
          const SizedBox(height: 16),
          Text(q.question, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          ...List.generate(q.options.length, (i) {
            final isSelected = answer == i;
            final disabled = answer != -1;
            Color? color;
            if (disabled) {
              if (i == q.correctIndex)
                color = Colors.green.shade200;
              else if (isSelected)
                color = Colors.red.shade200;
              else
                color = Colors.grey.shade100;
            } else if (isSelected) {
              color = Colors.blue.shade100;
            }

            return Card(
              color: color,
              child: ListTile(
                title: Text(q.options[i]),
                subtitle:
                    (disabled && i == q.correctIndex && q.explanation != null)
                        ? Text("💡 ${q.explanation}",
                            style: const TextStyle(fontSize: 12))
                        : null,
                onTap: disabled
                    ? null
                    : () {
                        setState(() => userAnswers[currentIndex] = i);
                        if (q.durationSeconds != null) questionTimer?.cancel();
                      },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultSummary() {
    final total = widget.quiz.questions.length;
    final score = _computeScore();
    final badge = _computeBadge(score, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Résultat', style: Theme.of(context).textTheme.titleLarge),
                Text('Score : $score / $total'),
                Text('Badge : $badge'),
              ],
            ),
          ),
        ),
        ElevatedButton(onPressed: _replay, child: const Text('Rejouer')),
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer')),
      ],
    );
  }
}

/// ================= Relecture d’un quiz sauvegardé
class QuizReviewScreen extends StatelessWidget {
  final QuizResult result;
  const QuizReviewScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Relecture ${result.quizId}")),
      body: ListView.builder(
        itemCount: result.answers.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text("Question ${i + 1}"),
            subtitle: Text("Réponse donnée: ${result.answers[i]}"),
          );
        },
      ),
    );
  }
}
