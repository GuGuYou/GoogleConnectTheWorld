import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 将 [IconData] 渲染为 Google Maps [BitmapDescriptor]。
class MapIconBitmap {
  MapIconBitmap._();

  static final _cache = <String, BitmapDescriptor>{};

  static String _cacheKey(IconData icon, Color color, double size, {Color? bgColor, double? dpr}) {
    return '${icon.codePoint}_${icon.fontFamily}_${icon.fontPackage}_${color.toARGB32()}_${size}_${bgColor?.toARGB32()}_${dpr?.toStringAsFixed(1)}';
  }

  /// 当前设备像素比，用于高清地图标记渲染。
  static double devicePixelRatio() {
    final views = ui.PlatformDispatcher.instance.views;
    if (views.isEmpty) return 2.0;
    return views.first.devicePixelRatio.clamp(1.0, 3.0);
  }

  /// 开发时改图标后若仍不刷新，可热重启（Hot Restart）或调用此方法清缓存。
  static void clearCache() => _cache.clear();

  /// 圆角半透明六边形标记（适合活动、用户、留言板）。
  static Future<BitmapDescriptor> pin({
    required IconData icon,
    required Color color,
    double size = 44,
    double iconSize = 22,
  }) async {
    final dpr = devicePixelRatio();
    final key = _cacheKey(icon, color, size, bgColor: color, dpr: dpr);
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);
    final center = Offset(size / 2, size / 2);
    final hex = roundedHexagonPath(
      center: center,
      radius: size / 2 - 4,
      cornerRadius: 5,
    );

    paintHexShell(canvas, hex, color);
    _paintIcon(canvas, icon, iconSize, Colors.white, Offset((size - iconSize) / 2, (size - iconSize) / 2));

    final descriptor = await toBitmapDescriptor(recorder, size, size, dpr: dpr);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// 尖顶圆角六边形路径（与广场蜂巢视觉一致）。
  static Path roundedHexagonPath({
    required Offset center,
    required double radius,
    double cornerRadius = 5,
  }) {
    final points = List.generate(6, (i) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });

    final path = Path();
    for (var i = 0; i < 6; i++) {
      final curr = points[i];
      final next = points[(i + 1) % 6];
      final prev = points[(i + 5) % 6];

      final fromPrev = curr - prev;
      final toNext = next - curr;
      final lenPrev = fromPrev.distance;
      final lenNext = toNext.distance;
      final cr = cornerRadius.clamp(0.0, math.min(lenPrev, lenNext) / 2 - 0.5);

      final start = Offset(
        curr.dx - fromPrev.dx / lenPrev * cr,
        curr.dy - fromPrev.dy / lenPrev * cr,
      );
      final end = Offset(
        curr.dx + toNext.dx / lenNext * cr,
        curr.dy + toNext.dy / lenNext * cr,
      );

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(curr.dx, curr.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }

  /// 半透明六边形外壳：柔光 + 填充 + 描边。
  static void paintHexShell(Canvas canvas, Path hex, Color color) {
    canvas.drawPath(
      hex,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(hex, Paint()..color = color.withValues(alpha: 0.55));
    canvas.drawPath(
      hex,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// 气泡 pin：圆角六边形（与 [pin] 样式一致）。
  static Future<BitmapDescriptor> bubble({
    required IconData icon,
    required Color color,
    double width = 48,
    double height = 56,
    double iconSize = 18,
  }) async {
    final dpr = devicePixelRatio();
    final key = _cacheKey(icon, color, width, bgColor: color, dpr: dpr);
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);
    final center = Offset(width / 2, (height - 22) / 2 + 4);
    final hex = roundedHexagonPath(
      center: center,
      radius: math.min(width, height - 22) / 2 - 6,
      cornerRadius: 6,
    );

    paintHexShell(canvas, hex, color);

    _paintIcon(
      canvas,
      icon,
      iconSize,
      Colors.white,
      Offset((width - iconSize) / 2, center.dy - iconSize / 2),
    );

    final descriptor = await toBitmapDescriptor(recorder, width, height, dpr: dpr);
    _cache[key] = descriptor;
    return descriptor;
  }

  static void _paintIcon(Canvas canvas, IconData icon, double size, Color color, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  static Future<BitmapDescriptor> toBitmapDescriptor(
    ui.PictureRecorder recorder,
    double logicalWidth,
    double logicalHeight, {
    required double dpr,
  }) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (logicalWidth * dpr).round(),
      (logicalHeight * dpr).round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: logicalWidth,
      height: logicalHeight,
      imagePixelRatio: dpr,
    );
  }
}
