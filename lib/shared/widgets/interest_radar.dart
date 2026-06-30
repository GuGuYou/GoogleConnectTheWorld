import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/ip_tag.dart';

/// 兴趣雷达图：可视化双方在各分类上的兴趣浓度与重合
/// 参考"匹配可视化"，直观告诉用户为什么配到一起。
class InterestRadar extends StatelessWidget {
  final Map<String, double> me; // category -> 0..1
  final Map<String, double>? other; // 对方（可空）
  final String lang;
  final double size;

  const InterestRadar({
    super.key,
    required this.me,
    this.other,
    required this.lang,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(me: me, other: other, lang: lang),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<String, double> me;
  final Map<String, double>? other;
  final String lang;
  _RadarPainter({required this.me, this.other, required this.lang});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.62;
    final cats = kTagCategories;
    final n = cats.length;
    final angleStep = 2 * math.pi / n;

    // 网格圈
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.glassBorder
      ..strokeWidth = 1;
    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * angleStep;
        final r = radius * ring / 4;
        final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 轴线 + 标签
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final end = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(center, end, gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: cats[i].name(lang),
          style: TextStyle(color: cats[i].color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final labelPos = center +
          Offset(math.cos(angle) * (radius + 16), math.sin(angle) * (radius + 16)) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, labelPos);
    }

    _drawPolygon(canvas, center, radius, angleStep, cats, me, AppColors.neonCyan);
    if (other != null) {
      _drawPolygon(canvas, center, radius, angleStep, cats, other!, AppColors.neonPink);
    }
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, double angleStep,
      List<TagCategory> cats, Map<String, double> data, Color color) {
    final path = Path();
    for (var i = 0; i < cats.length; i++) {
      final angle = -math.pi / 2 + i * angleStep;
      final v = (data[cats[i].key] ?? 0).clamp(0.08, 1.0);
      final r = radius * v;
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.18));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.me != me || old.other != other || old.lang != lang;
}

/// 由标签列表算出各分类浓度（0..1）
Map<String, double> radarFromTags(List<IpTag> tags) {
  final counts = <String, int>{};
  for (final t in tags) {
    counts[t.category] = (counts[t.category] ?? 0) + 1;
  }
  final maxC = counts.values.isEmpty ? 1 : counts.values.reduce(math.max);
  return {
    for (final c in kTagCategories) c.key: (counts[c.key] ?? 0) / maxC,
  };
}
