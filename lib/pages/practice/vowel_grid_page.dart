import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/pages/practice/word_grid_page.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:get/get.dart';

class VowelGridPage extends StatefulWidget {
  final String type; // 'short' or 'long'

  const VowelGridPage({super.key, required this.type});

  @override
  State<VowelGridPage> createState() => _VowelGridPageState();
}

class _VowelGridPageState extends State<VowelGridPage> {
  bool isEnglish = true;
  List<VowelProgress> vowels = [];
  bool loading = true;
  String? error;

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;

  String t(String en, String th) => isEnglish ? en : th;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await PracticeApi.fetchVowels(firebaseUid, widget.type);
      setState(() {
        vowels = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Color _cardColor(VowelProgress v) {
    if (v.completed == 0) return const Color(0xFFF0F0F0);
    if (v.completed >= v.total) return const Color(0xFFD4F5E2);
    return const Color(0xFFFFE5CC);
  }

  Color _borderColor(VowelProgress v) {
    if (v.completed == 0) return Colors.transparent;
    if (v.completed >= v.total) return const Color(0xFF1A7A50);
    return const Color(0xFFFF8C42);
  }

  Widget? _badge(VowelProgress v) {
    if (v.completed == 0) return null;
    if (v.completed >= v.total) {
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

  int get _completedVowels =>
      vowels.where((v) => v.completed >= v.total && v.total > 0).length;

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'short'
        ? t('Short Vowels', 'สระเสียงสั้น')
        : t('Long Vowels', 'สระเสียงยาว');

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
                          child: Text(t('Retry', 'ลองอีกครั้ง'))),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + badge row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A7A50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_completedVowels / ${vowels.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t('OVERALL PROGRESS', 'ความก้าวหน้าโดยรวม'),
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vowels.isEmpty
                              ? 0
                              : _completedVowels / vowels.length,
                          backgroundColor: const Color(0xFFDDDDDD),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1A7A50)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          itemCount: vowels.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, index) {
                            final v = vowels[index];
                            return GestureDetector(
                              onTap: () async {
                                await Get.to(() => WordGridPage(
                                      vowelId: v.vowelId,
                                      vowelSymbol: v.symbol,
                                      vowelType: v.vowelType,
                                      isEnglish: isEnglish,
                                    ));
                                // Reload after returning to refresh progress
                                setState(() => loading = true);
                                _load();
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: _cardColor(v),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: _borderColor(v), width: 2),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          v.symbol,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${v.completed}/${v.total}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_badge(v) != null) _badge(v)!,
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
