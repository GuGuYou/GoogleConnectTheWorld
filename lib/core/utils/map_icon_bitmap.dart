import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 将 [IconData] 渲染为 Google Maps [BitmapDescriptor]。
class MapIconBitmap {
  MapIconBitmap._();

  static final _cache = <String, BitmapDescriptor>{};

  static String _cacheKey(IconData icon, Color color, double size, {Color? bgColor}) {
    return '${icon.codePoint}_${icon.fontFamily}_${icon.fontPackage}_${color.toARGB32()}_${size}_${bgColor?.toARGB32()}';
  }

  /// 开发时改图标后若仍不刷新，可热重启（Hot Restart）或调用此方法清缓存。
  static void clearCache() => _cache.clear();

  /// 圆形 pin：彩色底 + 白色图标（适合活动、用户点）。
  static Future<BitmapDescriptor> pin({
    required IconData icon,
    required Color color,
    double size = 44,
    double iconSize = 22,
  }) async {
    final key = _cacheKey(icon, color, size, bgColor: color);
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = size / 2;

    canvas.drawCircle(
      Offset(r, r),
      r - 2,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(Offset(r, r), r - 2, Paint()..color = color);
    canvas.drawCircle(
      Offset(r, r),
      r - 2,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _paintIcon(canvas, icon, iconSize, Colors.white, Offset((size - iconSize) / 2, (size - iconSize) / 2));

    final descriptor = await _toDescriptor(recorder, size, size);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// 气泡 pin：圆角矩形 + 尾巴（适合留言墙）。
  static Future<BitmapDescriptor> bubble({
    required IconData icon,
    required Color color,
    double width = 48,
    double height = 56,
    double iconSize = 18,
  }) async {
    final key = _cacheKey(icon, color, width, bgColor: color);
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 4, width - 8, height - 22),
      const Radius.circular(14),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(body, Paint()..color = color);
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tail = Path()
      ..moveTo(width / 2, height - 18)
      ..lineTo(width / 2 - 6, height - 4)
      ..lineTo(width / 2 + 6, height - 18)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);

    _paintIcon(
      canvas,
      icon,
      iconSize,
      Colors.white,
      Offset((width - iconSize) / 2, 11),
    );

    final descriptor = await _toDescriptor(recorder, width, height);
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

  static Future<BitmapDescriptor> _toDescriptor(
    ui.PictureRecorder recorder,
    double width,
    double height,
  ) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: width,
      height: height,
    );
  }
}
