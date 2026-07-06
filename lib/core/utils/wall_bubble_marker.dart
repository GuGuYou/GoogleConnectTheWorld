import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 留言板地图标记：彩色对话气泡图标。
class WallBubbleMarker {
  WallBubbleMarker._();

  static final _cache = <int, BitmapDescriptor>{};

  static Future<BitmapDescriptor> iconFor(Color color) async {
    final key = color.toARGB32();
    final cached = _cache[key];
    if (cached != null) return cached;

    const w = 48.0;
    const h = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(4, 4, 40, 34),
      const Radius.circular(14),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final tail = Path()
      ..moveTo(24, 38)
      ..lineTo(18, 50)
      ..lineTo(30, 38)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
    canvas.drawPath(
      tail,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    const icon = Icons.chat_bubble_rounded;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 18,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(15, 11));

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), h.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: w,
      height: h,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}
