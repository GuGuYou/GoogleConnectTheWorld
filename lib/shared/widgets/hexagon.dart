import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Regular hexagon clip, shared by honeycomb UIs.
/// [pointy] true = vertex at top/bottom; false = flat top/bottom edges
/// (flat-top tiles a top/bottom + 4-diagonal flower without gaps).
class HexagonClipper extends CustomClipper<Path> {
  final bool pointy;
  const HexagonClipper({this.pointy = true});

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final start = pointy ? math.pi / 6 : 0.0;
    for (var i = 0; i < 6; i++) {
      final angle = start + i * math.pi / 3;
      final point = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant HexagonClipper oldClipper) =>
      oldClipper.pointy != pointy;
}
