import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../features/avatar/widgets/virtual_avatar_view.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../theme/app_colors.dart';
import 'map_icon_bitmap.dart';

/// 附近用户地图标记：圆角六边形气泡 + 用户头像。
class NearbyUserMarker {
  NearbyUserMarker._();

  static final _cache = <String, BitmapDescriptor>{};

  static void clearCache() => _cache.clear();

  static Future<BitmapDescriptor> iconFor({
    required String userId,
    required String avatarSeed,
    required String nickname,
    VirtualAvatar? virtualAvatar,
    required Color ringColor,
    bool online = false,
    double size = 48,
  }) async {
    final avatarSig = virtualAvatar != null
        ? '${virtualAvatar.seed}_${virtualAvatar.colorIndex}_'
            '${virtualAvatar.faceIndex}_${virtualAvatar.eyeIndex}_'
            '${virtualAvatar.mouthIndex}_${virtualAvatar.accessoryIndex}_'
            '${virtualAvatar.style.index}'
        : avatarSeed;
    final key = '${userId}_${avatarSig}_${ringColor.toARGB32()}_$online';
    final cached = _cache[key];
    if (cached != null) return cached;

    final dpr = MapIconBitmap.devicePixelRatio();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);
    final center = Offset(size / 2, size / 2);

    final hexRadius = size / 2 - 3;
    final hex = MapIconBitmap.roundedHexagonPath(
      center: center,
      radius: hexRadius,
      cornerRadius: 5,
    );
    MapIconBitmap.paintHexShell(canvas, hex, ringColor);

    // 头像内切于六边形，以 hex 中心对齐
    final avatarDiameter = hexRadius * 1.55;
    final avatarRect = Rect.fromCenter(
      center: center,
      width: avatarDiameter,
      height: avatarDiameter,
    );
    if (virtualAvatar != null) {
      VirtualAvatarView.paintAvatar(canvas, avatarRect, virtualAvatar);
    } else {
      AvatarPlaceholder.paintOnCanvas(
        canvas,
        avatarRect,
        seed: avatarSeed,
        label: nickname,
      );
    }

    if (online) {
      final dotSize = avatarDiameter * 0.26;
      final dotCenter = Offset(
        avatarRect.right - dotSize * 0.35,
        avatarRect.bottom - dotSize * 0.35,
      );
      canvas.drawCircle(
        dotCenter,
        dotSize / 2 + 1.5,
        Paint()..color = AppColors.bg0,
      );
      canvas.drawCircle(
        dotCenter,
        dotSize / 2,
        Paint()..color = AppColors.neonGreen,
      );
    }

    final descriptor = await MapIconBitmap.toBitmapDescriptor(recorder, size, size, dpr: dpr);
    _cache[key] = descriptor;
    return descriptor;
  }
}
