import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'scene_models.dart';

/// Art-directed isometric "hive" home scene: gold-rimmed hexagonal cutaway
/// rooms (theater, game corner, music bar, chat atriums) linked by golden
/// ladders, over a dark warm-glow backdrop. Approximates the reference render
/// with CustomPaint (no external art). Static — like the reference — so it
/// paints once and stays cheap.
class HiveRenderScene extends StatelessWidget {
  final List<SceneRoom> rooms;
  final void Function(int roomIndex) onEnterRoom;
  final VoidCallback? onSwitchToMap;

  const HiveRenderScene({
    super.key,
    required this.rooms,
    required this.onEnterRoom,
    this.onSwitchToMap,
  });

  int _online(int enterIndex) {
    if (enterIndex >= 0 && enterIndex < rooms.length) {
      return rooms[enterIndex].onlineCount;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Offset px(Offset frac) =>
            Offset(frac.dx * size.width, frac.dy * size.height);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Scene art
            Positioned.fill(
              child: CustomPaint(painter: _ScenePainter(size)),
            ),

            // Tappable room hotspots
            for (final r in _rooms)
              _hotspot(px(r.center), r.radius * size.width,
                  () => onEnterRoom(r.enterIndex)),

            // Room labels with online badge (below the room body)
            for (final r in _rooms)
              if (r.label.isNotEmpty)
                _label(px(r.center), r.radius * size.width, r.label,
                    _online(r.enterIndex),
                    r.kind == _RoomKind.atrium ? 1.0 : 1.6),

            // Floating hex icon badges above rooms
            ..._badgePlacements(size, px),

            // Minimal map access (top-right), styled as a floating hex chip
            if (onSwitchToMap != null)
              Positioned(
                top: 8,
                right: 16,
                child: _HexButton(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  onTap: onSwitchToMap!,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _hotspot(Offset c, double r, VoidCallback onTap) {
    return Positioned(
      left: c.dx - r,
      top: c.dy - r,
      width: r * 2,
      height: r * 2,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap),
    );
  }

  Widget _label(Offset c, double r, String text, int online, double yFactor) {
    return Positioned(
      left: c.dx - r * 1.4,
      top: c.dy + r * yFactor,
      width: r * 2.8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.tt(
                size: 13,
                weight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ).copyWith(shadows: const [
                Shadow(color: Colors.black87, blurRadius: 6),
              ]),
            ),
          ),
          const SizedBox(width: 6),
          _CountHexBadge(online),
        ],
      ),
    );
  }

  List<Widget> _badgePlacements(Size size, Offset Function(Offset) px) {
    final theater = px(const Offset(0.5, 0.17));
    final tR = 0.205 * size.width;
    final game = px(const Offset(0.29, 0.40));
    final music = px(const Offset(0.71, 0.40));
    final gR = 0.165 * size.width;
    return [
      _floatBadge(theater + Offset(tR * 0.95, -tR * 0.75), Icons.movie_creation),
      _floatBadge(theater + Offset(tR * 0.05, -tR * 1.15), Icons.play_arrow_rounded),
      _floatBadge(game + Offset(-gR * 1.05, -gR * 0.95), Icons.play_arrow_rounded),
      _floatBadge(music + Offset(gR * 1.05, -gR * 0.95), Icons.sports_esports),
    ];
  }

  Widget _floatBadge(Offset c, IconData icon) {
    const s = 34.0;
    return Positioned(
      left: c.dx - s / 2,
      top: c.dy - s / 2,
      child: _HexBadge(icon: icon, size: s),
    );
  }
}

/// Fixed room layout (fractions of the canvas). `enterIndex` maps to the
/// provider's room list so tapping still opens the matching interior.
class _RoomSpec {
  final String label;
  final int enterIndex;
  final _RoomKind kind;
  final Offset center; // fraction of (w, h)
  final double radius; // fraction of w
  final IconData icon;

  const _RoomSpec(this.label, this.enterIndex, this.kind, this.center,
      this.radius, this.icon);
}

enum _RoomKind { theater, game, music, atrium }

const _rooms = <_RoomSpec>[
  _RoomSpec('', 1, _RoomKind.theater, Offset(0.5, 0.17), 0.205, Icons.movie),
  _RoomSpec('GAME CORNER', 0, _RoomKind.game, Offset(0.29, 0.40), 0.165,
      Icons.sports_esports),
  _RoomSpec('MUSIC BAR', 3, _RoomKind.music, Offset(0.71, 0.40), 0.165,
      Icons.music_note),
  _RoomSpec('CHAT ATRIUM', 2, _RoomKind.atrium, Offset(0.28, 0.72), 0.15,
      Icons.chat_bubble),
  _RoomSpec('CHAT ATRIUM', 2, _RoomKind.atrium, Offset(0.72, 0.73), 0.15,
      Icons.chat_bubble),
];

// ===========================================================================
// Small overlay widgets
// ===========================================================================

class _CountHexBadge extends StatelessWidget {
  final int count;
  const _CountHexBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD98A), Color(0xFFE0951F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 99 ? '99' : '$count',
        style: AppTextStyles.tt(
          size: 10,
          weight: FontWeight.w700,
          color: AppColors.ctaText,
        ),
      ),
    );
  }
}

class _HexBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  const _HexBadge({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexBadgePainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(icon, size: size * 0.5, color: AppColors.ctaText),
      ),
    );
  }
}

class _HexBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path =
        _flatHexPath(Offset(size.width / 2, size.height / 2), size.width / 2);
    canvas.drawShadow(path, Colors.black, 4, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE29A), Color(0xFFE0951F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFF3C8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HexButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.chipSurface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(200),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: AppColors.neonYellow),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyles.tt(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.neonYellow)),
        ]),
      ),
    );
  }
}

// ===========================================================================
// Scene painter (static)
// ===========================================================================

Path _flatHexPath(Offset c, double r, {double sy = 1.0}) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final a = math.pi / 180 * (60 * i);
    final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a) * sy);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  path.close();
  return path;
}

/// Isometric-squashed hexagon vertices (pointy left/right). Index 0 = right,
/// 1 = lower-right, 2 = lower-left, 3 = left, 4 = upper-left, 5 = upper-right.
List<Offset> _hexVerts(Offset c, double r, double sy) {
  return List.generate(6, (i) {
    final a = math.pi / 180 * (60 * i);
    return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a) * sy);
  });
}

class _ScenePainter extends CustomPainter {
  final Size size;
  _ScenePainter(this.size);

  static const _rim = Color(0xFFFFE29A);
  static const _gold = Color(0xFFE0A62E);
  static const _goldDark = Color(0xFF7A5216);
  static const _wallTop = Color(0xFF5A441A);
  static const _wallBot = Color(0xFF1B1207);
  static const _floor = Color(0xFF2E220E);

  @override
  void paint(Canvas canvas, Size s) {
    _drawBackground(canvas, s);
    _drawSparkles(canvas, s);

    Offset px(Offset f) => Offset(f.dx * s.width, f.dy * s.height);

    // Connecting structure behind the rooms.
    _drawLadder(canvas, px(const Offset(0.5, 0.30)), px(const Offset(0.5, 0.40)));
    _drawLadder(canvas, px(const Offset(0.5, 0.47)), px(const Offset(0.5, 0.66)));
    _drawBridge(canvas, px(const Offset(0.29, 0.44)), px(const Offset(0.5, 0.52)));
    _drawBridge(canvas, px(const Offset(0.71, 0.44)), px(const Offset(0.5, 0.52)));
    _drawBridge(canvas, px(const Offset(0.28, 0.72)), px(const Offset(0.5, 0.66)));
    _drawBridge(canvas, px(const Offset(0.72, 0.73)), px(const Offset(0.5, 0.66)));

    // Rooms, back-to-front (theater = furthest/highest).
    for (final r in _rooms) {
      final c = px(r.center);
      final rad = r.radius * s.width;
      switch (r.kind) {
        case _RoomKind.theater:
          _drawRoom(canvas, c, rad, rad * 0.95, _drawTheaterInterior);
          break;
        case _RoomKind.game:
          _drawRoom(canvas, c, rad, rad * 0.9, _drawGameInterior);
          break;
        case _RoomKind.music:
          _drawRoom(canvas, c, rad, rad * 0.9, _drawMusicInterior);
          break;
        case _RoomKind.atrium:
          _drawAtrium(canvas, c, rad);
          break;
      }
    }
  }

  // ---- backdrop ----
  void _drawBackground(Canvas canvas, Size s) {
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.1,
          colors: [Color(0xFF241703), Color(0xFF0B0803), Color(0xFF050403)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & s),
    );
  }

  void _drawSparkles(Canvas canvas, Size s) {
    final rnd = math.Random(7);
    final paint = Paint();
    for (var i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = rnd.nextDouble() * s.height;
      final r = 0.6 + rnd.nextDouble() * 1.6;
      paint.color = _rim.withValues(alpha: 0.15 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  // ---- connectors ----
  void _drawLadder(Canvas canvas, Offset a, Offset b) {
    final dir = b - a;
    final len = dir.distance;
    if (len < 1) return;
    final n = dir / len;
    final perp = Offset(-n.dy, n.dx);
    const w = 9.0;
    final rail = Paint()
      ..color = _gold.withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a + perp * w, b + perp * w, rail);
    canvas.drawLine(a - perp * w, b - perp * w, rail);
    final rung = Paint()
      ..color = _rim.withValues(alpha: 0.75)
      ..strokeWidth = 2;
    final steps = (len / 12).floor();
    for (var i = 1; i < steps; i++) {
      final p = a + n * (len * i / steps);
      canvas.drawLine(p + perp * w, p - perp * w, rung);
    }
  }

  void _drawBridge(Canvas canvas, Offset a, Offset b) {
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _goldDark.withValues(alpha: 0.7)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _gold.withValues(alpha: 0.55)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }

  // ---- rooms ----
  /// A gold-rimmed hexagonal cutaway room: interior back walls + floor +
  /// props, open at the front, with a bright gold top rim.
  void _drawRoom(Canvas canvas, Offset c, double r, double depth,
      void Function(Canvas, Offset, double) interior) {
    const sy = 0.56;
    final top = _hexVerts(c, r, sy);
    final floorC = c + Offset(0, depth);
    final bot = _hexVerts(floorC, r, sy);

    // Base shadow
    canvas.drawPath(
      _flatHexPath(floorC + const Offset(0, 6), r * 1.02, sy: sy),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Back interior walls: upper-back faces 3-4, 4-5, 5-0.
    void wall(int i, int j) {
      final path = Path()
        ..moveTo(top[i].dx, top[i].dy)
        ..lineTo(top[j].dx, top[j].dy)
        ..lineTo(bot[j].dx, bot[j].dy)
        ..lineTo(bot[i].dx, bot[i].dy)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_wallTop, _wallBot],
          ).createShader(Rect.fromPoints(top[i], bot[j])),
      );
    }

    wall(3, 4);
    wall(4, 5);
    wall(5, 0);

    // Floor
    canvas.drawPath(
      _flatHexPath(floorC, r, sy: sy),
      Paint()
        ..shader = RadialGradient(
          colors: [_floor, const Color(0xFF0E0A03)],
        ).createShader(Rect.fromCircle(center: floorC, radius: r)),
    );

    // Warm interior glow
    final glowC = Offset(c.dx, c.dy + depth * 0.4);
    canvas.drawCircle(
      glowC,
      r * 0.9,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.glowOrange.withValues(alpha: 0.28),
          AppColors.glowOrange.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowC, radius: r * 0.9)),
    );

    // Interior props
    interior(canvas, floorC, r);

    // Vertical gold edges on the back corners
    final edge = Paint()
      ..color = _gold
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final i in [3, 4, 5, 0]) {
      canvas.drawLine(top[i], bot[i], edge);
    }

    // Floor outline
    canvas.drawPath(
      _flatHexPath(floorC, r, sy: sy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = _gold.withValues(alpha: 0.8),
    );

    // Solid gold frame ring around the opening (interior shows through the
    // inner hole), giving the room a substantial, forged-gold rim.
    final outer = _flatHexPath(c, r, sy: sy);
    final inner = _flatHexPath(c, r * 0.82, sy: sy);
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = _rim.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    final frame = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE7A8), Color(0xFFB9821F)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _rim,
    );
    canvas.drawPath(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _goldDark,
    );
  }

  /// Flat open hexagon platform with seated chat characters + bubbles.
  void _drawAtrium(Canvas canvas, Offset c, double r) {
    const sy = 0.56;
    const depth = 16.0;
    final floorC = c + const Offset(0, depth);

    final top = _hexVerts(c, r, sy);
    final bot = _hexVerts(floorC, r, sy);
    void band(int i, int j) {
      final path = Path()
        ..moveTo(top[i].dx, top[i].dy)
        ..lineTo(top[j].dx, top[j].dy)
        ..lineTo(bot[j].dx, bot[j].dy)
        ..lineTo(bot[i].dx, bot[i].dy)
        ..close();
      canvas.drawPath(path, Paint()..color = _goldDark);
    }

    band(0, 1);
    band(1, 2);
    band(2, 3);

    // top platform
    canvas.drawPath(
      _flatHexPath(c, r, sy: sy),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF2A1E0A), Color(0xFF171004)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r * 0.55,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.glowOrange.withValues(alpha: 0.35),
          AppColors.glowOrange.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r * 0.55)),
    );
    canvas.drawPath(
      _flatHexPath(c, r, sy: sy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = _rim,
    );

    final seats = [
      c + Offset(-r * 0.45, -r * 0.05),
      c + Offset(r * 0.4, -r * 0.12),
      c + Offset(-r * 0.05, r * 0.18),
    ];
    for (final seat in seats) {
      _drawDesk(canvas, seat, r * 0.16);
      _drawCharacter(canvas, seat + Offset(0, -r * 0.06), r * 0.14);
      _drawBubble(canvas, seat + Offset(r * 0.12, -r * 0.34), r * 0.12);
    }
  }

  // ---- interiors ----
  void _drawTheaterInterior(Canvas canvas, Offset floorC, double r) {
    final screenRect = Rect.fromCenter(
      center: floorC + Offset(0, -r * 0.7),
      width: r * 1.15,
      height: r * 0.62,
    );
    canvas.drawRect(
      screenRect.inflate(8),
      Paint()
        ..color = const Color(0xFF5B8BE0).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B3A6B), Color(0xFF0B1830)],
        ).createShader(screenRect),
    );
    final mtn = Path()
      ..moveTo(screenRect.left + 6, screenRect.bottom - 4)
      ..lineTo(screenRect.center.dx - 6, screenRect.center.dy)
      ..lineTo(screenRect.center.dx + 4, screenRect.bottom - 10)
      ..lineTo(screenRect.right - 6, screenRect.center.dy + 4)
      ..lineTo(screenRect.right - 6, screenRect.bottom - 4)
      ..close();
    canvas.drawPath(mtn, Paint()..color = const Color(0xFF25507F));
    canvas.drawRRect(
      RRect.fromRectAndRadius(screenRect, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF6FA8FF).withValues(alpha: 0.8),
    );
    final seatPaint = Paint()..color = const Color(0xFF1A140A);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        final p =
            floorC + Offset((col - 1) * r * 0.34, r * 0.08 + row * r * 0.22);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: r * 0.2, height: r * 0.16),
            const Radius.circular(3),
          ),
          seatPaint,
        );
      }
    }
  }

  void _drawGameInterior(Canvas canvas, Offset floorC, double r) {
    for (final side in [-1.0, 1.0]) {
      final rect = Rect.fromCenter(
        center: floorC + Offset(side * r * 0.5, -r * 0.55),
        width: r * 0.5,
        height: r * 0.36,
      );
      canvas.drawRect(
        rect.inflate(4),
        Paint()
          ..color = AppColors.glowOrange.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF6CE78), Color(0xFFC2801C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: rect.center, width: r * 0.24, height: r * 0.12),
          const Radius.circular(6),
        ),
        Paint()..color = AppColors.ctaText.withValues(alpha: 0.55),
      );
    }
    _drawCharacter(canvas, floorC + Offset(0, -r * 0.05), r * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: floorC + Offset(0, r * 0.22),
            width: r * 0.34,
            height: r * 0.12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF2C2110),
    );
  }

  void _drawMusicInterior(Canvas canvas, Offset floorC, double r) {
    final barPaint = Paint()..color = _rim.withValues(alpha: 0.85);
    for (var i = 0; i < 9; i++) {
      final x = floorC.dx + (i - 4) * r * 0.16;
      final h = r * (0.12 + 0.28 * (0.5 + 0.5 * math.sin(i * 1.3)));
      final y = floorC.dy - r * 0.55;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: r * 0.06, height: h),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }
    final base = floorC + Offset(0, r * 0.05);
    canvas.drawOval(
      Rect.fromCenter(center: base, width: r * 0.6, height: r * 0.3),
      Paint()..color = const Color(0xFF120C05),
    );
    canvas.drawOval(
      Rect.fromCenter(center: base, width: r * 0.42, height: r * 0.21),
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF6E4A12), Color(0xFF1A1206)],
        ).createShader(Rect.fromCenter(
            center: base, width: r * 0.42, height: r * 0.21)),
    );
    canvas.drawCircle(base, r * 0.04, Paint()..color = _rim);
    canvas.drawCircle(
        floorC + Offset(r * 0.42, -r * 0.42), r * 0.05, Paint()..color = _rim);
  }

  // ---- little figures ----
  void _drawDesk(Canvas canvas, Offset c, double r) {
    final p = _flatHexPath(c + Offset(0, r * 0.5), r, sy: 0.5);
    canvas.drawPath(p, Paint()..color = const Color(0xFF2A1E0A));
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _gold.withValues(alpha: 0.6),
    );
  }

  void _drawCharacter(Canvas canvas, Offset c, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: c + Offset(0, r * 0.5), width: r * 1.1, height: r * 1.1),
        Radius.circular(r * 0.4),
      ),
      Paint()..color = const Color(0xFF161009),
    );
    canvas.drawCircle(c + Offset(0, -r * 0.25), r * 0.42,
        Paint()..color = const Color(0xFF2A2018));
    canvas.drawCircle(
      c + Offset(0, -r * 0.25),
      r * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _rim.withValues(alpha: 0.55),
    );
  }

  void _drawBubble(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(r * 0.4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE29A), Color(0xFFE0951F)],
        ).createShader(rect),
    );
    final tail = Path()
      ..moveTo(c.dx - r * 0.1, rect.bottom - 1)
      ..lineTo(c.dx - r * 0.35, rect.bottom + r * 0.35)
      ..lineTo(c.dx + r * 0.2, rect.bottom - 1)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xFFE0951F));
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(c.dx + i * r * 0.35, c.dy), r * 0.1,
          Paint()..color = AppColors.ctaText.withValues(alpha: 0.7));
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.size != size;
}
