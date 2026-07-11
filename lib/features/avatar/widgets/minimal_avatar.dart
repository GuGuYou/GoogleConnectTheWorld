import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/models/virtual_avatar.dart';

/// Minimalist, Monument-Valley-inspired procedural avatar: flat geometric
/// faces, soft gradients, warm palette. Composed from the avatar's part
/// indices so every customization choice is reflected live.
///
/// Option counts (indices taken modulo these): face 5, eyes 5, mouth 5,
/// accessory 5, background 5. (Hairstyle was removed.)
class MinimalAvatarPainter extends CustomPainter {
  final VirtualAvatar avatar;

  /// When false the background gradient is skipped (for compositing).
  final bool drawBackground;

  const MinimalAvatarPainter(this.avatar, {this.drawBackground = true});

  // ── palettes ──────────────────────────────────────────────────────────
  static const backgrounds = <List<Color>>[
    [Color(0xFFFFE1A0), Color(0xFFEDA53E)], // gold
    [Color(0xFFF9C4D2), Color(0xFFE68AA6)], // rose
    [Color(0xFFCFB8EE), Color(0xFF9A78C9)], // lavender
    [Color(0xFFAADCD4), Color(0xFF64ABA8)], // teal
    [Color(0xFF7E6DAA), Color(0xFF3C2F5C)], // dusk
  ];

  static const _skins = <List<Color>>[
    [Color(0xFFFCE3C6), Color(0xFFF3CBA6)], // cream
    [Color(0xFFF8D0A8), Color(0xFFEBB081)], // light
    [Color(0xFFE9B387), Color(0xFFD5945F)], // tan
    [Color(0xFFCF9264), Color(0xFFB4743F)], // warm
    [Color(0xFFA97247), Color(0xFF8A5730)], // deep
  ];

  static const _ink = Color(0xFF2C2420);
  static const _garment = Color(0xFF322C3A);

  int get _face => avatar.faceIndex % _skins.length;
  int get _eyes => avatar.eyeIndex % 5;
  int get _mouth => avatar.mouthIndex % 5;
  int get _acc => avatar.accessoryIndex % 5;
  int get _bg => avatar.backgroundIndex % backgrounds.length;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    double u(double v) => v * s;

    if (drawBackground) {
      final bg = backgrounds[_bg];
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.0,
            colors: [bg[0], bg[1]],
          ).createShader(Offset.zero & size),
      );
    }

    // Shoulders / collar (geometric base)
    canvas.drawPath(
      Path()
        ..moveTo(u(0.12), u(1.05))
        ..lineTo(u(0.3), u(0.86))
        ..lineTo(u(0.7), u(0.86))
        ..lineTo(u(0.88), u(1.05))
        ..close(),
      Paint()..color = _garment,
    );

    _drawHead(canvas, s, p, u);
    _drawEyes(canvas, s, p, u);
    _drawMouth(canvas, s, p, u);
    _drawAccessory(canvas, s, p, u);
  }

  // ── head (geometric) ────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    final skin = _skins[_face];
    final c = p(0.5, 0.5);
    final path = _headPath(c, u);

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin[0], skin[1]],
        ).createShader(path.getBounds()),
    );
    // Soft directional facet shading (lit from upper-left) for MV volume.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Offset.zero & Size(s, s),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & Size(s, s)),
    );
    canvas.restore();
  }

  Path _headPath(Offset c, double Function(double) u) {
    switch (_face) {
      case 1: // rounded square
        return Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: u(0.6), height: u(0.62)),
              Radius.circular(u(0.14))));
      case 2: // shield (flat top, chin point)
        final w = u(0.62), h = u(0.66);
        return Path()
          ..moveTo(c.dx - w * 0.5, c.dy - h * 0.42)
          ..lineTo(c.dx + w * 0.5, c.dy - h * 0.42)
          ..lineTo(c.dx + w * 0.5, c.dy + h * 0.05)
          ..lineTo(c.dx, c.dy + h * 0.55)
          ..lineTo(c.dx - w * 0.5, c.dy + h * 0.05)
          ..close();
      case 3: // octagon
        return _poly(c, 8, u(0.32), u(0.34), math.pi / 8);
      case 4: // diamond (soft, tall)
        return _poly(c, 4, u(0.31), u(0.38), 0);
      default: // hexagon (flat-top)
        return _poly(c, 6, u(0.31), u(0.34), 0);
    }
  }

  Path _poly(Offset c, int sides, double rx, double ry, double rot) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final a = rot + i * 2 * math.pi / sides;
      final pt = Offset(c.dx + rx * math.cos(a), c.dy + ry * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  // ── eyes ──────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    final ink = Paint()..color = _ink;
    const lx = 0.385, rx = 0.615, y = 0.5;
    switch (_eyes) {
      case 1: // happy closed ^ ^
        final stroke = Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(0.022)
          ..strokeCap = StrokeCap.round;
        for (final x in [lx, rx]) {
          canvas.drawPath(
            Path()
              ..moveTo(u(x - 0.045), u(y + 0.01))
              ..quadraticBezierTo(u(x), u(y - 0.05), u(x + 0.045), u(y + 0.01)),
            stroke,
          );
        }
        break;
      case 2: // wide ovals
        for (final x in [lx, rx]) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: p(x, y), width: u(0.06), height: u(0.09)),
              ink);
        }
        break;
      case 3: // sleepy lines
        final stroke = Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(0.02)
          ..strokeCap = StrokeCap.round;
        for (final x in [lx, rx]) {
          canvas.drawLine(p(x - 0.045, y), p(x + 0.045, y), stroke);
        }
        break;
      case 4: // sparkle (dot + highlight)
        for (final x in [lx, rx]) {
          canvas.drawCircle(p(x, y), u(0.042), ink);
          canvas.drawCircle(
              p(x + 0.014, y - 0.014), u(0.013), Paint()..color = Colors.white);
        }
        break;
      default: // 0: dots
        for (final x in [lx, rx]) {
          canvas.drawCircle(p(x, y), u(0.032), ink);
        }
    }
  }

  // ── mouth ─────────────────────────────────────────────────────────────
  void _drawMouth(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    const mouthColor = Color(0xFFB56A5E);
    final stroke = Paint()
      ..color = mouthColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = u(0.024)
      ..strokeCap = StrokeCap.round;
    const y = 0.67;
    switch (_mouth) {
      case 1: // neutral line
        canvas.drawLine(p(0.46, y), p(0.54, y), stroke);
        break;
      case 2: // small o
        canvas.drawCircle(p(0.5, y), u(0.03), Paint()..color = mouthColor);
        break;
      case 3: // wide grin (filled)
        canvas.drawPath(
          Path()
            ..moveTo(u(0.42), u(y - 0.01))
            ..quadraticBezierTo(u(0.5), u(y + 0.075), u(0.58), u(y - 0.01))
            ..close(),
          Paint()..color = mouthColor,
        );
        break;
      case 4: // cat ω
        for (final dx in [-0.03, 0.03]) {
          canvas.drawPath(
            Path()
              ..moveTo(u(0.5 + dx - 0.03), u(y))
              ..quadraticBezierTo(
                  u(0.5 + dx), u(y + 0.035), u(0.5 + dx + 0.03), u(y)),
            stroke,
          );
        }
        break;
      default: // 0: smile
        canvas.drawPath(
          Path()
            ..moveTo(u(0.44), u(y - 0.01))
            ..quadraticBezierTo(u(0.5), u(y + 0.05), u(0.56), u(y - 0.01)),
          stroke,
        );
    }
  }

  // ── accessory ─────────────────────────────────────────────────────────
  void _drawAccessory(Canvas canvas, double s,
      Offset Function(double, double) p, double Function(double) u) {
    switch (_acc) {
      case 1: // round glasses
        final g = Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(0.016);
        canvas.drawCircle(p(0.385, 0.5), u(0.075), g);
        canvas.drawCircle(p(0.615, 0.5), u(0.075), g);
        canvas.drawLine(p(0.46, 0.5), p(0.54, 0.5), g);
        break;
      case 2: // sunglasses (filled)
        final g = Paint()..color = _ink;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.385, 0.5), width: u(0.16), height: u(0.11)),
                Radius.circular(u(0.05))),
            g);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.615, 0.5), width: u(0.16), height: u(0.11)),
                Radius.circular(u(0.05))),
            g);
        canvas.drawLine(
            p(0.465, 0.49),
            p(0.535, 0.49),
            Paint()
              ..color = _ink
              ..strokeWidth = u(0.02));
        break;
      case 3: // headphones
        final band = Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(0.03)
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
            Rect.fromCenter(center: p(0.5, 0.4), width: u(0.72), height: u(0.62)),
            math.pi, math.pi, false, band);
        final cup = Paint()..color = _ink;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.17, 0.5), width: u(0.1), height: u(0.16)),
                Radius.circular(u(0.04))),
            cup);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.83, 0.5), width: u(0.1), height: u(0.16)),
                Radius.circular(u(0.04))),
            cup);
        break;
      case 4: // gold star mark
        _drawStar(canvas, p(0.72, 0.3), u(0.05),
            Paint()..color = const Color(0xFFFFD86B));
        break;
      default:
        break; // 0: none
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MinimalAvatarPainter old) =>
      old.avatar.faceIndex != avatar.faceIndex ||
      old.avatar.eyeIndex != avatar.eyeIndex ||
      old.avatar.mouthIndex != avatar.mouthIndex ||
      old.avatar.accessoryIndex != avatar.accessoryIndex ||
      old.avatar.backgroundIndex != avatar.backgroundIndex ||
      old.drawBackground != drawBackground;
}
