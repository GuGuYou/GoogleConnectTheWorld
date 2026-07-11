import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'scene_models.dart';

/// Clean "hive" home: thin gold-outline octagon rooms with hand-drawn line-art
/// icons (game / movie / music) and a global-chat bubble cluster, over a dark
/// starfield. Static / visual only — tapping does not navigate.
class HiveRenderScene extends StatelessWidget {
  final List<SceneRoom> rooms;

  const HiveRenderScene({super.key, required this.rooms});

  int _count(int i, int fallback) =>
      (i >= 0 && i < rooms.length) ? rooms[i].onlineCount : fallback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Offset px(double x, double y) =>
            Offset(x * size.width, y * size.height);
        final r = 0.185 * size.width;

        final game = px(0.27, 0.18);
        final movie = px(0.73, 0.18);
        final music = px(0.5, 0.42);
        final chat = px(0.5, 0.79);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScenePainter(
                  size: size,
                  game: game,
                  movie: movie,
                  music: music,
                  r: r,
                ),
              ),
            ),

            // Global chat bubble cluster
            _GlobalChat(center: chat, width: size.width),

            // Labels + count badges
            _label(game, r, 'GAME CORNER', _count(0, 4)),
            _label(movie, r, 'MOVIE THEATER', _count(1, 4)),
            _label(music, r, 'MUSIC BAR', _count(3, 4)),
            _label(chat, 0.24 * size.width, 'GLOBAL CHAT', 12),
          ],
        );
      },
    );
  }

  Widget _label(Offset c, double r, String text, int count) {
    return Positioned(
      left: c.dx - 100,
      top: c.dy + r + 8,
      width: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.tt(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _CountBadge(count),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFFD98A), Color(0xFFE0951F)]),
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99' : '$count',
        style: AppTextStyles.tt(
            size: 10, weight: FontWeight.w700, color: AppColors.ctaText),
      ),
    );
  }
}

// ===========================================================================
// Global chat bubble cluster
// ===========================================================================

class _GlobalChat extends StatelessWidget {
  final Offset center;
  final double width;
  const _GlobalChat({required this.center, required this.width});

  // (dx, dy) as fractions of the cluster radius; text; filled?
  static const _bubbles = <(double, double, String, bool)>[
    (-0.5, -0.6, '你好', false),
    (-0.02, -0.72, 'HI', true),
    (0.45, -0.56, 'Hello', false),
    (-0.72, -0.2, '你好', true),
    (-0.28, -0.24, '英语', true),
    (0.14, -0.26, '😊', true),
    (0.6, -0.18, 'Bonjour', true),
    (-0.5, 0.18, 'Hola', false),
    (-0.06, 0.14, '😐', false),
    (0.34, 0.12, 'Hello', false),
    (0.7, 0.2, 'Ciao', true),
    (-0.28, 0.54, 'Konnichiwa', false),
    (0.26, 0.52, 'Bonjour', true),
    (0.66, 0.56, 'Privet', false),
  ];

  @override
  Widget build(BuildContext context) {
    final cr = 0.27 * width; // cluster radius
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final b in _bubbles)
          Positioned(
            left: center.dx + b.$1 * cr,
            top: center.dy + b.$2 * cr,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: _ChatBubble(text: b.$3, filled: b.$4),
            ),
          ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool filled;
  const _ChatBubble({required this.text, required this.filled});

  @override
  Widget build(BuildContext context) {
    final emoji = text.runes.length == 1 && text.codeUnitAt(0) > 0x2000;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: emoji ? 7 : 9, vertical: emoji ? 5 : 5),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFE7A83A) : const Color(0xFF161206),
        borderRadius: BorderRadius.circular(12),
        border: filled
            ? null
            : Border.all(color: AppColors.neonYellow.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: emoji
            ? const TextStyle(fontSize: 13)
            : AppTextStyles.tt(
                size: 11,
                weight: FontWeight.w700,
                color: filled ? AppColors.ctaText : AppColors.neonYellow,
              ),
      ),
    );
  }
}

// ===========================================================================
// Scene painter — starfield, octagon outlines, line-art icons
// ===========================================================================

class _ScenePainter extends CustomPainter {
  final Size size;
  final Offset game, movie, music;
  final double r;

  _ScenePainter({
    required this.size,
    required this.game,
    required this.movie,
    required this.music,
    required this.r,
  });

  static const _gold = Color(0xFFD9A63A);
  static const _goldBright = Color(0xFFF0C56A);

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0xFF1C1403), Color(0xFF0A0803), Color(0xFF050403)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & s),
    );
    _stars(canvas, s);

    _room(canvas, game, _drawJoystick);
    _room(canvas, movie, _drawMovie);
    _room(canvas, music, _drawHeadphones);
  }

  void _stars(Canvas canvas, Size s) {
    final rnd = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height);
      paint.color = _goldBright.withValues(alpha: 0.15 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(o, 0.5 + rnd.nextDouble() * 1.3, paint);
    }
  }

  // Outline octagon room + centered icon.
  void _room(Canvas canvas, Offset c, void Function(Canvas, Offset, double) icon) {
    final path = _octagon(c, r);
    // faint glow
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = _gold.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _gold.withValues(alpha: 0.85),
    );
    icon(canvas, c, r * 0.62);
  }

  Path _octagon(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  Paint get _line => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _goldBright;

  // ── icons ───────────────────────────────────────────────────────────────
  void _drawJoystick(Canvas canvas, Offset c, double k) {
    final line = _line;
    // isometric base (diamond top + depth)
    final top = Path()
      ..moveTo(c.dx - 0.55 * k, c.dy + 0.35 * k)
      ..lineTo(c.dx, c.dy + 0.12 * k)
      ..lineTo(c.dx + 0.55 * k, c.dy + 0.35 * k)
      ..lineTo(c.dx, c.dy + 0.58 * k)
      ..close();
    canvas.drawPath(top, line);
    // depth
    canvas.drawLine(c.translate(-0.55 * k, 0.35 * k),
        c.translate(-0.55 * k, 0.5 * k), line);
    canvas.drawLine(
        c.translate(0, 0.58 * k), c.translate(0, 0.73 * k), line);
    canvas.drawLine(c.translate(0.55 * k, 0.35 * k),
        c.translate(0.55 * k, 0.5 * k), line);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 0.55 * k, c.dy + 0.5 * k)
        ..lineTo(c.dx, c.dy + 0.73 * k)
        ..lineTo(c.dx + 0.55 * k, c.dy + 0.5 * k),
      line,
    );
    // stick + ball
    canvas.drawLine(
        c.translate(-0.02 * k, 0.32 * k), c.translate(-0.1 * k, -0.4 * k), line);
    canvas.drawCircle(c.translate(-0.12 * k, -0.52 * k), 0.14 * k, line);
    // buttons
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0.24 * k, 0.4 * k),
            width: 0.16 * k,
            height: 0.09 * k),
        line);
    canvas.drawOval(
        Rect.fromCenter(
            center: c.translate(0.36 * k, 0.46 * k),
            width: 0.16 * k,
            height: 0.09 * k),
        line);
  }

  void _drawMovie(Canvas canvas, Offset c, double k) {
    final line = _line;
    // clapperboard (left)
    final bc = c.translate(-0.32 * k, 0.12 * k);
    final board = RRect.fromRectAndRadius(
        Rect.fromCenter(center: bc, width: 0.9 * k, height: 0.6 * k),
        Radius.circular(0.05 * k));
    canvas.drawRRect(board, line);
    // clapper top bar
    final clapper = Path()
      ..moveTo(bc.dx - 0.45 * k, bc.dy - 0.3 * k)
      ..lineTo(bc.dx + 0.45 * k, bc.dy - 0.42 * k)
      ..lineTo(bc.dx + 0.45 * k, bc.dy - 0.24 * k)
      ..lineTo(bc.dx - 0.45 * k, bc.dy - 0.12 * k)
      ..close();
    canvas.drawPath(clapper, line);
    for (var i = 0; i < 3; i++) {
      final t = -0.3 + i * 0.28;
      canvas.drawLine(bc.translate(t * k, -0.3 * k),
          bc.translate((t + 0.08) * k, -0.16 * k), line);
    }
    // film reel (right)
    final rc = c.translate(0.34 * k, 0.16 * k);
    canvas.drawCircle(rc, 0.4 * k, line);
    canvas.drawCircle(rc, 0.12 * k, line);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      canvas.drawCircle(
          rc.translate(0.24 * k * math.cos(a), 0.24 * k * math.sin(a)),
          0.07 * k,
          line);
    }
  }

  void _drawHeadphones(Canvas canvas, Offset c, double k) {
    final line = _line;
    final hc = c.translate(-0.12 * k, 0.05 * k);
    // band
    canvas.drawArc(
        Rect.fromCenter(center: hc, width: 0.9 * k, height: 0.85 * k),
        math.pi,
        math.pi,
        false,
        line);
    // ear cups
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: hc.translate(side * 0.45 * k, 0.12 * k),
                  width: 0.2 * k,
                  height: 0.34 * k),
              Radius.circular(0.08 * k)),
          line);
    }
    // music note (upper-right, kept inside the octagon)
    final nc = c.translate(0.38 * k, -0.24 * k);
    canvas.drawOval(
        Rect.fromCenter(
            center: nc.translate(-0.12 * k, 0.34 * k),
            width: 0.2 * k,
            height: 0.15 * k),
        line);
    canvas.drawOval(
        Rect.fromCenter(
            center: nc.translate(0.24 * k, 0.24 * k),
            width: 0.2 * k,
            height: 0.15 * k),
        line);
    canvas.drawLine(nc.translate(-0.03 * k, 0.32 * k),
        nc.translate(-0.03 * k, -0.28 * k), line);
    canvas.drawLine(nc.translate(0.33 * k, 0.22 * k),
        nc.translate(0.33 * k, -0.38 * k), line);
    canvas.drawLine(
        nc.translate(-0.03 * k, -0.28 * k), nc.translate(0.33 * k, -0.38 * k),
        line..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.size != size;
}
