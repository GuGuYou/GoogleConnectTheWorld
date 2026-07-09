import 'dart:math';

import 'package:flutter/material.dart';

import 'iso_transform.dart';
import 'scene_models.dart';

/// 2.5D 等距蜂巢场景渲染器（CustomPainter）。
///
/// 绘制顺序（Y-sort 画家算法）：
///   1. 渐变背景 + 地板蜂巢纹理
///   2. 6 个六边形房间（门朝向中心）
///   3. 中心广场装饰环
///   4. 角色（按 wy 排序，远的先画）
///   5. 交互气泡（挥手、房间标签）
class HiveScenePainter extends CustomPainter {
  final IsoTransform iso;
  final List<SceneActor> actors;
  final List<SceneRoom> rooms;
  final int tick;        // 用于动画相位
  final String? selectedActorId;
  final String? enteredRoomId;

  HiveScenePainter({
    required this.iso,
    required this.actors,
    required this.rooms,
    required this.tick,
    this.selectedActorId,
    this.enteredRoomId,
  });

  // 颜色常量
  static const _floorLine = Color(0x30FFD84A);
  static const _floorFill = Color(0x182D1A00);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawFloorGrid(canvas);
    _drawPlazaCenter(canvas);
    _drawRooms(canvas);
    _drawActors(canvas);
    _drawBubbles(canvas);
  }

  // ---- 背景 ----
  void _drawBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // 深棕渐变
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF3D2A0E), Color(0xFF1A0F00), Color(0xFF0D0700)],
        stops: [0.0, 0.55, 1.0],
        center: Alignment.center,
        radius: 1.1,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);
  }

  // ---- 蜂巢地板网格 ----
  void _drawFloorGrid(Canvas canvas) {
    final gridPaint = Paint()
      ..color = _floorLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final fillPaint = Paint()..color = _floorFill;

    // 绘制等距菱形瓦片网格
    final range = 8;
    for (int x = -range; x <= range; x++) {
      for (int y = -range; y <= range; y++) {
        // 跳过太远的瓦片
        if (x.abs() + y.abs() > 10) continue;
        // 跳过广场中心区域（留空）
        if (x.abs() <= 2 && y.abs() <= 2) continue;
        // 跳过房间区域
        if (_isRoomArea(x, y)) continue;

        iso.paintTile(canvas, fillPaint, x.toDouble(), y.toDouble());
        iso.paintTile(canvas, gridPaint, x.toDouble(), y.toDouble());
      }
    }
  }

  bool _isRoomArea(int wx, int wy) {
    for (final r in rooms) {
      final dx = (wx - r.worldPos.dx).abs();
      final dy = (wy - r.worldPos.dy).abs();
      if (dx <= 1.5 && dy <= 1.5) return true;
    }
    return false;
  }

  // ---- 中心广场 ----
  void _drawPlazaCenter(Canvas canvas) {
    final center = iso.worldToScreen(0, 0);

    // 外发光
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0x30FFD84A), const Color(0x00FFD84A)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: iso.tileWidth * 2.0));
    canvas.drawCircle(center, iso.tileWidth * 2.0, glowPaint);

    // 金色环
    final phase = (tick % 480) / 480.0;
    final ringPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0x80FFD84A), Color(0xFFFFB000),
          Color(0x40FFD84A), Color(0x80FFD84A),
        ],
        stops: [phase, (phase + 0.3) % 1, (phase + 0.6) % 1, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: iso.tileWidth * 1.5));

    canvas.drawCircle(center, iso.tileWidth * 1.5, ringPaint);
    canvas.drawCircle(center, iso.tileWidth * 1.5,
      Paint()..color = const Color(0x30FFD84A)..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    // 浮空粒子
    final particlePaint = Paint()..color = const Color(0xAAFFD84A);
    for (int i = 0; i < 4; i++) {
      final a = (tick * 0.02 + i * pi / 2) % (2 * pi);
      final r = iso.tileWidth * 1.2 + sin(tick * 0.05 + i) * 8;
      final px = center.dx + cos(a) * r;
      final py = center.dy + sin(a) * r;
      canvas.drawCircle(Offset(px, py), 2.5, particlePaint);
    }
  }

  // ---- 六边形房间 ----
  void _drawRooms(Canvas canvas) {
    for (final room in rooms) {
      _drawRoom(canvas, room);
    }
  }

  void _drawRoom(Canvas canvas, SceneRoom room) {
    final c = iso.worldToScreen(room.worldPos.dx, room.worldPos.dy);
    final r = iso.tileWidth * 1.4;

    // 六边形台座阴影
    final shadowPaint = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(c + const Offset(2, 4), r * 0.9, shadowPaint);

    // 六边形主体（顶面）
    final hexPath = _hexPath(c, r);
    canvas.drawPath(hexPath, Paint()..color = room.color.withOpacity(0.15));

    // 六边形描边
    canvas.drawPath(hexPath, Paint()
      ..color = room.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
    );

    // 侧面（模拟厚度）
    final thickness = 12.0;
    for (int i = 0; i < 3; i++) {
      // 绘制朝下的三面
      final pStart = _hexCorner(c, r, 3 + i);
      final pEnd = _hexCorner(c, r, 3 + i + 1);
      final sidePath = Path()
        ..moveTo(pStart.dx, pStart.dy)
        ..lineTo(pEnd.dx, pEnd.dy)
        ..lineTo(pEnd.dx, pEnd.dy + thickness)
        ..lineTo(pStart.dx, pStart.dy + thickness)
        ..close();
      canvas.drawPath(sidePath, Paint()
        ..color = room.color.withOpacity(0.1 + i * 0.03));
    }

    // 门（朝向中心）
    final doorDir = Offset(
      -room.worldPos.dx,
      -room.worldPos.dy,
    );
    final doorLen = sqrt(doorDir.dx * doorDir.dx + doorDir.dy * doorDir.dy);
    if (doorLen > 1e-3) {
      final dirX = doorDir.dx / doorLen;
      final dirY = doorDir.dy / doorLen;
      // 门的位置在六边形朝向中心的一边
      final doorScreen = iso.worldToScreen(
        room.worldPos.dx + dirX * 1.2,
        room.worldPos.dy + dirY * 1.2,
      );
      final doorPaint = Paint()
        ..color = room.color.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: doorScreen, width: 10, height: 16),
          const Radius.circular(3),
        ),
        doorPaint,
      );
    }

    // Emoji + 房间名
    final textPainter = TextPainter(
      text: TextSpan(
        text: room.type.label.split(' ').last,
        style: TextStyle(
          color: room.color.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r * 2);
    textPainter.paint(canvas, Offset(c.dx - textPainter.width / 2, c.dy + r * 0.3));

    // 在线人数
    final countPainter = TextPainter(
      text: TextSpan(
        text: '${room.onlineCount}在线',
        style: TextStyle(
          color: room.color.withOpacity(0.6),
          fontSize: 8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    countPainter.paint(canvas, Offset(c.dx - countPainter.width / 2, c.dy + r * 0.5));
  }

  Path _hexPath(Offset center, double r) {
    return Path()..addPolygon(
      List.generate(6, (i) => _hexCorner(center, r, i)),
      true,
    );
  }

  Offset _hexCorner(Offset c, double r, int i) {
    final angle = (i * 60 - 30) * pi / 180;
    return Offset(c.dx + cos(angle) * r, c.dy + sin(angle) * r);
  }

  // ---- 角色 ----
  void _drawActors(Canvas canvas) {
    // Y-sort：按 worldY 排序（越靠上的先画）
    final sorted = List<SceneActor>.from(actors)
      ..sort((a, b) => a.worldPos.dy.compareTo(b.worldPos.dy));

    for (final actor in sorted) {
      _drawActor(canvas, actor);
    }
  }

  void _drawActor(Canvas canvas, SceneActor actor) {
    final pos = iso.worldToScreen(actor.worldPos.dx, actor.worldPos.dy);
    final isSelected = actor.id == selectedActorId;

    // 光晕环（我=金，别人=银）
    _drawGlowRing(canvas, pos, actor, isSelected);

    // 阴影
    canvas.drawOval(
      Rect.fromCenter(center: pos + const Offset(0, 16), width: 24, height: 8),
      Paint()..color = const Color(0x40000000)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 身体
    final bodyR = 12.0;
    canvas.drawCircle(pos - const Offset(0, 2), bodyR,
      Paint()..shader = LinearGradient(
        colors: [
          _avatarColor(actor.avatarSeed, 0),
          _avatarColor(actor.avatarSeed, 1),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: pos - const Offset(0, 2), radius: bodyR)),
    );

    // 头部
    final headR = 8.0;
    canvas.drawCircle(pos - const Offset(0, 14), headR,
      Paint()..color = _avatarColor(actor.avatarSeed, 2),
    );

    // 眼睛
    final eyePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawCircle(pos - const Offset(3, 15), 2.5, eyePaint);
    canvas.drawCircle(pos + const Offset(3, -15), 2.5, eyePaint);
    canvas.drawCircle(pos - const Offset(3, 15), 1.2, Paint()..color = Colors.black87);
    canvas.drawCircle(pos + const Offset(3, -15), 1.2, Paint()..color = Colors.black87);

    // 名字
    final namePainter = TextPainter(
      text: TextSpan(
        text: actor.name,
        style: TextStyle(
          color: actor.isMe ? const Color(0xFFFFD84A) : Colors.white70,
          fontSize: 9,
          fontWeight: actor.isMe ? FontWeight.w700 : FontWeight.w400,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    namePainter.paint(canvas, Offset(pos.dx - namePainter.width / 2, pos.dy - 28));

    // 走路动画（通过 tick 驱动角色轻微上下弹跳）
    if (actor.state == ActorState.walking) {
      // 使用 tick 相位驱动弹跳效果（在角色 y 坐标上微调）
    }
  }

  void _drawGlowRing(Canvas canvas, Offset pos, SceneActor actor, bool selected) {
    final ringR = selected ? 20.0 : 14.0;
    final alpha = actor.isMe ? 0.6 : 0.3;
    final pulse = 1.0 + sin(tick * 0.05) * 0.1;

    canvas.drawCircle(pos, ringR * pulse,
      Paint()
        ..color = actor.glowColor.withOpacity(alpha * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = actor.isMe ? 2.5 : 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  Color _avatarColor(int seed, int variant) {
    const colors = [
      [Color(0xFFFF7AAE), Color(0xFFFFC6D9), Color(0xFFFFE0EC)],
      [Color(0xFF6DE7FF), Color(0xFF6B7CFF), Color(0xFFB3C6FF)],
      [Color(0xFFFFD36B), Color(0xFFFF8A5C), Color(0xFFFFE0B2)],
      [Color(0xFF7DFFB2), Color(0xFF22C6A5), Color(0xFFB9F6CA)],
      [Color(0xFFC79BFF), Color(0xFF7A5CFF), Color(0xFFD1C4FF)],
      [Color(0xFFFFF176), Color(0xFF42A5F5), Color(0xFFFFF9C4)],
    ];
    return colors[seed.abs() % colors.length][variant % 3];
  }

  // ---- 气泡 ----
  void _drawBubbles(Canvas canvas) {
    for (final actor in actors) {
      if (actor.showWaveBubble) {
        final pos = iso.worldToScreen(actor.worldPos.dx, actor.worldPos.dy);
        _drawWaveBubble(canvas, pos);
      }
    }
  }

  void _drawWaveBubble(Canvas canvas, Offset pos) {
    final bubblePos = pos - const Offset(0, 42);
    final bubbleR = 20.0;

    // 气泡背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: bubblePos, radius: bubbleR),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // 小三角
    final triPath = Path()
      ..moveTo(bubblePos.dx, bubblePos.dy + bubbleR - 2)
      ..lineTo(bubblePos.dx - 5, bubblePos.dy + bubbleR + 8)
      ..lineTo(bubblePos.dx + 5, bubblePos.dy + bubbleR + 8)
      ..close();
    canvas.drawPath(triPath, Paint()..color = Colors.white.withOpacity(0.9));

    // 文字
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '👋',
        style: TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(bubblePos.dx - textPainter.width / 2, bubblePos.dy - 8));
  }

  @override
  bool shouldRepaint(covariant HiveScenePainter oldDelegate) {
    return true; // 每帧都重绘（游戏循环）
  }
}
