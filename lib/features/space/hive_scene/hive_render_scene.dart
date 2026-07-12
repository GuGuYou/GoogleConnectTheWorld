import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/gold_glow.dart';
import 'scene_models.dart';

/// Hive home per the Hive.svg redesign: a full-screen honeycomb of rounded
/// pointy-top hexagons — three opaque "active" room cells (solid-gold PNG
/// art + gold label, no count badges) over a lattice of 10%-opacity ghost
/// cells that dissolves into a gold-chrome glass chat panel at the bottom.
///
/// Regions are tappable — [onRoomTap] receives the rooms-list index
/// (game 0 / movie 1 / music 3) and [onGlobalChatTap] fires for the panel.
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

  // 设计稿（375×812，场景区 ≈ y100..726）折算的场景内相对坐标。
  static const _gameC = Offset(0.486, 0.153);
  static const _movieC = Offset(0.279, 0.368);
  static const _musicC = Offset(0.692, 0.368);
  static const _chatTop = 0.585; // 聊天面板顶部
  static const _chatHeight = 0.33;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        Offset px(Offset f) => Offset(f.dx * size.width, f.dy * size.height);
        final r = 0.222 * size.width; // 六边形中心→顶点

        final game = px(_gameC);
        final movie = px(_movieC);
        final music = px(_musicC);
        final chatRect = Rect.fromLTWH(
          0.043 * size.width,
          _chatTop * size.height,
          0.914 * size.width,
          _chatHeight * size.height,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // 蜂窝网格（活跃格 + 幽灵格）+ 星尘 + 底部渐隐
            Positioned.fill(
              child: CustomPaint(
                painter: _HoneycombPainter(
                  size: size,
                  actives: [game, movie, music],
                  r: r,
                  fadeTop: _chatTop - 0.09,
                ),
              ),
            ),

            // 房间插画（实心金 PNG；缺资源时回退绘制占位）
            _icon(game, r, 0, scale: 0.74, dy: -0.07),
            _icon(movie, r, 1, scale: 0.59, dy: 0),
            _icon(music, r, 2, scale: 0.70, dy: -0.25),

            // 房间标签（金色，位于六边形下部内侧；无计数徽章）
            _label(game, r, ref.tr('space_room_game')),
            _label(movie, r, ref.tr('space_room_movie')),
            _label(music, r, ref.tr('space_room_music')),

            // 附近聊天：金色描边玻璃面板 + 气泡
            Positioned.fromRect(
              rect: chatRect,
              child: _ChatPanel(title: ref.tr('space_local_chat')),
            ),

            // 单击层：房间优先（最近六边形），其次聊天面板
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _resolveTap(
                  d.localPosition,
                  rooms: [(0, game), (1, movie), (3, music)],
                  r: r,
                  chatRect: chatRect,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _icon(Offset c, double r, int kind,
      {required double scale, required double dy}) {
    final hexW = r * math.sqrt(3); // 六边形平边宽
    final s = hexW * scale;
    return Positioned(
      left: c.dx - s / 2,
      top: c.dy - s / 2 + dy * r,
      width: s,
      height: s,
      child: Image.asset(
        _iconAsset[kind]!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _label(Offset c, double r, String text) {
    return Positioned(
      left: c.dx - 100,
      top: c.dy + 0.52 * r,
      width: 200,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.tt(
          size: 11.5,
          weight: FontWeight.w700,
          color: AppColors.neonYellow,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Maps a tap point to a region. Room indices follow the seeded rooms
  /// list: 0 game, 1 cinema, 3 music.
  void _resolveTap(
    Offset p, {
    required List<(int, Offset)> rooms,
    required double r,
    required Rect chatRect,
  }) {
    int? best;
    var bestDist = double.infinity;
    for (final (index, c) in rooms) {
      final d = (p - c).distance;
      if (d <= r * 1.02 && d < bestDist) {
        best = index;
        bestDist = d;
      }
    }
    if (best != null) {
      onRoomTap?.call(best);
      return;
    }
    if (chatRect.inflate(6).contains(p)) {
      onGlobalChatTap?.call();
    }
  }
}

// ===========================================================================
// Honeycomb painter — bg, stars, active + ghost hex cells, bottom fade
// ===========================================================================

class _HoneycombPainter extends CustomPainter {
  final Size size;
  final List<Offset> actives;
  final double r;
  final double fadeTop;

  _HoneycombPainter({
    required this.size,
    required this.actives,
    required this.r,
    required this.fadeTop,
  });

  static const _bg = Color(0xFF050605);
  static const _cellFill = Color(0xFF141212);
  static const _gold = Color(0xFFFFC000);
  static const _goldBright = Color(0xFFF0C56A);
  static const _innerGlow = Color(0xFFD68D1F);

  /// 圆角尖顶六边形路径。
  Path _hexPath(Offset c, double radius, double corner) {
    final pts = List.generate(6, (i) {
      final a = -math.pi / 2 + i * math.pi / 3;
      return Offset(c.dx + radius * math.cos(a), c.dy + radius * math.sin(a));
    });
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final prev = pts[(i + 5) % 6];
      final cur = pts[i];
      final next = pts[(i + 1) % 6];
      final inV = (cur - prev);
      final outV = (next - cur);
      final inDir = inV / inV.distance;
      final outDir = outV / outV.distance;
      final p1 = cur - inDir * corner;
      final p2 = cur + outDir * corner;
      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  void _cell(Canvas canvas, Offset c, double radius, double opacity) {
    final path = _hexPath(c, radius, radius * 0.08);
    canvas.drawPath(
        path, Paint()..color = _cellFill.withValues(alpha: opacity));
    // 顶部内侧金色柔光（近似设计稿 inner shadow #D68D1F @62%）
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(c.dx - radius, c.dy - radius, radius * 2, radius * 0.9),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _innerGlow.withValues(alpha: 0.30 * opacity),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromLTWH(c.dx - radius, c.dy - radius, radius * 2, radius)),
    );
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.33
        ..color = _gold.withValues(alpha: 0.85 * opacity),
    );
  }

  @override
  void paint(Canvas canvas, Size s) {
    // 背景 + 顶部暖光
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0xFF1C1403), Color(0xFF0A0803), _bg],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & s),
    );
    _stars(canvas, s);

    // 蜂窝网格：以 game 格为锚点铺设，活跃格满亮，其余 10% 幽灵格。
    final anchor = actives[0];
    final hexW = r * math.sqrt(3);
    final pitchX = hexW + 0.028 * s.width; // 设计稿 155/375
    final pitchY = 1.5 * r + 0.014 * s.width * 1.5; // 约 133.5/375 比例

    final activeSet = actives.map((a) => '${a.dx.round()}_${a.dy.round()}')
        .toSet();

    for (var row = -1; row <= 3; row++) {
      for (var col = -2; col <= 2; col++) {
        final x = anchor.dx + col * pitchX + (row.isOdd ? pitchX / 2 : 0);
        final y = anchor.dy + row * pitchY;
        // 越界太多的跳过
        if (x < -hexW || x > s.width + hexW || y > s.height + r) continue;
        final key = '${x.round()}_${y.round()}';
        if (activeSet.contains(key)) continue;
        _cell(canvas, Offset(x, y), r, 0.10);
      }
    }
    for (final c in actives) {
      _cell(canvas, c, r, 1.0);
    }

    // 蜂巢向聊天面板渐隐
    final fadeRect = Rect.fromLTWH(
        0, fadeTop * s.height, s.width, 0.14 * s.height);
    canvas.drawRect(
      fadeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bg.withValues(alpha: 0), _bg],
        ).createShader(fadeRect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, fadeRect.bottom, s.width, s.height - fadeRect.bottom),
      Paint()..color = _bg,
    );
  }

  void _stars(Canvas canvas, Size s) {
    final rnd = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < 70; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height);
      paint.color =
          _goldBright.withValues(alpha: 0.15 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(o, 0.5 + rnd.nextDouble() * 1.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoneycombPainter old) =>
      old.size != size || old.r != r;
}

// ===========================================================================
// Chat panel — gold-chrome glass card with dark-glass bubbles
// ===========================================================================

class _ChatPanel extends StatelessWidget {
  final String title;
  const _ChatPanel({required this.title});

  /// (dx, dy) 相对面板中心（单位：面板半宽/半高）。
  static const _bubbles = <(double, double, String)>[
    (-0.66, -0.42, '你好'),
    (-0.10, -0.55, 'HI'),
    (0.48, -0.45, 'Hello'),
    (-0.72, 0.02, '你好'),
    (-0.28, -0.08, '英语'),
    (0.12, -0.10, '😊'),
    (0.62, -0.05, 'Bonjour'),
    (-0.50, 0.36, 'Hola'),
    (-0.05, 0.30, '😐'),
    (0.36, 0.28, 'Hello'),
    (0.72, 0.40, 'Ciao'),
    (-0.28, 0.68, 'Konnichiwa'),
    (0.24, 0.66, 'Bonjour'),
    (0.66, 0.72, 'Privet'),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const GoldCardBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: AppColors.cardSurface,
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 顶部金色径向微光
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -1.05),
                        radius: 1.0,
                        colors: [
                          const Color(0xFFFFC000).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 标题
                Positioned(
                  top: 0.055 * h,
                  left: 0,
                  right: 0,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.tt(
                      size: 10,
                      weight: FontWeight.w700,
                      color: AppColors.neonYellow,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
                // 气泡（统一暗玻璃 + 金描边）
                for (final b in _bubbles)
                  Positioned(
                    left: w / 2 + b.$1 * (w / 2) * 0.86,
                    top: h * 0.56 + b.$2 * (h / 2) * 0.72,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: _GlassBubble(text: b.$3),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GlassBubble extends StatelessWidget {
  final String text;
  const _GlassBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    final emoji = text.runes.length == 1 && text.codeUnitAt(0) > 0x2000;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: emoji ? 6 : 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1909).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFFD68D1F).withValues(alpha: 0.55),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: emoji
            ? const TextStyle(fontSize: 13)
            : AppTextStyles.tt(
                size: 11,
                weight: FontWeight.w700,
                color: AppColors.neonYellow,
              ),
      ),
    );
  }
}
