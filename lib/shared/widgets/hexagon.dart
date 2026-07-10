import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Regular hexagon clip (pointy-top), shared by honeycomb UIs.
class HexagonClipper extends CustomClipper<Path> {
  const HexagonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
