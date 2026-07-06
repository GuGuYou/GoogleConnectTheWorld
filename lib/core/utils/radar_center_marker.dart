import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';

/// 用户本人位置的雷达中心：同心圆环 + 十字准星 + 中心光点。
class RadarCenterMarker {
  RadarCenterMarker._();

  static BitmapDescriptor? _cachedIcon;

  /// 雷达扫描环（米），由内到外透明度递减。
  static const List<double> ringRadiiMeters = [120, 240, 400];

  static Future<BitmapDescriptor> icon() async {
    if (_cachedIcon != null) return _cachedIcon!;

    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final color = AppColors.neonCyan;

    // 外圈雷达环（静态图形，动画由地图 Circle 层补充）
    for (var i = 3; i >= 1; i--) {
      final radius = size / 2 - 4 - (3 - i) * 6;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.08 * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // 十字准星
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const crossLen = 14.0;
    canvas.drawLine(center + const Offset(-crossLen, 0), center + const Offset(-6, 0), crossPaint);
    canvas.drawLine(center + const Offset(6, 0), center + const Offset(crossLen, 0), crossPaint);
    canvas.drawLine(center + const Offset(0, -crossLen), center + const Offset(0, -6), crossPaint);
    canvas.drawLine(center + const Offset(0, 6), center + const Offset(0, crossLen), crossPaint);

    // 扫描扇形（45° 楔形，暗示雷达方向）
    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size / 2 - 8),
        -math.pi / 4,
        math.pi / 6,
        false,
      )
      ..close();
    canvas.drawPath(
      sweepPath,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          size / 2 - 8,
          [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        ),
    );

    // 中心光点
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(center, 7, Paint()..color = color);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    _cachedIcon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: size,
      height: size,
    );
    return _cachedIcon!;
  }

  /// 地图上的雷达同心圆环（与中心 Marker 配合）。
  static Set<Circle> rings(LatLng center) {
    return {
      for (var i = 0; i < ringRadiiMeters.length; i++)
        Circle(
          circleId: CircleId('me_ring_$i'),
          center: center,
          radius: ringRadiiMeters[i],
          fillColor: AppColors.neonCyan.withValues(alpha: 0.04 + i * 0.02),
          strokeColor: AppColors.neonCyan.withValues(alpha: 0.25 - i * 0.05),
          strokeWidth: 2,
          zIndex: 1 + i,
        ),
    };
  }
}
