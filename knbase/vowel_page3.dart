// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:http/http.dart' as http;
// import 'vowel_utils.dart';

// class VowelPage3 extends StatefulWidget {
//   const VowelPage3({super.key});

//   @override
//   State<VowelPage3> createState() => _VowelPage3State();
// }

// class _VowelPage3State extends State<VowelPage3> {
//   final AudioRecorder _recorder = AudioRecorder();
//   bool _isRecording = false;
//   String _statusText = "Press to start 2s recording";
//   static const int _recordDurationSeconds = 2;
//   int _remainingSeconds = _recordDurationSeconds;
//   Timer? _countdownTimer;

//   final String _apiUrl = "http://192.168.0.62:5000/predict2";

//   List<double> _refSamples = [];
//   List<double> _userSamples = [];

//   double _userF1 = 0, _userF2 = 0;
//   double _confidence = 0;
//   static const int _targetIndex = 1;

//   static const List<String> _vowelNames = [
//     '01', '02', '03', '04', '05', '06', '07', '08', '09',
//     's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9',
//   ];
//   static const List<String> _vowelLabels = [
//     'อา', 'อี', 'อือ', 'อู', 'เอ', 'แอ', 'โอ', 'ออ', 'เออ',
//     'อะ', 'อิ', 'อึ', 'อุ', 'เอะ', 'แอะ', 'โอะ', 'เอาะ', 'เออะ',
//   ];

//   @override
//   void dispose() {
//     _countdownTimer?.cancel();
//     _recorder.dispose();
//     super.dispose();
//   }

//   // ── FIXED: now applies preprocessSamples just like _loadUserWaveform ──
//   Future<List<double>> _loadRefWaveform(int classId) async {
//     try {
//       final path = 'assets/references/${_vowelNames[classId]}.wav';
//       debugPrint('[Ref] $path');
//       final data = await rootBundle.load(path);
//       final raw = decodePcmWav(data.buffer.asUint8List());
//       final processed = preprocessSamples(raw); // ← added: same as user
//       debugPrint('[Ref] raw=${raw.length} processed=${processed.length}');
//       return processed;
//     } catch (e) {
//       debugPrint('[Ref] error: $e');
//       return [];
//     }
//   }

//   Future<List<double>> _loadUserWaveform(String filePath) async {
//     try {
//       final bytes = await File(filePath).readAsBytes();
//       final raw = decodePcmWav(bytes);
//       final processed = preprocessSamples(raw);
//       debugPrint('[User] raw=${raw.length} processed=${processed.length}');
//       return processed;
//     } catch (e) {
//       debugPrint('[User] error: $e');
//       return [];
//     }
//   }

//   Future<void> _startRecordingWorkflow() async {
//     if (await _recorder.hasPermission()) {
//       final dir = await getApplicationDocumentsDirectory();
//       final path = '${dir.path}/vowel_audio3.wav';

//       const config = RecordConfig(
//         encoder: AudioEncoder.wav,
//         sampleRate: 16000,
//         numChannels: 1,
//       );

//       setState(() {
//         _isRecording = true;
//         _remainingSeconds = _recordDurationSeconds;
//         _statusText = "Recording... ($_remainingSeconds s)";
//         _refSamples = [];
//         _userSamples = [];
//       });

//       await _recorder.start(config, path: path);

//       _countdownTimer?.cancel();
//       _countdownTimer =
//           Timer.periodic(const Duration(seconds: 1), (timer) async {
//         if (_remainingSeconds <= 1) {
//           timer.cancel();
//           final finalPath = await _recorder.stop();
//           setState(() {
//             _isRecording = false;
//             _statusText = "Analysing...";
//           });
//           if (finalPath != null) _uploadToApi(finalPath);
//         } else {
//           setState(() {
//             _remainingSeconds--;
//             _statusText = "Recording... ($_remainingSeconds s)";
//           });
//         }
//       });
//     }
//   }

//   Future<void> _uploadToApi(String filePath) async {
//     try {
//       var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
//       request.files.add(await http.MultipartFile.fromPath('file', filePath));
//       request.fields['index'] = _targetIndex.toString();

//       final sr = await request.send();
//       final response = await http.Response.fromStream(sr);

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as Map<String, dynamic>;
//         final double conf = (data['confidence'] as num).toDouble();
//         final uf = data['user_formants'] as Map<String, dynamic>;

//         final waves = await Future.wait([
//           _loadRefWaveform(_targetIndex),
//           _loadUserWaveform(filePath),
//         ]);

//         setState(() {
//           _confidence = conf;
//           _userF1 = (uf['F1'] as num).toDouble();
//           _userF2 = (uf['F2'] as num).toDouble();
//           _refSamples = waves[0];
//           _userSamples = waves[1];
//           _statusText =
//               "Score: ${(_confidence * 100).toStringAsFixed(1)}%";
//         });

//         _showResultModal();
//       } else {
//         setState(() => _statusText = "Server Error: ${response.statusCode}");
//       }
//     } catch (e) {
//       setState(() => _statusText = "Connection Error: $e");
//     }
//   }

//   void _showResultModal() {
//     final vowelLabel = _vowelLabels[_targetIndex];
//     showDialog(
//       context: context,
//       builder: (ctx) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Center(
//                     child: Text("Practice Result",
//                         style: const TextStyle(
//                             fontSize: 20, fontWeight: FontWeight.bold)),
//                   ),
//                   const SizedBox(height: 4),
//                   Center(
//                     child: Text(
//                       "$vowelLabel  ·  ${(_confidence * 100).toStringAsFixed(1)}%",
//                       style:
//                           TextStyle(fontSize: 15, color: Colors.grey.shade600),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Center(child: _confidenceBar()),
//                   const SizedBox(height: 20),

//                   // ── Waveform ──────────────────────────────────────────
//                   Text("Waveform Comparison",
//                       style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700)),
//                   const SizedBox(height: 6),
//                   Container(
//                     height: 140,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade50,
//                       borderRadius: BorderRadius.circular(10),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(10),
//                       child: LayoutBuilder(
//                         builder: (ctx, constraints) => CustomPaint(
//                           size: Size(constraints.maxWidth, 140),
//                           painter: WaveformPainter(
//                             refSamples: _refSamples,
//                             userSamples: _userSamples,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       _legendDot(Colors.orange, "Reference"),
//                       const SizedBox(width: 20),
//                       _legendDot(const Color(0xFF2ECC71), "Your voice"),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // ── Formants ──────────────────────────────────────────
//                   Text("Formant Frequencies",
//                       style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade700)),
//                   const SizedBox(height: 8),
//                   _formantTable(),

//                   const SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(ctx),
//                       style: ElevatedButton.styleFrom(
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10)),
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                       ),
//                       child: const Text("Try Again"),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned(
//               right: 10,
//               top: 10,
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(ctx),
//                 child: Container(
//                   decoration: BoxDecoration(
//                       color: Colors.grey[200], shape: BoxShape.circle),
//                   child: Icon(Icons.close, color: Colors.grey[700], size: 24),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _confidenceBar() {
//     final pct = _confidence.clamp(0.0, 1.0);
//     final Color barColor;
//     final String label;
//     if (pct >= 0.75) {
//       barColor = const Color(0xFF2ECC71);
//       label = "Great!";
//     } else if (pct >= 0.5) {
//       barColor = Colors.orange;
//       label = "Keep practicing";
//     } else {
//       barColor = Colors.redAccent;
//       label = "Try again";
//     }

//     return Column(
//       children: [
//         SizedBox(
//           width: 200,
//           height: 12,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(6),
//             child: LinearProgressIndicator(
//               value: pct,
//               backgroundColor: Colors.grey.shade200,
//               valueColor: AlwaysStoppedAnimation<Color>(barColor),
//             ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//               fontSize: 12, color: barColor, fontWeight: FontWeight.w600),
//         ),
//       ],
//     );
//   }

//   Widget _legendDot(Color color, String label) => Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//               width: 12,
//               height: 12,
//               decoration:
//                   BoxDecoration(color: color, shape: BoxShape.circle)),
//           const SizedBox(width: 4),
//           Text(label,
//               style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//         ],
//       );

//   Widget _formantTable() {
//     final rows = [
//       ["", "F1 (Hz)", "F2 (Hz)"],
//       ["Your voice", _userF1.toStringAsFixed(0), _userF2.toStringAsFixed(0)],
//     ];

//     return Table(
//       border: TableBorder.all(
//           color: Colors.grey.shade200,
//           borderRadius: BorderRadius.circular(8)),
//       columnWidths: const {
//         0: FlexColumnWidth(2),
//         1: FlexColumnWidth(2),
//         2: FlexColumnWidth(2),
//       },
//       children: rows.asMap().entries.map((entry) {
//         final isHeader = entry.key == 0;
//         return TableRow(
//           decoration: BoxDecoration(
//             color: isHeader
//                 ? Colors.grey.shade100
//                 : (entry.key.isOdd ? Colors.white : Colors.grey.shade50),
//           ),
//           children: entry.value.map((cell) {
//             return Padding(
//               padding:
//                   const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
//               child: Text(
//                 cell,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontWeight:
//                       isHeader ? FontWeight.bold : FontWeight.normal,
//                   fontSize: 13,
//                   color: isHeader ? Colors.grey.shade700 : Colors.black87,
//                 ),
//               ),
//             );
//           }).toList(),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Vowel Practice")),
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _vowelLabels[_targetIndex],
//               style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _statusText,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 32),

//             // ── Record button ─────────────────────────────────────────
//             GestureDetector(
//               onTap: _isRecording ? null : _startRecordingWorkflow,
//               child: Container(
//                 padding: const EdgeInsets.all(30),
//                 decoration: BoxDecoration(
//                   color: _isRecording ? Colors.red : Colors.blue,
//                   shape: BoxShape.circle,
//                   boxShadow: const [
//                     BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10,
//                         offset: Offset(0, 4))
//                   ],
//                 ),
//                 child: Icon(
//                     _isRecording ? Icons.stop : Icons.mic,
//                     size: 50,
//                     color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }