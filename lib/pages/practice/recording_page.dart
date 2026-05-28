import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:frontend/services/vowel_utils.dart';
import 'package:frontend/widgets/language_toggle_button.dart';
import 'package:frontend/widgets/waveform_display.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingPage extends StatefulWidget {
  final int lessonId;
  final int lessonOrder;
  final int vowelId;
  final String word;
  final String vowelSymbol;
  final bool isEnglish;

  const RecordingPage({
    super.key,
    required this.lessonId,
    required this.lessonOrder,
    required this.vowelId,
    required this.word,
    required this.vowelSymbol,
    this.isEnglish = true,
  });

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  static const int _recordSeconds = 2;

  late bool isEnglish;
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  int _remainingSeconds = _recordSeconds;
  String _statusText = '';
  Timer? _countdownTimer;

  List<double> _refSamples = [];
  List<double> _userSamples = [];
  double _confidence = 0;
  double _userF1 = 0;
  double _userF2 = 0;
  VowelFormant? _refFormant;

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  int get _vowelIndex => vowelIdToIndex(widget.vowelId);

  @override
  void initState() {
    super.initState();
    isEnglish = widget.isEnglish;
    _statusText = t(
      'Press the mic and speak for $_recordSeconds seconds.',
      'กดไมค์แล้วพูด $_recordSeconds วินาที',
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<List<double>> _loadRefWaveform() async {
    try {
      final path = 'assets/references/${widget.vowelId}/${widget.lessonOrder}.wav';
      print('Loading reference waveform from: $path');
      final data = await rootBundle.load(path);
      return preprocessSamples(decodePcmWav(data.buffer.asUint8List()));
    } catch (e) {
      debugPrint('Ref waveform load error: $e');
      return [];
    }
  }

  Future<List<double>> _loadUserWaveform(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      return preprocessSamples(decodePcmWav(bytes));
    } catch (e) {
      debugPrint('User waveform load error: $e');
      return [];
    }
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      Get.snackbar(
        t('Permission Denied', 'ไม่ได้รับอนุญาต'),
        t('Microphone access is required', 'ต้องการสิทธิ์เข้าถึงไมโครโฟน'),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/vowel_${widget.vowelId}.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _remainingSeconds = _recordSeconds;
      _statusText = t('Recording... $_remainingSeconds s',
          'กำลังบันทึก... $_remainingSeconds วินาที');
      _refSamples = [];
      _userSamples = [];
    });

    _countdownTimer?.cancel();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        final finalPath = await _recorder.stop();
        setState(() {
          _isRecording = false;
          _statusText = t('Analysing...', 'กำลังวิเคราะห์...');
        });
        if (finalPath != null) await _submitToApi(finalPath);
      } else {
        setState(() {
          _remainingSeconds--;
          _statusText = t('Recording... $_remainingSeconds s',
              'กำลังบันทึก... $_remainingSeconds วินาที');
        });
      }
    });
  }

  Future<void> _submitToApi(String filePath) async {
    final recordStart = DateTime.now()
        .subtract(Duration(seconds: _recordSeconds));
    try {
      final result = await PracticeApi.predict(File(filePath), _vowelIndex);
      final duration = DateTime.now().difference(recordStart).inSeconds;

      final waves = await Future.wait([
        _loadRefWaveform(),
        _loadUserWaveform(filePath),
      ]);

      VowelFormant? refFormant;
      try {
        refFormant = await PracticeApi.fetchVowelFormant(widget.vowelId);
      } catch (_) {}

      // Save to backend (fire-and-forget; don't block UI)
      PracticeApi.saveSession(
        firebaseUid: firebaseUid,
        lessonId: widget.lessonId,
        confidence: result.confidence,
        isPassed: result.isPassed,
        durationSeconds: duration,
      );
      PracticeApi.saveProgress(
        firebaseUid: firebaseUid,
        lessonId: widget.lessonId,
        isCompleted: result.isPassed,
        bestAccuracy: result.confidence,
      );
      PracticeApi.updateStreak(firebaseUid);

      setState(() {
        _confidence = result.confidence;
        _userF1 = result.userF1;
        _userF2 = result.userF2;
        _refFormant = refFormant;
        _refSamples = waves[0];
        _userSamples = waves[1];
        _statusText =
            t('Score: ${(_confidence * 100).toStringAsFixed(1)}%',
              'คะแนน: ${(_confidence * 100).toStringAsFixed(1)}%');
      });

      _showResultModal();
    } catch (e) {
      setState(() => _statusText = t('Error: $e', 'เกิดข้อผิดพลาด: $e'));
    }
  }

  String _buildSuggestion() {
    final ref = _refFormant;
    if (ref == null || (_userF1 == 0 && _userF2 == 0)) return '';

    final List<String> partsEn = [];
    final List<String> partsTh = [];

    final f1Diff = _userF1;
    final f2Diff = _userF2;
    final f1Threshold = ref.f1 ;
    final f2Threshold = ref.f2;

    if (f1Diff > f1Threshold) {
      partsEn.addAll(['closing your mouth slightly', 'raising your tongue']);
      partsTh.addAll(['ปิดปากลงเล็กน้อย', 'ยกลิ้นขึ้น']);
    } else if (f1Diff < -f1Threshold) {
      partsEn.addAll(['opening your mouth wider', 'lowering your tongue']);
      partsTh.addAll(['อ้าปากให้กว้างขึ้น', 'วางลิ้นให้ต่ำลง']);
    }

    if (f2Diff > f2Threshold) {
      partsEn.add('moving your tongue slightly back');
      partsTh.add('เลื่อนลิ้นไปด้านหลังเล็กน้อย');
    } else if (f2Diff < -f2Threshold) {
      partsEn.addAll(['moving your tongue slightly forward', 'relaxing your lips']);
      partsTh.addAll(['เลื่อนลิ้นไปด้านหน้าเล็กน้อย', 'ผ่อนคลายริมฝีปาก']);
    }

    if (partsEn.isEmpty) return '';
    return isEnglish
        ? 'Try ${partsEn.join(', ')}.'
        : 'ลอง${partsTh.join(' ')}';
  }

  void _showResultModal() {
    final passed = _confidence >= 0.70;
    final suggestion = _buildSuggestion();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      passed
                          ? t('Correct 🎉', 'ถูกต้อง 🎉')
                          : t('Incorrect', 'ไม่ถูกต้อง'),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: passed
                            ? const Color(0xFF1A7A50)
                            : Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Waveform
                  WaveformDisplay(
                    refSamples: _refSamples,
                    userSamples: _userSamples,
                    refLabel: t('Sample Audio', 'เสียงตัวอย่าง'),
                    userLabel: t('Your Audio', 'เสียงของคุณ'),
                  ),
                  const SizedBox(height: 14),

                  // Accuracy
                  Center(
                    child: Text(
                      t(
                        'accuracy ${(_confidence * 100).toStringAsFixed(0)}%',
                        'ความแม่นยำ ${(_confidence * 100).toStringAsFixed(0)}%',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Suggestion
                  if (suggestion.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${t('suggestion', 'คำแนะนำ')} : ',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextSpan(
                            text: suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A7A50)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(t('Try Again', 'ลองอีกครั้ง'),
                              style: const TextStyle(
                                  color: Color(0xFF1A7A50))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Get.back();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A7A50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(t('Finish', 'เสร็จสิ้น'),
                              style: const TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey[200], shape: BoxShape.circle),
                  child:
                      Icon(Icons.close, color: Colors.grey[700], size: 24),
                ),
              ),
            ),
          ],
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(
              //   widget.vowelSymbol,
              //   style: const TextStyle(
              //       fontSize: 36, color: Colors.grey),
              // // ),
              // const SizedBox(height: 8),
              Text(
                widget.word,
                style: const TextStyle(
                  fontSize: 170,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isRecording ? null : _startRecording,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? Colors.red
                        : const Color(0xFF1A7A50),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                                ? Colors.red
                                : const Color(0xFF1A7A50))
                            .withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
