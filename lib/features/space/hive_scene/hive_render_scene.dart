import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'scene_models.dart';

/// Clean "hive" home: thin gold-outline octagon rooms holding an icon (game /
/// movie / music) and a global-chat bubble cluster, over a dark starfield.
/// Each region is tappable — [onRoomTap] receives the rooms-list index
/// (game 0 / movie 1 / music 3) and [onGlobalChatTap] fires for the cluster.
///
/// Room icons use image assets (transparent PNGs at the paths in
/// [_iconAsset]); if a file is missing the hand-drawn line-art is shown.
class HiveRenderScene extends ConsumerWidget {
  final List<SceneRoom> rooms;
  final void Function(int roomIndex)? onRoomTap;
  final VoidCallback? onGlobalChatTap;

  const HiveRenderScene({
    super.key,
    required this.rooms,
    this.onRoomTap,
    this.onGlobalChatTap,
  });

  static const _iconAsset = <int, String>{
    0: 'assets/images/decorations/hive_game.png',
    1: 'assets/images/decorations/hive_movie.png',
    2: 'assets/images/decorations/hive_music.png',
  };

  int _count(int i, int fallback) =>
      (i >= 0 && i < rooms.length) ? rooms[i].onlineCount : fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Offset px(double x, double y) =>
            Offset(x * size.width, y * size.height);
        final r = 0.185 * size.width;
        final cr = 0.27 * size.width;

        final game = px(0.27, 0.18);
        final movie = px(0.73, 0.18);
        final music = px(0.5, 0.42);
        final chat = px(0.5, 0.79);

        // 世界频道人数 = 各房间在线人数之和（无房间数据时兜底 12）
        final globalCount = rooms.isEmpty
            ? 12
            : rooms.fold<int>(0, (s, room) => s + room.onlineCount);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScenePainter(
                    size: size, centers: [game, movie, music], r: r),
              ),
            ),

            // Room icons (image asset, line-art fallback)
            _icon(game, r, 0),
            _icon(movie, r, 1),
            _icon(music, r, 2),

            // Global chat bubble cluster
            _GlobalChat(center: chat, width: size.width),

            // Labels + count badges
            _label(game, r, ref.tr('space_room_game'), _count(0, 4)),
            _label(movie, r, ref.tr('space_room_movie'), _count(1, 4)),
            _label(music, r, ref.tr('space_room_music'), _count(3, 4)),
            _label(chat, 0.24 * size.width, ref.tr('space_global_chat'),
                globalCount),

            // Single tap layer with point-in-region resolution. Rooms win
            // over the chat cluster and the nearest octagon wins among
            // rooms, so overlapping rectangles (landscape / short windows)
            // can never steal each other's taps.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _resolveTap(
                  d.localPosition,
                  rooms: [(0, game), (1, movie), (3, music)],
                  r: r,
                  chat: chat,
                  cr: cr,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Maps a tap point to a region. Room indices follow the seeded rooms
  /// list: 0 game, 1 cinema, 3 music — matching the label counts.
  void _resolveTap(
    Offset p, {
    required List<(int, Offset)> rooms,
    required double r,
    required Offset chat,
    required double cr,
  }) {
    // 1) Octagon bodies — nearest center within the octagon's radius wins.
    int? best;
    var bestDist = double.infinity;
    for (final (index, c) in rooms) {
      final d = (p - c).distance;
      if (d <= r * 1.05 && d < bestDist) {
        best = index;
        bestDist = d;
      }
    }
    if (best != null) {
      onRoomTap?.call(best);
      return;
    }
    // 2) Label rows (200px wide, 34px tall, right under each octagon).
    for (final (index, c) in rooms) {
      if ((p.dx - c.dx).abs() <= 100 &&
          p.dy >= c.dy + r &&
          p.dy <= c.dy + r + 34) {
        onRoomTap?.call(index);
        return;
      }
    }
    // 3) Global chat cluster + its label.
    if ((p.dx - chat.dx).abs() <= 1.1 * cr &&
        p.dy >= chat.dy - 0.9 * cr &&
        p.dy <= chat.dy + cr + 40) {
      onGlobalChatTap?.call();
    }
  }

  Widget _icon(Offset c, double r, int kind) {
    final s = r * 1.35;
    return Positioned(
      left: c.dx - s / 2,
      top: c.dy - s / 2,
      width: s,
      height: s,
      child: Image.asset(
        _iconAsset[kind]!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            CustomPaint(painter: _IconPainter(kind)),
      ),
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
    final cr = 0.27 * width;
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
      padding: EdgeInsets.symmetric(horizontal: emoji ? 7 : 9, vertical: 5),
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
// Scene painter — starfield + octagon outlines
// ===========================================================================

class _ScenePainter extends CustomPainter {
  final Size size;
  final List<Offset> centers;
  final double r;

  _ScenePainter({required this.size, required this.centers, required this.r});

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
    for (final c in centers) {
      _octagonRoom(canvas, c);
    }
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

  void _octagonRoom(Canvas canvas, Offset c) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 8 + i * math.pi / 4;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
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
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) => old.size != size;
}

// ===========================================================================
// Line-art icon fallback (used until image assets are supplied)
// ===========================================================================

class _IconPainter extends CustomPainter {
  final int kind; // 0 game, 1 movie, 2 music
  const _IconPainter(this.kind);

  static const _goldBright = Color(0xFFF0C56A);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final k = size.width * 0.42;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _goldBright;
    switch (kind) {
      case 1:
        _movie(canvas, c, k, line);
        break;
      case 2:
        _music(canvas, c, k, line);
        break;
      default:
        _joystick(canvas, c, k, line);
    }
  }

  void _joystick(Canvas canvas, Offset c, double k, Paint line) {
    final top = Path()
      ..moveTo(c.dx - 0.55 * k, c.dy + 0.35 * k)
      ..lineTo(c.dx, c.dy + 0.12 * k)
      ..lineTo(c.dx + 0.55 * k, c.dy + 0.35 * k)
      ..lineTo(c.dx, c.dy + 0.58 * k)
      ..close();
    canvas.drawPath(top, line);
    canvas.drawLine(c.translate(-0.55 * k, 0.35 * k),
        c.translate(-0.55 * k, 0.5 * k), line);
    canvas.drawLine(c.translate(0, 0.58 * k), c.translate(0, 0.73 * k), line);
    canvas.drawLine(c.translate(0.55 * k, 0.35 * k),
        c.translate(0.55 * k, 0.5 * k), line);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 0.55 * k, c.dy + 0.5 * k)
        ..lineTo(c.dx, c.dy + 0.73 * k)
        ..lineTo(c.dx + 0.55 * k, c.dy + 0.5 * k),
      line,
    );
    canvas.drawLine(
        c.translate(-0.02 * k, 0.32 * k), c.translate(-0.1 * k, -0.4 * k), line);
    canvas.drawCircle(c.translate(-0.12 * k, -0.52 * k), 0.14 * k, line);
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

  void _movie(Canvas canvas, Offset c, double k, Paint line) {
    final bc = c.translate(-0.32 * k, 0.12 * k);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: bc, width: 0.9 * k, height: 0.6 * k),
            Radius.circular(0.05 * k)),
        line);
    canvas.drawPath(
      Path()
        ..moveTo(bc.dx - 0.45 * k, bc.dy - 0.3 * k)
        ..lineTo(bc.dx + 0.45 * k, bc.dy - 0.42 * k)
        ..lineTo(bc.dx + 0.45 * k, bc.dy - 0.24 * k)
        ..lineTo(bc.dx - 0.45 * k, bc.dy - 0.12 * k)
        ..close(),
      line,
    );
    for (var i = 0; i < 3; i++) {
      final t = -0.3 + i * 0.28;
      canvas.drawLine(bc.translate(t * k, -0.3 * k),
          bc.translate((t + 0.08) * k, -0.16 * k), line);
    }
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

  void _music(Canvas canvas, Offset c, double k, Paint line) {
    final hc = c.translate(-0.12 * k, 0.05 * k);
    canvas.drawArc(
        Rect.fromCenter(center: hc, width: 0.9 * k, height: 0.85 * k),
        math.pi,
        math.pi,
        false,
        line);
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
        nc.translate(-0.03 * k, -0.28 * k),
        nc.translate(0.33 * k, -0.38 * k),
        line..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.kind != kind;
}
