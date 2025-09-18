// lib/screens/tabs/progress_tab.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../models/course_model.dart';
import '../../models/quiz_result_model.dart';
import '../../models/fiche_model.dart';
import '../../models/video_model.dart';
import '../../services/firestore_service.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final FirestoreService _fs = FirestoreService();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _loading = true;
  bool _online = true;

  List<Course> _modules = [];
  final Map<String, List<QuizResult>> _quizResultsByModule = {};
  final Map<String, List<Fiche>> _fichesByModule = {};
  final Map<String, List<VideoItem>> _videosByModule = {};

  StreamSubscription<ConnectivityResult>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((status) {
      setState(() => _online = status != ConnectivityResult.none);
    });
    _loadAll();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool force = false}) async {
    setState(() => _loading = true);
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _modules = [];
        _quizResultsByModule.clear();
        _fichesByModule.clear();
        _videosByModule.clear();
        _loading = false;
      });
      return;
    }

    try {
      final modules = await _fs.getModules(forceRefresh: force);
      _modules = modules;

      _quizResultsByModule.clear();
      _fichesByModule.clear();
      _videosByModule.clear();

      for (final m in modules) {
        // 🔹 Prendre la bonne collection : quizHistory
        try {
          final snap = await _db
              .collection("users/${user.uid}/quizHistory")
              .where("moduleId", isEqualTo: m.id)
              .get();

          final results =
              snap.docs.map((d) => QuizResult.fromFirestore(d)).toList();
          results.sort((a, b) => b.date.compareTo(a.date));
          _quizResultsByModule[m.id] = results;
        } catch (_) {
          _quizResultsByModule[m.id] = [];
        }

        try {
          _fichesByModule[m.id] = await _fs.getFichesForModule(m.id);
        } catch (_) {
          _fichesByModule[m.id] = [];
        }

        try {
          _videosByModule[m.id] = await _fs.getVideosForModule(m.id);
        } catch (_) {
          _videosByModule[m.id] = [];
        }
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _computeStats(String moduleId) {
    final quizzes = _quizResultsByModule[moduleId] ?? [];
    final fiches = _fichesByModule[moduleId] ?? [];
    final videos = _videosByModule[moduleId] ?? [];

    // Scores en %
    final quizScores = quizzes
        .map((r) => r.total > 0 ? (r.score / r.total * 100) : 0)
        .toList();
    final bestScore =
        quizScores.isNotEmpty ? quizScores.reduce((a, b) => a > b ? a : b) : 0;
    final avgScore = quizScores.isNotEmpty
        ? quizScores.reduce((a, b) => a + b) / quizScores.length
        : 0.0;

    double fichesProgress = fiches.isEmpty
        ? 0
        : fiches.where((f) => f.viewed == true).length / fiches.length;
    double videosProgress = videos.isEmpty
        ? 0
        : videos.where((v) => v.watched == true).length / videos.length;
    double quizzesProgress = quizzes.isEmpty
        ? 0
        : quizzes.where((r) => r.total > 0).length / quizzes.length;

    return {
      'best': bestScore,
      'avg': avgScore,
      'quizCount': quizzes.length,
      'scores': quizScores,
      'fichesProgress': fichesProgress,
      'videosProgress': videosProgress,
      'quizzesProgress': quizzesProgress,
    };
  }

  String? _badgeForScore(int best) {
    if (best >= 90) return 'Expert';
    if (best >= 80) return 'Très bon';
    if (best >= 60) return 'Compétent';
    return null;
  }

  Future<void> _exportCsv(Course module) async {
    final results = _quizResultsByModule[module.id] ?? [];
    if (results.isEmpty) return;

    final sb = StringBuffer();
    sb.writeln('moduleId,moduleTitle,quizId,date,score,total,badge');
    for (final r in results) {
      sb.writeln(
        '${r.moduleId},"${module.title}",${r.quizId},${r.date.toIso8601String()},${r.score},${r.total},${r.badge}',
      );
    }

    final csv = sb.toString();
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: csv));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copié dans le presse-papier.')),
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${module.id}_progress.csv');
      await file.writeAsString(csv, flush: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exporté dans : ${file.path}')),
      );
    }
  }

  Widget _buildModuleCard(Course m) {
    final stats = _computeStats(m.id);
    final badge = _badgeForScore(stats['best']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(m.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                if (badge != null)
                  Chip(
                    label: Text(badge),
                    backgroundColor: badge == 'Expert'
                        ? Colors.green.shade200
                        : badge == 'Très bon'
                            ? Colors.blue.shade200
                            : Colors.orange.shade200,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleStat(
                  percent: stats['quizzesProgress'],
                  label: "Quiz",
                  value: "${stats['quizCount']}",
                  color: Colors.blue,
                ),
                _buildCircleStat(
                  percent: stats['fichesProgress'],
                  label: "Fiches",
                  value: "${_fichesByModule[m.id]?.length ?? 0}",
                  color: Colors.green,
                ),
                _buildCircleStat(
                  percent: stats['videosProgress'],
                  label: "Vidéos",
                  value: "${_videosByModule[m.id]?.length ?? 0}",
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text("Moyenne Quiz: ${stats['avg'].toStringAsFixed(1)}%",
                style: const TextStyle(fontSize: 14)),
            LinearProgressIndicator(
              value: (stats['avg'] ?? 0) / 100,
              minHeight: 8,
              color: Colors.purple,
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModuleProgressPage(
                      module: m,
                      quizResults: _quizResultsByModule[m.id] ?? [],
                      fiches: _fichesByModule[m.id] ?? [],
                      videos: _videosByModule[m.id] ?? [],
                      onExportCsv: () => _exportCsv(m),
                    ),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Détails'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleStat({
    required double percent,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 45,
          lineWidth: 6,
          percent: percent.clamp(0.0, 1.0),
          center:
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          progressColor: color,
          backgroundColor: Colors.grey.shade200,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma progression'),
        actions: [
          IconButton(
              onPressed: () => _loadAll(force: true),
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _modules.isEmpty
              ? const Center(child: Text('Aucun module disponible.'))
              : RefreshIndicator(
                  onRefresh: () => _loadAll(force: true),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (!_online)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    color: Colors.orange,
                                    child: const Text(
                                        '⚠️ Hors ligne — données partielles'),
                                  ),
                                const SizedBox(height: 12),
                                ..._modules
                                    .map((m) => _buildModuleCard(m))
                                    .toList(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class ModuleProgressPage extends StatelessWidget {
  final Course module;
  final List<QuizResult> quizResults;
  final List<Fiche> fiches;
  final List<VideoItem> videos;
  final VoidCallback onExportCsv;

  const ModuleProgressPage({
    super.key,
    required this.module,
    required this.quizResults,
    required this.fiches,
    required this.videos,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique — ${module.title}'),
        actions: [
          IconButton(onPressed: onExportCsv, icon: const Icon(Icons.download))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (quizResults.isNotEmpty)
            _buildSection(
                '📊 Quizzes',
                quizResults.map((r) {
                  final percent = r.total > 0 ? (r.score / r.total * 100) : 0;
                  return ListTile(
                    leading: Icon(
                      percent >= 50
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: percent >= 50 ? Colors.green : Colors.grey,
                    ),
                    title: Text('${r.quizId} • ${percent.toStringAsFixed(1)}%'),
                    subtitle:
                        Text('${r.date.toLocal()} • ${r.score}/${r.total}'),
                  );
                }).toList()),
          if (fiches.isNotEmpty)
            _buildSection(
                '📘 Fiches consultées',
                fiches.map((f) {
                  return ListTile(
                    leading: Icon(
                      f.viewed == true
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: f.viewed == true ? Colors.green : Colors.grey,
                    ),
                    title: Text(f.title),
                  );
                }).toList()),
          if (videos.isNotEmpty)
            _buildSection(
                '🎥 Vidéos regardées',
                videos.map((v) {
                  return ListTile(
                    leading: Icon(
                      v.watched == true
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: v.watched == true ? Colors.green : Colors.grey,
                    ),
                    title: Text(v.title),
                  );
                }).toList()),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}
