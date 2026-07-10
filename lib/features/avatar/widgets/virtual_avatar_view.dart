import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/virtual_avatar.dart';

class VirtualAvatarView extends StatelessWidget {
  final VirtualAvatar avatar;
  final double size;
  final bool glow;
  final bool online;

  /// When there is no AI-generated image, show the Figma 3D hero avatar
  /// (`fig_avatar_hero.png`) instead of the procedural fallback. Used for
  /// the profile hero and customize preview to match the redesign; other
  /// contexts (e.g. many nearby users) keep the distinct procedural look.
  final bool heroPlaceholder;

  const VirtualAvatarView({
    super.key,
    required this.avatar,
    this.size = 72,
    this.glow = false,
    this.online = false,
    this.heroPlaceholder = false,
  });

  static const _heroAsset = 'assets/images/avatars/fig_avatar_hero.png';

  static const palettes = [
    [Color(0xFFFF7AAE), Color(0xFFFFC6D9)],
    [Color(0xFF6DE7FF), Color(0xFF6B7CFF)],
    [Color(0xFFFFD36B), Color(0xFFFF8A5C)],
    [Color(0xFF7DFFB2), Color(0xFF22C6A5)],
    [Color(0xFFC79BFF), Color(0xFF7A5CFF)],
    [Color(0xFFFFF176), Color(0xFF42A5F5)],
  ];

  /// 将虚拟形象绘制到 [rect] 区域（供地图标记等离屏 Canvas 使用）。
  static void paintAvatar(Canvas canvas, Rect rect, VirtualAvatar avatar) {
    final colors = palettes[avatar.colorIndex % palettes.length];
    canvas.save();
    canvas.translate(rect.left, rect.top);
    final local = Offset.zero & rect.size;
    if (avatar.style == AvatarVisualStyle.pixel) {
      canvas.clipRRect(RRect.fromRectAndRadius(local, Radius.circular(rect.width * 0.18)));
    } else {
      canvas.clipRRect(RRect.fromRectAndRadius(local, Radius.circular(rect.width / 2)));
    }
    canvas.drawRect(local, Paint()..color = colors.last);
    final painter = avatar.style == AvatarVisualStyle.pixel
        ? _PixelAvatarPainter(avatar, colors)
        : _CuteAvatarPainter(avatar, colors);
    painter.paint(canvas, local.size);
    canvas.restore();
  }

  static ImageProvider? _resolveGeneratedImage(VirtualAvatar avatar) {
    final url = avatar.generatedImageUrl;
    if (avatar.source != AvatarSource.gemini || url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final commaIdx = url.indexOf(',');
      if (commaIdx == -1) return null;
      try {
        return MemoryImage(base64Decode(url.substring(commaIdx + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final colors = palettes[avatar.colorIndex % palettes.length];
    final generatedImage = _resolveGeneratedImage(avatar);
    // No AI image + hero context → show the 3D hero art on a warm backdrop.
    final useHero = generatedImage == null && heroPlaceholder;
    final procedural = CustomPaint(
      painter: avatar.style == AvatarVisualStyle.pixel
          ? _PixelAvatarPainter(avatar, colors)
          : _CuteAvatarPainter(avatar, colors),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: avatar.style == AvatarVisualStyle.pixel ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: avatar.style == AvatarVisualStyle.pixel ? BorderRadius.circular(size * 0.18) : null,
            color: useHero ? AppColors.hexFill : colors.last,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: (useHero ? AppColors.glowOrange : colors.first)
                          .withValues(alpha: 0.55),
                      blurRadius: 18,
                    )
                  ]
                : null,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: useHero
              ? Image.asset(
                  _heroAsset,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) => procedural,
                )
              : generatedImage != null
                  ? Image(
                      image: generatedImage,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorBuilder: (context, error, stackTrace) => procedural,
                    )
                  : procedural,
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bg0, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _CuteAvatarPainter extends CustomPainter {
  final VirtualAvatar avatar;
  final List<Color> colors;

  _CuteAvatarPainter(this.avatar, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..shader = LinearGradient(colors: colors).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final face = Paint()..color = const Color(0xFFFFE0CC);
    final faceRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.55),
      width: size.width * (avatar.faceIndex == 1 ? 0.58 : 0.64),
      height: size.height * (avatar.faceIndex == 2 ? 0.68 : 0.6),
    );
    canvas.drawOval(faceRect, face);

    final hair = Paint()..color = colors.first.withValues(alpha: 0.95);
    canvas.drawArc(faceRect.translate(0, -size.height * 0.1), 3.15, 3.14, true, hair);
    if (avatar.accessoryIndex == 1) {
      final bow = Paint()..color = AppColors.neonPink;
      canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.25), size.width * 0.08, bow);
      canvas.drawCircle(Offset(size.width * 0.44, size.height * 0.25), size.width * 0.08, bow);
    } else if (avatar.accessoryIndex == 2) {
      final halo = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..color = AppColors.neonYellow;
      canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.22), width: size.width * 0.36, height: size.height * 0.1), halo);
    }

    final eye = Paint()..color = const Color(0xFF2B2440);
    final eyeY = size.height * 0.53;
    if (avatar.eyeIndex == 1) {
      canvas.drawLine(Offset(size.width * 0.34, eyeY), Offset(size.width * 0.43, eyeY - size.height * 0.03), eye..strokeWidth = size.width * 0.035);
      canvas.drawLine(Offset(size.width * 0.57, eyeY - size.height * 0.03), Offset(size.width * 0.66, eyeY), eye);
    } else {
      canvas.drawCircle(Offset(size.width * 0.38, eyeY), size.width * 0.035, eye);
      canvas.drawCircle(Offset(size.width * 0.62, eyeY), size.width * 0.035, eye);
      if (avatar.eyeIndex == 2) {
        canvas.drawCircle(Offset(size.width * 0.39, eyeY - 1), size.width * 0.012, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(size.width * 0.63, eyeY - 1), size.width * 0.012, Paint()..color = Colors.white);
      }
    }

    final mouth = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFB14A6B);
    final mouthY = size.height * 0.68;
    if (avatar.mouthIndex == 1) {
      canvas.drawLine(Offset(size.width * 0.45, mouthY), Offset(size.width * 0.55, mouthY), mouth);
    } else if (avatar.mouthIndex == 2) {
      canvas.drawCircle(Offset(size.width * 0.5, mouthY), size.width * 0.035, mouth);
    } else {
      canvas.drawArc(Rect.fromCenter(center: Offset(size.width * 0.5, mouthY - size.height * 0.02), width: size.width * 0.22, height: size.height * 0.14), 0.15, 2.85, false, mouth);
    }
  }

  @override
  bool shouldRepaint(covariant _CuteAvatarPainter oldDelegate) => oldDelegate.avatar != avatar;
}

class _PixelAvatarPainter extends CustomPainter {
  final VirtualAvatar avatar;
  final List<Color> colors;

  _PixelAvatarPainter(this.avatar, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 12;
    void rect(int x, int y, int w, int h, Color color) {
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, w * cell, h * cell), Paint()..color = color);
    }

    rect(0, 0, 12, 12, colors.last);
    rect(3, 3, 6, 7, const Color(0xFFFFD9B8));
    rect(2, 2, 8, 3, colors.first);
    rect(2, 4, 1, 3, colors.first);
    rect(9, 4, 1, 3, colors.first);
    rect(4, 5, 1, 1, const Color(0xFF1D1630));
    rect(7, 5, 1, 1, const Color(0xFF1D1630));
    if (avatar.eyeIndex == 2) {
      rect(4, 4, 1, 1, Colors.white);
      rect(7, 4, 1, 1, Colors.white);
    }
    if (avatar.mouthIndex == 1) {
      rect(5, 8, 2, 1, const Color(0xFF9A3D5A));
    } else {
      rect(5, 8, 1, 1, const Color(0xFF9A3D5A));
      rect(6, 9, 1, 1, const Color(0xFF9A3D5A));
      rect(7, 8, 1, 1, const Color(0xFF9A3D5A));
    }
    if (avatar.accessoryIndex == 1) {
      rect(2, 1, 2, 2, AppColors.neonPink);
      rect(8, 1, 2, 2, AppColors.neonPink);
    } else if (avatar.accessoryIndex == 2) {
      rect(4, 1, 4, 1, AppColors.neonYellow);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelAvatarPainter oldDelegate) => oldDelegate.avatar != avatar;
}
