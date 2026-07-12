import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static final _imageCache = <String, ui.Image>{};

  static void clearCache() {
    _cache.clear();
    _imageCache.clear();
  }

  static Future<BitmapDescriptor> iconFor({
    required String userId,
    required String avatarSeed,
    required String nickname,
    VirtualAvatar? virtualAvatar,
    required Color ringColor,
    bool online = false,
    /// true 显示六边形框；false 仅显示圆形头像。
    bool showHexFrame = true,
    double size = 48,
  }) async {
    final avatarSig = virtualAvatar != null
        ? '${virtualAvatar.seed}_${virtualAvatar.source.index}_'
            '${virtualAvatar.generatedImageUrl ?? ''}_'
            '${virtualAvatar.colorIndex}_'
            '${virtualAvatar.faceIndex}_${virtualAvatar.eyeIndex}_'
            '${virtualAvatar.mouthIndex}_${virtualAvatar.accessoryIndex}_'
            '${virtualAvatar.style.index}'
        : avatarSeed;
    final key = '${userId}_${avatarSig}_${ringColor.toARGB32()}_${online}_$showHexFrame';
    final cached = _cache[key];
    if (cached != null) return cached;

    final dpr = MapIconBitmap.devicePixelRatio();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr, dpr);
    final center = Offset(size / 2, size / 2);

    final hexRadius = size / 2 - 3;
    if (showHexFrame) {
      final hex = MapIconBitmap.roundedHexagonPath(
        center: center,
        radius: hexRadius,
        cornerRadius: 5,
      );
      MapIconBitmap.paintHexShell(canvas, hex, ringColor);
    }

    // 头像内切于六边形（或无框时占同等区域），以中心对齐
    final avatarDiameter = hexRadius * 1.55;
    final avatarRect = Rect.fromCenter(
      center: center,
      width: avatarDiameter,
      height: avatarDiameter,
    );
    final paintedPhoto = await _tryPaintPhotoAvatar(canvas, avatarRect, virtualAvatar);
    if (!paintedPhoto) {
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

  /// 若是 asset:/photo 头像则绘制并返回 true；否则 false（交给分层/占位绘制）。
  static Future<bool> _tryPaintPhotoAvatar(
    Canvas canvas,
    Rect rect,
    VirtualAvatar? avatar,
  ) async {
    final url = avatar?.generatedImageUrl;
    if (avatar == null ||
        avatar.source != AvatarSource.photo ||
        url == null ||
        !url.startsWith('asset:')) {
      return false;
    }
    final path = url.substring('asset:'.length);
    final image = await _loadAssetImage(path);
    if (image == null) return false;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2)),
    );
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    // BoxFit.cover
    final scale = (rect.width / src.width > rect.height / src.height)
        ? rect.width / src.width
        : rect.height / src.height;
    final dw = src.width * scale;
    final dh = src.height * scale;
    final dst = Rect.fromCenter(center: rect.center, width: dw, height: dh);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
    return true;
  }

  static Future<ui.Image?> _loadAssetImage(String assetPath) async {
    final cached = _imageCache[assetPath];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        // 地图标记很小，降采样避免把 3–4MB 原图解进内存
        targetWidth: 128,
      );
      final frame = await codec.getNextFrame();
      _imageCache[assetPath] = frame.image;
      return frame.image;
    } catch (_) {
      return null;
    }
  }
}
