import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Flat #050605 backdrop with soft orange glows and faint honeycomb texture,
/// matching the Figma frame base (glow ellipses #FF8C00 + scattered hexes).
class NeonBackground extends StatelessWidget {
  final Widget child;
  const NeonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg0,
      child: Stack(
        children: [
          const Positioned.fill(child: _HoneycombPattern()),
          // 顶部主暖光（对应设计稿 #FF8C00 辉光椭圆）
          Positioned(
              top: -160,
              left: -40,
              right: -40,
              child: _blob(AppColors.glowOrange.withValues(alpha: 0.42), 460)),
          Positioned(
              top: 30,
              left: 30,
              right: 30,
              child: _blob(AppColors.glowOrange.withValues(alpha: 0.16), 300)),
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
      ..color = AppColors.neonYellow.withValues(alpha: 0.04)
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
