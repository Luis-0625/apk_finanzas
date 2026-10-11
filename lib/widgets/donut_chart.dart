import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/format.dart';

class DonutSegment {
  final Color color;
  final double value;
  const DonutSegment(this.color, this.value);
}

class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.segments,
    required this.balance,
    required this.income,
    required this.expense,
    required this.size,
  });

  final List<DonutSegment> segments;
  final int balance;
  final int income;
  final int expense;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sig = segments.map((s) => s.value).join(',');
    final positive = balance >= 0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(sig),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, p, __) => CustomPaint(
              size: Size.square(size),
              painter: _DonutPainter(segments: segments, progress: p, stroke: size * 0.085),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.17),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Balance del mes',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: balance.toDouble()),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cop(v),
                      style: TextStyle(
                        fontSize: size * 0.13,
                        fontWeight: FontWeight.w800,
                        color: positive ? AppColors.emerald : AppColors.expense,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.emerald),
                    const SizedBox(width: 2),
                    Text(copCompact(income),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                    const SizedBox(width: 2),
                    Text(copCompact(expense),
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.progress, required this.stroke});
  final List<DonutSegment> segments;
  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );

    canvas.drawArc(
      rect, 0, 2 * pi, false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withOpacity(0.06),
    );

    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    final gap = segments.length > 1 ? 0.06 : 0.0;
    var start = -pi / 2;
    for (final s in segments) {
      final sweep = (s.value / total) * 2 * pi;
      final drawn = max(0.0, sweep - gap) * progress;
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = s.color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = s.color;
      canvas.drawArc(rect, start + gap / 2, drawn, false, glow);
      canvas.drawArc(rect, start + gap / 2, drawn, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.segments != segments || old.stroke != stroke;
}
