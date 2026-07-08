import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/hive_room.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/avatar_placeholder.dart';

/// 全屏"蜂巢社交中心"场景（参考"潮玩社群"概念图）。
///
/// 与 [PlazaSceneView] 的差异：
/// - 完全响应式，占满父容器（不再用 InteractiveViewer 等比缩放）
/// - 4 个角的"蜂巢房"呈对称布局，中央有金色能量环
/// - 顶部金胶囊标题 + 底部输入栏全部由本组件渲染，
///   外层 SpacePage 不再做 Column 嵌套。
class HiveRoomScene extends ConsumerStatefulWidget {
  const HiveRoomScene({super.key, this.onSwitchToMap});

  /// 切换到"地图"模式时的回调
  final VoidCallback? onSwitchToMap;

  @override
  ConsumerState<HiveRoomScene> createState() => _HiveRoomSceneState();
}

class _HiveRoomSceneState extends ConsumerState<HiveRoomScene>
    with TickerProviderStateMixin {
  static const _honey = Color(0xFFFFC107);
  static const _honeyBright = Color(0xFFFFE082);
  static const _honeyDeep = Color(0xFFB8860B);
  static const _bgTop = Color(0xFF1A0F00);
  static const _bgMid = Color(0xFF2A1B05);
  static const _bgBottom = Color(0xFF3D2A0E);

  late final AnimationController _beamCtrl;
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    // 中心环旋转
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    // 光束流动
    _beamCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _beamCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // 自适应尺寸：屏幕越宽，蜂房越大但保留最小尺寸
        final shortest = c.maxHeight < c.maxWidth ? c.maxHeight : c.maxWidth;
        final roomSize = (shortest * 0.36).clamp(150.0, 240.0);
        final ringSize = (roomSize * 0.55).clamp(80.0, 130.0);
        return Stack(
          children: [
            // 1. 蜂巢背景纹理
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [_bgBottom, _bgMid, _bgTop],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: Opacity(
                  opacity: 0.22,
                  child: CustomPaint(painter: _HexBackgroundPainter()),
                ),
              ),
            ),
            // 2. 顶部金胶囊标题 + 右上地图切换
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _HiveSocialHeader(
                    title: ref.tr('hive_social_title'),
                    mapLabel: ref.tr('space_map'),
                    onTapMap: widget.onSwitchToMap,
                  ),
                ),
              ),
            ),
            // 3. 动态蜂房 + 中心环 + 光束（从用户 tag 生成，3-6 格）
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 78, 8, 8),
                child: _HiveRoomLayout(
                  rooms: ref.watch(hiveRoomsProvider),
                  roomSize: roomSize,
                  ringSize: ringSize,
                  ringCtrl: _ringCtrl,
                  beamCtrl: _beamCtrl,
                  onRoomTap: (room) {
                    context.push('/tag-space/${room.tag.id}');
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 顶部胶囊标题栏（中文 + 切换地图按钮）
class _HiveSocialHeader extends StatelessWidget {
  final String title;
  final String mapLabel;
  final VoidCallback? onTapMap;
  const _HiveSocialHeader({
    required this.title,
    required this.mapLabel,
    required this.onTapMap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    _HiveRoomSceneState._honey.withValues(alpha: 0.95),
                    _HiveRoomSceneState._honeyDeep.withValues(alpha: 0.95),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _HiveRoomSceneState._honey.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hexagon_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onTapMap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  mapLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 动态蜂房 + 中心环 + 光束布局（3-6 格自适应）
class _HiveRoomLayout extends StatelessWidget {
  final List<HiveRoomData> rooms;
  final double roomSize;
  final double ringSize;
  final Animation<double> ringCtrl;
  final Animation<double> beamCtrl;
  final ValueChanged<HiveRoomData>? onRoomTap;

  const _HiveRoomLayout({
    required this.rooms,
    required this.roomSize,
    required this.ringSize,
    required this.ringCtrl,
    required this.beamCtrl,
    this.onRoomTap,
  });

  /// 根据房间数计算每个房间在画布中的位置
  List<Offset> _computePositions(Size canvas, int count) {
    final center = Offset(canvas.width / 2, canvas.height / 2);
    final radius = (canvas.width < canvas.height ? canvas.width : canvas.height) * 0.32;
    final positions = <Offset>[];

    switch (count) {
      case 3:
        // 品字形：上2 + 下1
        positions.addAll([
          Offset(center.dx - radius * 0.65, center.dy - radius * 0.55),
          Offset(center.dx + radius * 0.65, center.dy - radius * 0.55),
          Offset(center.dx, center.dy + radius * 0.65),
        ]);
        break;
      case 4:
        // 四角
        for (int i = 0; i < 4; i++) {
          final angle = -math.pi / 2 + (2 * math.pi / 4) * i + math.pi / 4;
          positions.add(Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          ));
        }
        break;
      case 5:
        // 五角星排列
        for (int i = 0; i < 5; i++) {
          final angle = -math.pi / 2 + (2 * math.pi / 5) * i;
          positions.add(Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          ));
        }
        break;
      default:
        // 6 格：六边形环绕
        for (int i = 0; i < count; i++) {
          final angle = -math.pi / 2 + (2 * math.pi / count) * i;
          positions.add(Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          ));
        }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final center = Offset(w / 2, h / 2);
        final count = rooms.length.clamp(1, 6);
        final positions = _computePositions(Size(w, h), count);

        // 每房间左上角坐标
        final roomOffsets = positions
            .map((p) => Offset(p.dx - roomSize / 2, p.dy - roomSize / 2))
            .toList();

        return Stack(
          children: [
            // 光束：中心 → 各房间
            Positioned.fill(
              child: CustomPaint(
                painter: _BeamPainter(
                  center: center,
                  targets: positions,
                  phase: beamCtrl.value,
                ),
              ),
            ),
            // 中心能量环
            Positioned(
              left: center.dx - ringSize / 2,
              top: center.dy - ringSize / 2,
              width: ringSize,
              height: ringSize,
              child: _CenterRing(controller: ringCtrl),
            ),
            // 动态蜂房
            for (var i = 0; i < count; i++)
              Positioned(
                left: roomOffsets[i].dx,
                top: roomOffsets[i].dy,
                width: roomSize,
                height: roomSize,
                child: _HiveRoom(
                  roomId: rooms[i].id,
                  title: rooms[i].title,
                  action: rooms[i].action,
                  infoIcon: rooms[i].icon,
                  primaryColor: rooms[i].color,
                  accentEmoji: rooms[i].emoji,
                  bgGradient: rooms[i].isHotFill
                      ? const [Color(0xFFFF7043), Color(0xFFB8860B)]
                      : const [Color(0xFFFFE082), Color(0xFFB8860B)],
                  users: rooms[i].users,
                  roomSize: roomSize,
                  onlineCount: rooms[i].onlineCount,
                  hasUnread: rooms[i].hasUnread,
                  onTap: onRoomTap != null
                      ? () => onRoomTap!(rooms[i])
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 单个蜂巢房：六边形台座 + 顶部房间名 + 活动角色 + 底部 CTA + 同好数/红点
class _HiveRoom extends StatelessWidget {
  final String roomId;
  final String title;
  final String action;
  final IconData infoIcon;
  final Color primaryColor;
  final String accentEmoji;
  final List<Color> bgGradient;
  final List<UserProfile> users;
  final double roomSize;
  final int onlineCount;
  final bool hasUnread;
  final VoidCallback? onTap;

  const _HiveRoom({
    required this.roomId,
    required this.title,
    required this.action,
    required this.infoIcon,
    required this.primaryColor,
    required this.accentEmoji,
    required this.bgGradient,
    required this.users,
    required this.roomSize,
    this.onlineCount = 0,
    this.hasUnread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pad = roomSize * 0.06;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 房间标题 + 同好数 + 未读红点
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (onlineCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$onlineCount',
                      style: const TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (hasUnread) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(infoIcon, size: 12, color: Colors.white),
                ),
              ],
            ),
          ),
        // 立体台座（梯形阴影 + 六边形顶面）
        Positioned(
          top: 28,
          left: 0,
          right: 0,
          bottom: 26,
          child: _HoneycombPlatform(
            gradient: bgGradient,
            roomSize: roomSize,
          ),
        ),
        // 房间内容：emoji + 角色头像
        Positioned(
          top: 32,
          left: pad,
          right: pad,
          bottom: 30,
          child: _RoomContent(
            users: users,
            accentEmoji: accentEmoji,
            primaryColor: primaryColor,
          ),
        ),
        // 底部 CTA 按钮
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFB8860B)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _HiveRoomSceneState._honey.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

/// 六边形立体台座（顶面六边形 + 4 段侧面模拟厚度）
class _HoneycombPlatform extends StatelessWidget {
  final List<Color> gradient;
  final double roomSize;
  const _HoneycombPlatform({required this.gradient, required this.roomSize});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(roomSize, roomSize),
      painter: _HexPlatformPainter(gradient: gradient, size: roomSize),
    );
  }
}

class _HexPlatformPainter extends CustomPainter {
  final List<Color> gradient;
  final double size;
  _HexPlatformPainter({required this.gradient, required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final w = canvasSize.width;
    final h = canvasSize.height;
    final center = Offset(w / 2, h * 0.45);
    final hexSize = math.min(w, h) * 0.48;

    // 顶部六边形 path
    final topHex = _pointyTopHex(center, hexSize);
    // 底面六边形 path（向下偏移模拟厚度）
    final bottomY = center.dy + 14;
    final bottomHex = _pointyTopHex(Offset(center.dx, bottomY), hexSize);

    // 侧面：4 个梯形/平行四边形（在左右两端）
    final leftSide = Path()
      ..moveTo(center.dx - hexSize, center.dy)
      ..lineTo(center.dx - hexSize, bottomY)
      ..lineTo(center.dx - hexSize * 0.5, bottomY + hexSize * 0.85)
      ..lineTo(center.dx - hexSize * 0.5, center.dy + hexSize * 0.85)
      ..close();
    final rightSide = Path()
      ..moveTo(center.dx + hexSize, center.dy)
      ..lineTo(center.dx + hexSize, bottomY)
      ..lineTo(center.dx + hexSize * 0.5, bottomY + hexSize * 0.85)
      ..lineTo(center.dx + hexSize * 0.5, center.dy + hexSize * 0.85)
      ..close();

    // 侧面渐变（暗蜂蜜色）
    final sidePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8B6914), Color(0xFF5C4400)],
      ).createShader(Rect.fromLTWH(0, center.dy, w, h - center.dy));
    canvas.drawPath(leftSide, sidePaint);
    canvas.drawPath(rightSide, sidePaint);

    // 底面（在顶面下方，模拟厚度底部）
    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6B4F00), Color(0xFF3D2A0E)],
      ).createShader(bottomHex.getBounds());
    canvas.drawPath(bottomHex, bottomPaint);

    // 顶面：蜂蜜金渐变
    final topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      ).createShader(topHex.getBounds());
    canvas.drawPath(topHex, topPaint);

    // 顶面描边
    final stroke = Paint()
      ..color = _HiveRoomSceneState._honeyBright.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(topHex, stroke);

    // 顶面中心高光圆
    final hl = Paint()
      ..shader = RadialGradient(
        colors: [
          _HiveRoomSceneState._honeyBright.withValues(alpha: 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: hexSize * 0.9));
    canvas.drawPath(topHex, hl);
  }

  Path _pointyTopHex(Offset center, double size) {
    final p = Path();
    for (int i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + size * math.cos(a);
      final y = center.dy + size * math.sin(a);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(_HexPlatformPainter old) =>
      old.size != size || old.gradient != gradient;
}

/// 房间内角色头像 + emoji 装饰
class _RoomContent extends StatelessWidget {
  final List<UserProfile> users;
  final String accentEmoji;
  final Color primaryColor;
  const _RoomContent({
    required this.users,
    required this.accentEmoji,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final showUsers = users.take(3).toList();
    return Stack(
      children: [
        // emoji 装饰
        Positioned(
          top: 0,
          right: 0,
          child: Text(accentEmoji, style: const TextStyle(fontSize: 22)),
        ),
        // 角色头像：底部居中铺一行
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < showUsers.length; i++)
                Transform.translate(
                  offset: Offset(0, (i % 2 == 0 ? 0.0 : -4.0)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: AvatarPlaceholder(
                      seed: showUsers[i].avatarSeed,
                      label: showUsers[i].nickname,
                      size: 22,
                      online: showUsers[i].online,
                      glow: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 中心金色能量环（多层叠加 + 旋转）
class _CenterRing extends StatelessWidget {
  final Animation<double> controller;
  const _CenterRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RingPainter(rotation: controller.value * 2 * math.pi),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double rotation;
  _RingPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.42;

    // 外发光
    final glow = Paint()
      ..color = _HiveRoomSceneState._honey.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(center, r, glow);

    // 主环
    final ring = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFFC107),
          Color(0xFFFFE082),
          Color(0xFFFFC107),
        ],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, r, ring);

    // 内环
    final innerRing = Paint()
      ..color = _HiveRoomSceneState._honeyBright.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, r - 8, innerRing);

    // 中心高光
    final hl = Paint()
      ..shader = RadialGradient(
        colors: [
          _HiveRoomSceneState._honeyBright.withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.7));
    canvas.drawCircle(center, r * 0.4, hl);

    // 4 个浮空粒子（沿环旋转）
    for (int i = 0; i < 4; i++) {
      final a = rotation + (math.pi / 2) * i;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      final dot = Paint()..color = _HiveRoomSceneState._honeyBright;
      canvas.drawCircle(p, 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.rotation != rotation;
}

/// 中心 → 4 房 的光束（流光效果）
class _BeamPainter extends CustomPainter {
  final Offset center;
  final List<Offset> targets;
  final double phase;
  _BeamPainter({
    required this.center,
    required this.targets,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      // 渐变光束
      final beam = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _HiveRoomSceneState._honey.withValues(alpha: 0.0),
            _HiveRoomSceneState._honey.withValues(alpha: 0.55),
            _HiveRoomSceneState._honeyBright.withValues(alpha: 0.7),
            _HiveRoomSceneState._honey.withValues(alpha: 0.55),
            _HiveRoomSceneState._honey.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        ).createShader(Rect.fromPoints(center, t))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center, t, beam);

      // 移动光点
      final move = (phase + i / targets.length) % 1.0;
      final px = center.dx + (t.dx - center.dx) * move;
      final py = center.dy + (t.dy - center.dy) * move;
      final dot = Paint()..color = _HiveRoomSceneState._honeyBright;
      canvas.drawCircle(Offset(px, py), 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      old.phase != phase || old.center != center || old.targets != targets;
}

/// 背景蜂巢纹理（沿用 plaza 视觉一致性）
class _HexBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _HiveRoomSceneState._honey.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const r = 50.0;
    const dx = r * 1.732;
    const dy = r * 1.5;
    const offX = dx / 2;
    for (int row = -1;; row++) {
      final y = row * dy;
      if (y - r > size.height) break;
      final offset = row.isOdd ? offX : 0.0;
      for (int col = -1;; col++) {
        final x = col * dx + offset;
        if (x - r > size.width) break;
        final p = Path();
        for (int i = 0; i < 6; i++) {
          final a = (math.pi / 3) * i - math.pi / 2;
          final px = x + r * math.cos(a);
          final py = y + r * math.sin(a);
          if (i == 0) {
            p.moveTo(px, py);
          } else {
            p.lineTo(px, py);
          }
        }
        p.close();
        canvas.drawPath(p, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HexBackgroundPainter old) => false;
}
