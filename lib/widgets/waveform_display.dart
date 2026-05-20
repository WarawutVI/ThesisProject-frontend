import 'package:flutter/material.dart';
import 'package:frontend/services/vowel_utils.dart';

/// A self-contained waveform comparison widget.
/// Shows the reference (orange) and user (green) audio curves
/// side-by-side with a legend below.
class WaveformDisplay extends StatelessWidget {
  final List<double> refSamples;
  final List<double> userSamples;
  final String refLabel;
  final String userLabel;
  final double height;

  const WaveformDisplay({
    super.key,
    required this.refSamples,
    required this.userSamples,
    this.refLabel = 'Reference',
    this.userLabel = 'Your voice',
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LayoutBuilder(
              builder: (ctx, constraints) => CustomPaint(
                size: Size(constraints.maxWidth, height),
                painter: WaveformPainter(
                  refSamples: refSamples,
                  userSamples: userSamples,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendDot(color: Colors.orange, label: refLabel),
            const SizedBox(width: 20),
            _LegendDot(color: const Color(0xFF2ECC71), label: userLabel),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
