import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BmiGauge extends StatelessWidget {
  final double bmiValue;
  final String category;

  const BmiGauge({super.key, required this.bmiValue, required this.category});

  Color get _categoryColor {
    if (bmiValue < 18.5) return AppColors.warning;
    if (bmiValue < 25) return AppColors.success;
    if (bmiValue < 30) return AppColors.accent;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      width: double.infinity,
      child: CustomPaint(
        painter: _GaugePainter(bmiValue: bmiValue),
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: Column(
            children: [
              Text(
                bmiValue.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _categoryColor.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: _categoryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _GaugePainter extends CustomPainter {
  final double bmiValue;
  _GaugePainter({required this.bmiValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = min(size.width / 2, size.height) - 10;
    const startAngle = pi; // 180deg
    const sweepAngle = pi; // half circle

    // Segmented background arc: kurus - normal - berlebih - obesitas
    final segments = [
      (AppColors.warning, 0.18), // kurus < 18.5 (proporsi kira-kira)
      (AppColors.success, 0.32), // normal 18.5-25
      (AppColors.accent, 0.25), // berlebih 25-30
      (AppColors.danger, 0.25), // obesitas > 30
    ];

    double currentStart = startAngle;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    for (final seg in segments) {
      final sweep = sweepAngle * seg.$2;
      strokePaint.color = seg.$1;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentStart,
        sweep,
        false,
        strokePaint,
      );
      currentStart += sweep;
    }

    // Needle: map bmi 15..35 ke sudut 180..360 derajat
    final clamped = bmiValue.clamp(15, 35);
    final t = (clamped - 15) / (35 - 15);
    final angle = startAngle + sweepAngle * t;

    final needleLength = radius - 6;
    final needleEnd = Offset(
      center.dx + needleLength * cos(angle),
      center.dy + needleLength * sin(angle),
    );

    final needlePaint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    final dotPaint = Paint()..color = AppColors.textDark;
    canvas.drawCircle(center, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.bmiValue != bmiValue;
}
