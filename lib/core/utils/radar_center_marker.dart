import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/map_config.dart';
import 'map_icon_bitmap.dart';

/// 用户本人位置的雷达中心：蜂巢六边形枢纽 + 蜂蜜金扫描环。
class RadarCenterMarker {
  RadarCenterMarker._();

  static BitmapDescriptor? _cachedIcon;

  static Color get _primary => MapConfig.radarColor;
  static Color get _accent => MapConfig.radarAccentColor;

  static Future<BitmapDescriptor> icon() async {
    if (_cachedIcon != null) return _cachedIcon!;

    const size = 72.0;
    final dpr = MapIconBitmap.devicePixelRatio();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);
    final center = Offset(size / 2, size / 2);

    // 外圈柔光（蜂巢呼吸感）
    canvas.drawCircle(
      center,
      30,
      Paint()
        ..color = _primary.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 内层同心六边形环
    for (var i = 2; i >= 0; i--) {
      final ring = MapIconBitmap.roundedHexagonPath(
        center: center,
        radius: 18 + i * 7,
        cornerRadius: 4 + i.toDouble(),
      );
      canvas.drawPath(
        ring,
        Paint()
          ..color = _primary.withValues(alpha: 0.12 + i * 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // 主蜂巢枢纽（与地图气泡同语言）
    final hub = MapIconBitmap.roundedHexagonPath(
      center: center,
      radius: 20,
      cornerRadius: 5,
    );
    MapIconBitmap.paintHexShell(canvas, hub, _primary);

    // 中心「我」光点：薄荷青点缀
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = _accent.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, 5.5, Paint()..color = _accent);
    canvas.drawCircle(
      center,
      5.5,
      Paint()
        ..color = const Color(0xFFFFF7D6).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _cachedIcon = await MapIconBitmap.toBitmapDescriptor(recorder, size, size, dpr: dpr);
    return _cachedIcon!;
  }

  /// 地图上的雷达同心圆环（蜂蜜金玻璃描边，与底图低对比路网区分）。
  static Set<Circle> rings(LatLng center) {
    final ringRadiiMeters = MapConfig.radarRingRadiiMeters;
    return {
      for (var i = 0; i < ringRadiiMeters.length; i++)
        Circle(
          circleId: CircleId('me_ring_$i'),
          center: center,
          radius: ringRadiiMeters[i],
          fillColor: _primary.withValues(alpha: 0.025 + i * 0.012),
          strokeColor: _primary.withValues(alpha: 0.18 + (2 - i) * 0.07),
          strokeWidth: 1,
          zIndex: 1 + i,
        ),
    };
  }

  /// 开发时改样式后清缓存，避免热重载仍显示旧图标。
  static void clearCache() => _cachedIcon = null;
}
