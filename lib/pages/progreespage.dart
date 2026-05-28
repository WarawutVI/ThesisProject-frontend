import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/pages/progressELM/avg_accuracy_donuts.dart';
import 'package:frontend/pages/progressELM/practice_count_chart.dart';
import 'package:frontend/pages/progressELM/recent_sessions_list.dart';
import 'package:frontend/pages/progressELM/summary_card.dart';
import 'package:frontend/pages/progressELM/trend_card.dart';
import 'package:frontend/pages/progressELM/weak_vowels_list.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

/// Progress analytics dashboard.
///
/// This file is intentionally thin — it only:
///   1. Loads the data needed by child widgets.
///   2. Lays out those widgets in a scrollable column.
///
/// Each section lives in its own file under lib/pages/progressELM/.
class Progreespage extends StatefulWidget {
  const Progreespage({super.key});

  @override
  State<Progreespage> createState() => _ProgreespageState();
}

class _ProgreespageState extends State<Progreespage> {
  // ── Page-level state ─────────────────────────────────────────────────────────

  bool isEnglish = true;
  bool loading = true;
  String? error;

  ProgressSummary? _summary;
  UserStreak? _streak;
  List<VowelStats> _shortStats = [];
  List<VowelStats> _longStats = [];
  List<SessionRecord> _recentSessions = [];

  String _barType = 'short';

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data loading ─────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        PracticeApi.fetchSummary(_uid),
        PracticeApi.fetchStreak(_uid),
        PracticeApi.fetchVowelStats(_uid, 'short'),
        PracticeApi.fetchVowelStats(_uid, 'long'),
        PracticeApi.fetchRecentSessions(_uid),
      ]);
      setState(() {
        _summary = results[0] as ProgressSummary;
        _streak = results[1] as UserStreak;
        _shortStats = results[2] as List<VowelStats>;
        _longStats = results[3] as List<VowelStats>;
        _recentSessions = results[4] as List<SessionRecord>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  // ── Derived data ─────────────────────────────────────────────────────────────

  List<VowelStats> get _barStats =>
      _barType == 'short' ? _shortStats : _longStats;

  /// Bottom-3 vowels by average accuracy (only vowels that have been practised).
  List<VowelStats> get _weakVowels {
    return [..._shortStats, ..._longStats]
        .where((v) => v.practiceCount > 0)
        .toList()
      ..sort((a, b) => a.avgAccuracy.compareTo(b.avgAccuracy));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F3),
      appBar: _buildAppBar(),
      body: switch ((loading, error)) {
        (true, _) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1A7A50))),
        (_, String e) when e.isNotEmpty => _buildError(e),
        _ => _buildBody(),
      },
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() => AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Your Progress', 'ความก้าวหน้า'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          LanguageToggleButton(
            isEnglish: isEnglish,
            onChanged: (v) => setState(() => isEnglish = v),
          ),
        ],
      );

  // ── Scrollable body with all section widgets ──────────────────────────────────

  Widget _buildBody() {
    return RefreshIndicator(
      color: const Color.fromARGB(255, 236, 236, 236),
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1 — Hero accuracy banner
            SummaryCard(
              summary: _summary!,
              streak: _streak?.currentStreak ?? 0,
              isEnglish: isEnglish,
            ),
            const SizedBox(height: 16),

            // 2 — Practice count bar chart
            PracticeCountChart(
              stats: _barStats,
              type: _barType,
              isEnglish: isEnglish,
              onTypeChanged: (v) => setState(() => _barType = v),
            ),
            const SizedBox(height: 16),

            // 3 — Long vs short accuracy donuts
            AvgAccuracyDonuts(
              longAvg: _summary!.longAvgAccuracy,
              shortAvg: _summary!.shortAvgAccuracy,
              isEnglish: isEnglish,
            ),
            const SizedBox(height: 16),

            // 4 — Accuracy trend (self-contained: fetches its own data)
            TrendCard(
              firebaseUid: _uid,
              isEnglish: isEnglish,
            ),
            const SizedBox(height: 16),

            // 5 — Recent sessions list
            RecentSessionsList(
              sessions: _recentSessions,
              isEnglish: isEnglish,
            ),
            const SizedBox(height: 16),

            // 6 — Weak vowels CTA
            WeakVowelsList(
              weakVowels: _weakVowels.take(3).toList(),
              isEnglish: isEnglish,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _buildError(String _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.redAccent, size: 40),
            const SizedBox(height: 12),
            Text(
              t('Failed to load data', 'โหลดข้อมูลไม่สำเร็จ'),
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A7A50),
                foregroundColor: Colors.white,
              ),
              child: Text(t('Retry', 'ลองอีกครั้ง')),
            ),
          ],
        ),
      );
}
