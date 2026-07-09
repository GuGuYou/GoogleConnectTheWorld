import 'dart:math';
import 'package:flutter/material.dart';

/// 2.5D 等距视角下的世界坐标 ↔ 屏幕坐标转换工具。
///
/// 使用标准 2:1 isometric 投影：
///   screenX = (wx - wy) * tileW / 2
///   screenY = (wx + wy) * tileH / 2
///
/// 世界原点 (0,0) 映射到画布中心。
class IsoTransform {
  final double tileWidth;   // 每个菱形瓦片的屏幕宽
  final double tileHeight;  // 每个菱形瓦片的屏幕高
  final Offset origin;      // 屏幕原点（世界 (0,0) 对应的屏幕像素位置）

  const IsoTransform({
    required this.tileWidth,
    required this.tileHeight,
    required this.origin,
  });

  /// 工厂：根据画布尺寸构造等距投影
  factory IsoTransform.fromCanvas(Size canvas, {double tileW = 64, double tileH = 32}) {
    return IsoTransform(
      tileWidth: tileW,
      tileHeight: tileH,
      origin: Offset(canvas.width / 2, canvas.height / 2),
    );
  }

  /// 世界坐标 → 屏幕坐标
  Offset worldToScreen(double wx, double wy) {
    return Offset(
      origin.dx + (wx - wy) * tileWidth / 2,
      origin.dy + (wx + wy) * tileHeight / 2,
    );
  }

  /// 屏幕坐标 → 世界坐标（近似，用于点击反向）
  Offset screenToWorld(double sx, double sy) {
    final dx = sx - origin.dx;
    final dy = sy - origin.dy;
    final wx = (dx / tileWidth + dy / tileHeight);
    final wy = (dy / tileHeight - dx / tileWidth);
    return Offset(wx, wy);
  }

  /// Y-sort 用的排序键：wy 越大越靠前（屏幕下方）
  double sortKey(double wy) => wy;

  /// 绘制菱形瓦片（等距下的方格地板）
  void paintTile(Canvas canvas, Paint paint, double wx, double wy) {
    final c = worldToScreen(wx, wy);
    final hw = tileWidth / 2;
    final hh = tileHeight / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - hh)
      ..lineTo(c.dx + hw, c.dy)
      ..lineTo(c.dx, c.dy + hh)
      ..lineTo(c.dx - hw, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }
}

/// 六边形房间在世界地图上的排列。
///
/// 6 个房间围绕中心广场排列，每个房间占用 3x3 的瓦片区，
/// 入口（门）朝向中心。
class HiveRoomLayout {
  /// 中心广场的中心世界坐标
  static const Offset plazaCenter = Offset(0, 0);

  /// 6 个房间的世界坐标（房间中心）
  static const List<Offset> roomCenters = [
    Offset(0, -5),    // 上方
    Offset(4.3, -2.5), // 右上
    Offset(4.3, 2.5),  // 右下
    Offset(0, 5),     // 下方
    Offset(-4.3, 2.5), // 左下
    Offset(-4.3, -2.5), // 左上
  ];

  /// 每个房间的入口世界坐标（朝中心一步）
  static List<Offset> roomDoorPositions() {
    return roomCenters.map((c) {
      final dir = Offset(plazaCenter.dx - c.dx, plazaCenter.dy - c.dy);
      final len = sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
      if (len < 1e-6) return c;
      return c + Offset(dir.dx / len * 1.5, dir.dy / len * 1.5);
    }).toList();
  }

  /// 6 个房间的颜色主题（按需求中的类型映射）
  static const List<Color> roomColors = [
    Color(0xFF6366F1), // 上方 - 游戏房 (靛蓝)
    Color(0xFFF43F5E), // 右上 - 电影院 (玫红)
    Color(0xFF10B981), // 右下 - 你画我猜 (翠绿)
    Color(0xFFF59E0B), // 下方 - 音乐吧 (琥珀)
    Color(0xFF8B5CF6), // 左下 - 游戏房2 (紫)
    Color(0xFF06B6D4), // 左上 - 电影院2 (青)
  ];

  /// NPC 绕行路径（绕广场外圈环形行走）
  static List<Offset> npcRingPath({int segments = 24, double radius = 3.5}) {
    final path = <Offset>[];
    for (int i = 0; i < segments; i++) {
      final angle = (2 * pi * i) / segments - pi / 2;
      path.add(Offset(cos(angle) * radius, sin(angle) * radius));
    }
    return path;
  }

  /// 广场活动区域内的随机点（玩家可以走到）
  static Offset randomPlazaPoint(Random rng) {
    // 环形区域：内径 0.5，外径 2.5（避开正中心）
    final angle = rng.nextDouble() * 2 * pi;
    final dist = 0.5 + rng.nextDouble() * 2.0;
    return Offset(cos(angle) * dist, sin(angle) * dist);
  }
}

/// 在瓦片地图上的寻路（A* 简化版，用于角色移动）。
///
/// 使用世界坐标网格（精度到 0.5 格），
/// 只允许在广场区域（世界坐标范围 xy ∈ [-2.5, 2.5]）内移动。
class TilePathfinder {
  static const double _bound = 2.8; // 广场范围

  /// 从起点到终点的直线插值路径（等距场景简单路径即可）
  static List<Offset> findPath(Offset from, Offset to, {int steps = 20}) {
    final path = <Offset>[];
    final clamped = _clampToPlaza(to);
    for (int i = 1; i <= steps; i++) {
      final t = i / steps;
      final p = Offset(
        from.dx + (clamped.dx - from.dx) * t,
        from.dy + (clamped.dy - from.dy) * t,
      );
      path.add(_clampToPlaza(p));
    }
    return path;
  }

  static Offset _clampToPlaza(Offset p) {
    return Offset(
      p.dx.clamp(-_bound, _bound),
      p.dy.clamp(-_bound, _bound),
    );
  }
}
