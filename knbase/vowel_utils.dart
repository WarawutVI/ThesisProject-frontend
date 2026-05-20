import 'dart:typed_data';
import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  final List<double> refSamples;
  final List<double> userSamples;

  WaveformPainter({required this.refSamples, required this.userSamples});

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;

    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 0.8,
    );

    void drawWave(List<double> samples, Color color, double strokeWidth) {
      if (samples.length < 2) return;
      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      for (int i = 0; i < samples.length; i++) {
        final x = (i / (samples.length - 1)) * size.width;
        final y = midY - (samples[i] * midY * 0.85);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    drawWave(refSamples, Colors.orange.withValues(alpha: 0.9), 2.0);
    drawWave(userSamples, const Color(0xFF2ECC71).withValues(alpha: 0.9), 1.8);
  }

  @override
  bool shouldRepaint(WaveformPainter old) =>
      old.refSamples != refSamples || old.userSamples != userSamples;
}

// Walks RIFF chunks to find "data" then decodes 16-bit PCM to normalised [-1, 1]
List<double> decodePcmWav(Uint8List bytes, {int targetPoints = 200}) {
  if (bytes.length < 44) {
    debugPrint('[WAV] file too small: ${bytes.length}');
    return [];
  }

  final bd = ByteData.sublistView(bytes);

  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  if (riff != 'RIFF') {
    debugPrint('[WAV] not RIFF (got "$riff")');
    return [];
  }

  int offset = 12;
  int dataStart = -1;
  int dataLen = 0;

  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final chunkSize = bd.getUint32(offset + 4, Endian.little);
    debugPrint('[WAV] chunk "$id" size=$chunkSize offset=$offset');

    if (id == 'data') {
      dataStart = offset + 8;
      dataLen = chunkSize;
      break;
    }
    offset += 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
  }

  if (dataStart < 0 || dataLen == 0) {
    debugPrint('[WAV] "data" chunk not found');
    return [];
  }

  final end = (dataStart + dataLen).clamp(0, bytes.length);
  final pcm = bytes.sublist(dataStart, end);
  final sampleCount = pcm.length ~/ 2;

  if (sampleCount == 0) return [];
  debugPrint('[WAV] $sampleCount samples at offset $dataStart');

  final raw = List<double>.filled(sampleCount, 0.0);
  for (int i = 0; i < sampleCount; i++) {
    int s = (pcm[i * 2 + 1] << 8) | pcm[i * 2];
    if (s >= 0x8000) s -= 0x10000;
    raw[i] = s / 32768.0;
  }

  final step = raw.length / targetPoints;
  final result = List<double>.generate(targetPoints, (i) {
    return raw[(i * step).toInt().clamp(0, raw.length - 1)];
  });

  final maxAbs =
      result.map((v) => v.abs()).fold(0.0, (a, b) => a > b ? a : b);
  if (maxAbs > 0) return result.map((v) => v / maxAbs).toList();
  return result;
}

// Strip silence from both ends then keep middle 50%
List<double> preprocessSamples(List<double> samples,
    {double silenceThreshold = 0.02}) {
  if (samples.isEmpty) return [];

  int start = 0;
  while (start < samples.length && samples[start].abs() < silenceThreshold) {
    start++;
  }
  int end = samples.length - 1;
  while (end > start && samples[end].abs() < silenceThreshold) {
    end--;
  }

  final trimmed = samples.sublist(start, end + 1);
  if (trimmed.length < 10) return samples;

  final cropAmt = (trimmed.length * 0.25).round();
  final cropped = trimmed.sublist(cropAmt, trimmed.length - cropAmt);
  return cropped.length < 10 ? trimmed : cropped;
}
