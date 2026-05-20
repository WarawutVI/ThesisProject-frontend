import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/services/practice_api.dart';
import 'package:frontend/services/vowel_utils.dart';
import 'package:frontend/widgets/waveform_display.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingPage extends StatefulWidget {
  final int lessonId;
  final int vowelId;      // DB id 1–18, used to derive Flask index + asset
  final String word;
  final String vowelSymbol;
  final bool isEnglish;

  const RecordingPage({
    super.key,
    required this.lessonId,
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

  String get firebaseUid => FirebaseAuth.instance.currentUser!.uid;
  String t(String en, String th) => isEnglish ? en : th;

  int get _vowelIndex => vowelIdToIndex(widget.vowelId);
  String get _assetName => vowelIndexToAssetName(_vowelIndex);

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
      final path = 'assets/references/$_assetName.wav';
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

  void _showResultModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      t('Practice Result', 'ผลการฝึก'),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${widget.word}  ·  ${(_confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(child: _confidenceBar()),
                  const SizedBox(height: 20),

                  // Waveform
                  Text(
                    t('Waveform Comparison', 'เปรียบเทียบคลื่นเสียง'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  WaveformDisplay(
                    refSamples: _refSamples,
                    userSamples: _userSamples,
                    refLabel: t('Reference', 'เสียงอ้างอิง'),
                    userLabel: t('Your voice', 'เสียงของคุณ'),
                  ),
                  const SizedBox(height: 20),

                  // Formants
                  Text(
                    t('Formant Frequencies', 'ความถี่ฟอร์แมนต์'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  _formantTable(),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF1A7A50)),
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
                              style:
                                  const TextStyle(color: Colors.white)),
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
                  child: Icon(Icons.close,
                      color: Colors.grey[700], size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBar() {
    final pct = _confidence.clamp(0.0, 1.0);
    final Color barColor;
    final String label;
    if (pct >= 0.75) {
      barColor = const Color(0xFF2ECC71);
      label = t('Great!', 'เยี่ยมมาก!');
    } else if (pct >= 0.5) {
      barColor = Colors.orange;
      label = t('Keep practicing', 'ฝึกต่อไป');
    } else {
      barColor = Colors.redAccent;
      label = t('Try again', 'ลองอีกครั้ง');
    }

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: barColor,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _formantTable() {
    final rows = [
      ['', 'F1 (Hz)', 'F2 (Hz)'],
      [
        t('Your voice', 'เสียงของคุณ'),
        _userF1.toStringAsFixed(0),
        _userF2.toStringAsFixed(0),
      ],
    ];

    return Table(
      border: TableBorder.all(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
      },
      children: rows.asMap().entries.map((entry) {
        final isHeader = entry.key == 0;
        return TableRow(
          decoration: BoxDecoration(
            color: isHeader
                ? Colors.grey.shade100
                : (entry.key.isOdd
                    ? Colors.white
                    : Colors.grey.shade50),
          ),
          children: entry.value.map((cell) {
            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Text(
                cell,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight:
                      isHeader ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isHeader
                      ? Colors.grey.shade700
                      : Colors.black87,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
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
          IconButton(
            onPressed: () => setState(() => isEnglish = !isEnglish),
            icon: const Icon(Icons.language, color: Colors.black54),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.vowelSymbol,
                style: const TextStyle(
                    fontSize: 36, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                widget.word,
                style: const TextStyle(
                  fontSize: 72,
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
