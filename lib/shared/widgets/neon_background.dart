import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class NeonBackground extends StatelessWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF070807), Color(0xFF161100), Color(0xFF050503)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: _HoneycombPattern()),
          Positioned(
              top: -90,
              right: -80,
              child: _blob(AppColors.neonYellow.withValues(alpha: 0.22), 280)),
          Positioned(
              bottom: -100,
              left: -100,
              child: _blob(AppColors.neonPurple.withValues(alpha: 0.18), 260)),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _HoneycombPattern extends StatelessWidget {
  const _HoneycombPattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _HoneycombPainter());
  }
}

class _HoneycombPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonYellow.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const radius = 26.0;
    const h = radius * 1.732;
    for (double y = -h; y < size.height + h; y += h) {
      final offset = ((y / h).round().isEven) ? 0.0 : radius * 1.5;
      for (double x = -radius * 2;
          x < size.width + radius * 2;
          x += radius * 3) {
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final angle = 1.0472 * i + 0.5236;
          final point = Offset(x + offset + radius * math.cos(angle),
              y + radius * math.sin(angle));
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
