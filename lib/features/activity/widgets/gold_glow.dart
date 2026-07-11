import 'package:flutter/material.dart';

/// Gold card chrome shared by the Events cards (Frame 4 Figma spec):
/// a 1px linear-gradient border (#D68D1F → #704A10 @60%) plus a soft
/// #FDD570 radial glow stroke near the top edge.
class GoldCardBorderPainter extends CustomPainter {
  final double radius;
  const GoldCardBorderPainter({this.radius = 7});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      const Offset(0.5, 0.5) & Size(size.width - 1, size.height - 1),
      Radius.circular(radius - 0.5),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = const LinearGradient(
          colors: [Color(0x99D68D1F), Color(0x5C704A10)],
        ).createShader(Offset.zero & size),
    );
    // Bright #FDD570 glow bleeding in from the top-left of the border.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = RadialGradient(
          center: const Alignment(-0.55, -1.2),
          radius: 1.0,
          colors: [
            const Color(0xFFFDD570).withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant GoldCardBorderPainter old) =>
      old.radius != radius;
}

/// Pointy-top hexagon with the Figma treatment: dark #141212 fill, crisp
/// #FFC000 outline and a blurred outer gold glow. [child] is centered.
class GlowHexagon extends StatelessWidget {
  final double width;
  final double height;
  final double strokeWidth;
  final Widget? child;

  const GlowHexagon({
    super.key,
    required this.width,
    required this.height,
    this.strokeWidth = 1.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GlowHexPainter(strokeWidth),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _GlowHexPainter extends CustomPainter {
  final double strokeWidth;
  const _GlowHexPainter(this.strokeWidth);

  static const _gold = Color(0xFFFFC000);

  Path _hex(Size s) {
    final w = s.width, h = s.height;
    return Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w / 2, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hex(size);
    canvas.drawPath(path, Paint()..color = const Color(0xFF141212));
    // Outer gold glow.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 3
        ..color = _gold.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Warm inner wash (approximates the Figma inner shadow #D68D1F).
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.9),
          radius: 1.1,
          colors: [
            const Color(0xFFD68D1F).withValues(alpha: 0.28),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size),
    );
    // Crisp outline.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = _gold.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _GlowHexPainter old) =>
      old.strokeWidth != strokeWidth;
}
