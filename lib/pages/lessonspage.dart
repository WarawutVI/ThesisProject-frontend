import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/pages/lessons/vowel_detail_page.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class Lessonspage extends StatefulWidget {
  const Lessonspage({super.key});

  @override
  State<Lessonspage> createState() => _LessonspageState();
}

class _LessonspageState extends State<Lessonspage> {
  bool isEnglish = true;
  bool loading = true;
  List<VowelDetail> _vowels = [];
  String? _error;

  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; _error = null; });
    try {
      final data = await PracticeApi.fetchVowelDetails();
      setState(() { _vowels = data; loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final longVowels  = _vowels.where((v) => v.vowelType == 'long').toList();
    final shortVowels = _vowels.where((v) => v.vowelType == 'short').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Lessons', 'บทเรียน'),
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          LanguageToggleButton(
            isEnglish: isEnglish,
            onChanged: (v) => setState(() => isEnglish = v),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A7A50)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A7A50)),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF1A7A50),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _NewHereBanner(isEnglish: isEnglish),
                      const SizedBox(height: 24),
                      _VowelSection(
                        title: t('Long Vowels', 'สระเสียงยาว'),
                        vowels: longVowels,
                        isEnglish: isEnglish,
                      ),
                      const SizedBox(height: 28),
                      _VowelSection(
                        title: t('Short Vowels', 'สระเสียงสั้น'),
                        vowels: shortVowels,
                        isEnglish: isEnglish,
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── "New here?" banner ────────────────────────────────────────────────────────

class _NewHereBanner extends StatelessWidget {
  final bool isEnglish;
  const _NewHereBanner({required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book_rounded, color: Color(0xFF1A7A50), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEnglish ? 'New here?' : 'มาใหม่ใช่ไหม?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isEnglish
                    ? 'Tap any vowel to learn how to say it.'
                    : 'แตะสระเพื่อเรียนรู้วิธีออกเสียง',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section (Long / Short) with 3×3 grid ─────────────────────────────────────

class _VowelSection extends StatelessWidget {
  final String title;
  final List<VowelDetail> vowels;
  final bool isEnglish;

  const _VowelSection({
    required this.title,
    required this.vowels,
    required this.isEnglish,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              isEnglish ? '${vowels.length} sounds' : '${vowels.length} เสียง',
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: vowels.length,
          itemBuilder: (_, i) => _VowelCard(vowel: vowels[i], isEnglish: isEnglish),
        ),
      ],
    );
  }
}

// ── Individual vowel card ─────────────────────────────────────────────────────

class _VowelCard extends StatelessWidget {
  final VowelDetail vowel;
  final bool isEnglish;
  const _VowelCard({required this.vowel, required this.isEnglish});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => VowelDetailPage(vowel: vowel, isEnglish: isEnglish),
        transition: Transition.rightToLeft,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              vowel.symbol,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              vowel.unicodePhonetic ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A7A50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
