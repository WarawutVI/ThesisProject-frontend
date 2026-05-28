import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/pages/homepage.dart';
import 'package:frontend/pages/practice/recording_page.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class WordGridPage extends StatefulWidget {
  final int vowelId;
  final String vowelSymbol;
  final String vowelType;
  final bool isEnglish;

  const WordGridPage({
    super.key,
    required this.vowelId,
    required this.vowelSymbol,
    required this.vowelType,
    this.isEnglish = true,
  });

  @override
  State<WordGridPage> createState() => _WordGridPageState();
}

class _WordGridPageState extends State<WordGridPage> {
  late bool isEnglish;
  LessonProgress? _vowelLesson;
  List<LessonProgress> _wordLessons = [];
  bool loading = true;
  String? error;

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PracticeApi.fetchLessons(firebaseUid, widget.vowelId);
      setState(() {
        _vowelLesson = data.where((l) => l.lessonOrder == 1).firstOrNull;
        _wordLessons = data.where((l) => l.lessonOrder != 1).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _tapLesson(LessonProgress l) async {
    await Get.to(() => RecordingPage(
          lessonId: l.lessonId,
          lessonOrder: l.lessonOrder,
          vowelId: widget.vowelId,
          word: l.lessonName,
          vowelSymbol: widget.vowelSymbol,
          isEnglish: isEnglish,
        ));
    setState(() => loading = true);
    _load();
  }

  Color _cardColor(LessonProgress l) {
    if (l.isCompleted == null) return Colors.white;
    if (l.isCompleted == true) return const Color(0xFFD4F5E2);
    return const Color(0xFFFFE5CC);
  }

  Color _borderColor(LessonProgress l) {
    if (l.isCompleted == null) return const Color(0xFFDDDDDD);
    if (l.isCompleted == true) return const Color(0xFF1A7A50);
    return const Color(0xFFFF8C42);
  }

  Widget? _badge(LessonProgress l) {
    if (l.isCompleted == null) return null;
    if (l.isCompleted == true) {
      return const Positioned(
        top: 6,
        right: 6,
        child: CircleAvatar(
          radius: 10,
          backgroundColor: Color(0xFF1A7A50),
          child: Icon(Icons.check, size: 12, color: Colors.white),
        ),
      );
    }
    return const Positioned(
      top: 6,
      right: 6,
      child: CircleAvatar(
        radius: 10,
        backgroundColor: Color(0xFFFF8C42),
        child: Icon(Icons.close, size: 12, color: Colors.white),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          t('How to pronounce ${widget.vowelSymbol}',
              'วิธีออกเสียง ${widget.vowelSymbol}'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A7A50)),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t('Articulation Guide', 'คำแนะนำการออกเสียง'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Open your mouth naturally. Relax your tongue and keep it low. '
                  'Do not round your lips. Hold the sound steady.',
                  'อ้าปากตามธรรมชาติ ผ่อนคลายลิ้นและวางลิ้นต่ำในปาก '
                  'ห้ามห่อปาก ยืดเสียงให้นิ่ง',
                ),
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF8F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_fill,
                          size: 40, color: Color(0xFF1A7A50)),
                      SizedBox(height: 8),
                      Text('Video placeholder',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('Close', 'ปิด'),
                style: const TextStyle(color: Color(0xFF1A7A50))),
          ),
        ],
      ),
    );
  }

  Widget _sectionBadge(int number) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF1A7A50),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF8F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          t('Practice', 'ฝึกพูด'),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          LanguageToggleButton(
            isEnglish: isEnglish,
            onChanged: (v) => setState(() => isEnglish = v),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          _load();
                        },
                        child: Text(t('Retry', 'ลองอีกครั้ง')),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vowel symbol + info button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.vowelSymbol,
                                  style: const TextStyle(
                                    fontSize: 70,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _showInfoDialog,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A7A50),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.info_outline,
                                        color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Section 1: just the vowel
                            if (_vowelLesson != null) ...[
                              Row(
                                children: [
                                  _sectionBadge(1),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('just the vowel', 'แค่สระ'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('say it alone', 'ออกเสียงเดี่ยว'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => _tapLesson(_vowelLesson!),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: _cardColor(_vowelLesson!),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _borderColor(_vowelLesson!),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _vowelLesson!.lessonName,
                                            style: const TextStyle(
                                              fontSize: 42,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1A7A50),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.mic,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_badge(_vowelLesson!) != null)
                                      _badge(_vowelLesson!)!,
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Section 2: with letters
                            if (_wordLessons.isNotEmpty) ...[
                              Row(
                                children: [
                                  _sectionBadge(2),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('With letters', 'คำที่ใช้สระนี้'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('${_wordLessons.length} words',
                                        '${_wordLessons.length} คำ'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _wordLessons.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.0,
                                ),
                                itemBuilder: (context, index) {
                                  final l = _wordLessons[index];
                                  return GestureDetector(
                                    onTap: () => _tapLesson(l),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: _cardColor(l),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: _borderColor(l),
                                                width: 2),
                                          ),
                                          child: Center(
                                            child: Text(
                                              l.lessonName,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_badge(l) != null) _badge(l)!,
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Home button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28),
                      child: GestureDetector(
                        onTap: () => Get.offAll(() => Homepage()),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A6B45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
