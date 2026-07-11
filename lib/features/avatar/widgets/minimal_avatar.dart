import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/models/virtual_avatar.dart';

/// Minimalist, Monument-Valley-inspired procedural avatar: flat geometric
/// shapes, soft gradients, warm palette. Fully composed from the avatar's
/// part indices, so every customization choice is reflected live.
///
/// Option counts (indices are taken modulo these): face 5, hair 4, eyes 5,
/// mouth 5, accessory 5, background 5.
class MinimalAvatarPainter extends CustomPainter {
  final VirtualAvatar avatar;

  /// When false, the background gradient is skipped (transparent) — used for
  /// compositing over an existing backdrop.
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

  static const _hairColor = Color(0xFF3E2A1E);
  static const _hairHi = Color(0xFF5A3E2C);
  static const _ink = Color(0xFF2C2420);
  static const _garment = Color(0xFF322C3A);

  int get _face => avatar.faceIndex % _skins.length;
  int get _hair => avatar.hairIndex % 4;
  int get _eyes => avatar.eyeIndex % 5;
  int get _mouth => avatar.mouthIndex % 5;
  int get _acc => avatar.accessoryIndex % 5;
  int get _bg => avatar.backgroundIndex % backgrounds.length;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    double u(double v) => v * s;

    // Background
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

    // Shoulders / collar (simple portrait base)
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCenter(
            center: p(0.5, 1.18), width: u(1.15), height: u(0.9))),
      Paint()..color = _garment,
    );

    // Hair volume behind the head (bob), then head, then front hair.
    if (_hair == 3) {
      canvas.drawPath(
        Path()
          ..addOval(Rect.fromCenter(
              center: p(0.5, 0.46), width: u(0.8), height: u(0.76))),
        Paint()..color = _hairColor,
      );
    }
    _drawHead(canvas, s, p, u);
    _drawHair(canvas, s, p, u);
    _drawEyes(canvas, s, p, u);
    _drawMouth(canvas, s, p, u);
    _drawAccessory(canvas, s, p, u);
  }

  // ── head ──────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    final skin = _skins[_face];
    final center = p(0.5, 0.5);
    // shape by face index
    late final Path path;
    switch (_face) {
      case 1: // oval tall
        path = Path()
          ..addOval(Rect.fromCenter(
              center: center, width: u(0.56), height: u(0.66)));
        break;
      case 2: // oval wide
        path = Path()
          ..addOval(Rect.fromCenter(
              center: center, width: u(0.66), height: u(0.56)));
        break;
      case 3: // squircle
        path = Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: center, width: u(0.6), height: u(0.62)),
              Radius.circular(u(0.22))));
        break;
      case 4: // tapered chin
        path = _taperedFace(center, u(0.62), u(0.66));
        break;
      default: // round
        path = Path()
          ..addOval(Rect.fromCenter(
              center: center, width: u(0.6), height: u(0.6)));
    }

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin[0], skin[1]],
        ).createShader(path.getBounds()),
    );
    // ears
    final earPaint = Paint()..color = skin[1];
    canvas.drawCircle(p(0.22, 0.52), u(0.055), earPaint);
    canvas.drawCircle(p(0.78, 0.52), u(0.055), earPaint);
  }

  Path _taperedFace(Offset c, double w, double h) {
    final hw = w / 2, hh = h / 2;
    return Path()
      ..moveTo(c.dx - hw * 0.92, c.dy - hh * 0.35)
      ..cubicTo(c.dx - hw, c.dy - hh, c.dx + hw, c.dy - hh,
          c.dx + hw * 0.92, c.dy - hh * 0.35)
      ..cubicTo(c.dx + hw * 0.8, c.dy + hh * 0.5, c.dx + hw * 0.35,
          c.dy + hh, c.dx, c.dy + hh)
      ..cubicTo(c.dx - hw * 0.35, c.dy + hh, c.dx - hw * 0.8,
          c.dy + hh * 0.5, c.dx - hw * 0.92, c.dy - hh * 0.35)
      ..close();
  }

  // ── hair ──────────────────────────────────────────────────────────────
  void _drawHair(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    final paint = Paint()..color = _hairColor;
    final hi = Paint()..color = _hairHi;
    switch (_hair) {
      case 1: // side-swept fringe
        canvas.drawPath(
          Path()
            ..moveTo(u(0.24), u(0.44))
            ..cubicTo(u(0.24), u(0.18), u(0.78), u(0.14), u(0.78), u(0.42))
            ..cubicTo(u(0.66), u(0.3), u(0.5), u(0.34), u(0.42), u(0.42))
            ..cubicTo(u(0.4), u(0.34), u(0.32), u(0.34), u(0.24), u(0.44))
            ..close(),
          paint,
        );
        break;
      case 2: // short spiky
        canvas.drawPath(
          Path()
            ..moveTo(u(0.24), u(0.47))
            ..cubicTo(u(0.2), u(0.22), u(0.8), u(0.22), u(0.76), u(0.47))
            ..cubicTo(u(0.68), u(0.35), u(0.32), u(0.35), u(0.24), u(0.47))
            ..close(),
          paint,
        );
        for (var i = 0; i < 6; i++) {
          final x = 0.3 + i * 0.08;
          canvas.drawPath(
            Path()
              ..moveTo(u(x), u(0.25))
              ..lineTo(u(x + 0.028), u(0.16))
              ..lineTo(u(x + 0.056), u(0.25))
              ..close(),
            paint,
          );
        }
        break;
      case 3: // rounded bob — front cap over the forehead (volume drawn behind)
        canvas.drawPath(
          Path()
            ..moveTo(u(0.22), u(0.5))
            ..cubicTo(u(0.18), u(0.16), u(0.82), u(0.16), u(0.78), u(0.5))
            ..cubicTo(u(0.7), u(0.34), u(0.3), u(0.34), u(0.22), u(0.5))
            ..close(),
          paint,
        );
        break;
      default: // 0: smooth cap
        canvas.drawPath(
          Path()
            ..moveTo(u(0.2), u(0.5))
            ..cubicTo(u(0.16), u(0.14), u(0.84), u(0.14), u(0.8), u(0.5))
            ..cubicTo(u(0.72), u(0.32), u(0.28), u(0.32), u(0.2), u(0.5))
            ..close(),
          paint,
        );
    }
    // soft highlight strand
    if (_hair != 3) {
      canvas.drawPath(
        Path()
          ..moveTo(u(0.4), u(0.24))
          ..quadraticBezierTo(u(0.52), u(0.19), u(0.64), u(0.25)),
        hi
          ..style = PaintingStyle.stroke
          ..strokeWidth = u(0.02)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── eyes ──────────────────────────────────────────────────────────────
  void _drawEyes(Canvas canvas, double s, Offset Function(double, double) p,
      double Function(double) u) {
    final ink = Paint()..color = _ink;
    final lx = 0.385, rx = 0.615, y = 0.54;
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
    const y = 0.7;
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
        canvas.drawCircle(p(0.385, 0.54), u(0.075), g);
        canvas.drawCircle(p(0.615, 0.54), u(0.075), g);
        canvas.drawLine(p(0.46, 0.54), p(0.54, 0.54), g);
        break;
      case 2: // sunglasses (filled)
        final g = Paint()..color = _ink;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.385, 0.54), width: u(0.16), height: u(0.11)),
                Radius.circular(u(0.05))),
            g);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.615, 0.54), width: u(0.16), height: u(0.11)),
                Radius.circular(u(0.05))),
            g);
        canvas.drawLine(
            p(0.465, 0.53),
            p(0.535, 0.53),
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
            Rect.fromCenter(center: p(0.5, 0.42), width: u(0.7), height: u(0.6)),
            math.pi, math.pi, false, band);
        final cup = Paint()..color = _ink;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.19, 0.52), width: u(0.1), height: u(0.16)),
                Radius.circular(u(0.04))),
            cup);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p(0.81, 0.52), width: u(0.1), height: u(0.16)),
                Radius.circular(u(0.04))),
            cup);
        break;
      case 4: // gold star mark
        _drawStar(canvas, p(0.74, 0.36), u(0.05),
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
      old.avatar.hairIndex != avatar.hairIndex ||
      old.avatar.eyeIndex != avatar.eyeIndex ||
      old.avatar.mouthIndex != avatar.mouthIndex ||
      old.avatar.accessoryIndex != avatar.accessoryIndex ||
      old.avatar.backgroundIndex != avatar.backgroundIndex ||
      old.drawBackground != drawBackground;
}
