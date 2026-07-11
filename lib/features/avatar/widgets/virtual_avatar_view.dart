import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/virtual_avatar.dart';
import 'layered_avatar.dart';
import 'minimal_avatar.dart';

/// Renders a [VirtualAvatar] as the layered watercolor avatar composed from
/// the Frame 2 part sprites (see [LayeredAvatar]). An AI-generated image,
/// if present, takes precedence.
class VirtualAvatarView extends StatelessWidget {
  final VirtualAvatar avatar;
  final double size;
  final bool glow;
  final bool online;

  const VirtualAvatarView({
    super.key,
    required this.avatar,
    this.size = 72,
    this.glow = false,
    this.online = false,
  });

  /// Paint the avatar into [rect] on an offscreen canvas (map markers, etc.).
  /// Uses the layered sprites when [AvatarPartCache] is warmed up, otherwise
  /// falls back to the procedural minimal avatar.
  static void paintAvatar(Canvas canvas, Rect rect, VirtualAvatar avatar) {
    if (AvatarPartCache.ready) {
      AvatarPartCache.drawAvatar(canvas, rect, avatar);
      return;
    }
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2)));
    canvas.translate(rect.left, rect.top);
    MinimalAvatarPainter(avatar).paint(canvas, rect.size);
    canvas.restore();
  }

  /// If the AI has generated a real image (data URI or URL), resolve it;
  /// otherwise null → the procedural avatar is drawn.
  static ImageProvider? _resolveGeneratedImage(VirtualAvatar avatar) {
    final url = avatar.generatedImageUrl;
    if (avatar.source != AvatarSource.gemini || url == null || url.isEmpty) {
      return null;
    }
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
    final generatedImage = _resolveGeneratedImage(avatar);
    final bg = MinimalAvatarPainter.backgrounds[
        avatar.backgroundIndex % MinimalAvatarPainter.backgrounds.length];
    final procedural = LayeredAvatar(avatar: avatar, size: size);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: bg[1].withValues(alpha: 0.5),
                      blurRadius: 18,
                    )
                  ]
                : null,
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: generatedImage != null
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
