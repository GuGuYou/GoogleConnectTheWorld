import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/models/virtual_avatar.dart';

/// Layered bitmap avatar built from the Frame 2 Figma part sprites
/// (assets/images/avatars/parts): watercolor face bases, hairs with
/// scalp+ears, eyes, mouths, accessories and scenic circle backgrounds.
///
/// Slots (option 0 of hair/accessory means "none"):
///   face 5 · hair 1+5 · eyes 5 · mouth 5 · accessory 1+6 · background 5
class AvatarParts {
  AvatarParts._();

  static const dir = 'assets/images/avatars/parts';

  static const faceCount = 5;
  static const hairCount = 6; // 0 = none, 1..5 -> hair_0..4
  static const eyeCount = 5;
  static const mouthCount = 5;
  static const accCount = 7; // 0 = none, 1..6 -> acc_0..5
  static const bgCount = 5;

  static String face(int i) => '$dir/face_${i % faceCount}.png';
  static String hair(int i) => '$dir/hair_${(i - 1) % (hairCount - 1)}.png';
  static String eyes(int i) => '$dir/eyes_${i % eyeCount}.png';
  static String mouth(int i) => '$dir/mouth_${i % mouthCount}.png';
  static String acc(int i) => '$dir/acc_${(i - 1) % (accCount - 1)}.png';
  static String bg(int i) => '$dir/bg_${i % bgCount}.png';

  /// Every part asset (for preloading).
  static List<String> all() => [
        for (var i = 0; i < faceCount; i++) face(i),
        for (var i = 1; i < hairCount; i++) hair(i),
        for (var i = 0; i < eyeCount; i++) eyes(i),
        for (var i = 0; i < mouthCount; i++) mouth(i),
        for (var i = 1; i < accCount; i++) acc(i),
        for (var i = 0; i < bgCount; i++) bg(i),
      ];
}

/// Placement of a part inside the unit avatar box: [w] = width fraction,
/// ([cx],[cy]) = center. Height follows the image's aspect ratio.
class PartLayout {
  final double w;
  final double cx;
  final double cy;
  const PartLayout(this.w, this.cx, this.cy);
}

class AvatarLayouts {
  AvatarLayouts._();

  static const face = PartLayout(0.63, 0.5, 0.61);
  static const eyes = PartLayout(0.42, 0.5, 0.575);
  static const mouth = PartLayout(0.16, 0.5, 0.72);
  static const hair = PartLayout(0.84, 0.5, 0.395);

  /// Per-accessory placement (index 1..6 → list 0..5):
  /// glasses, monocle, round shades, square shades, earring, cap.
  static const accs = <PartLayout>[
    PartLayout(0.48, 0.5, 0.575),
    PartLayout(0.18, 0.62, 0.58),
    PartLayout(0.50, 0.5, 0.575),
    PartLayout(0.48, 0.5, 0.57),
    PartLayout(0.09, 0.78, 0.695),
    PartLayout(0.60, 0.5, 0.30),
  ];
}

/// Widget composition of the layered avatar (background optional).
class LayeredAvatar extends StatelessWidget {
  final VirtualAvatar avatar;
  final double size;
  final bool drawBackground;

  const LayeredAvatar({
    super.key,
    required this.avatar,
    required this.size,
    this.drawBackground = true,
  });

  Widget _part(String asset, PartLayout l) {
    return Positioned(
      left: l.cx * size,
      top: l.cy * size,
      width: l.w * size,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Image.asset(asset, filterQuality: FilterQuality.medium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = avatar;
    final hair = a.hairIndex % AvatarParts.hairCount;
    final acc = a.accessoryIndex % AvatarParts.accCount;
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (drawBackground)
              Positioned.fill(
                child: Image.asset(AvatarParts.bg(a.backgroundIndex),
                    fit: BoxFit.cover),
              ),
            _part(AvatarParts.face(a.faceIndex), AvatarLayouts.face),
            // 发型带头皮补丁，垫在五官下面：刘海压前额，眼嘴浮在最上层
            if (hair > 0) _part(AvatarParts.hair(hair), AvatarLayouts.hair),
            _part(AvatarParts.eyes(a.eyeIndex), AvatarLayouts.eyes),
            _part(AvatarParts.mouth(a.mouthIndex), AvatarLayouts.mouth),
            if (acc > 0)
              _part(AvatarParts.acc(acc),
                  AvatarLayouts.accs[(acc - 1) % AvatarLayouts.accs.length]),
          ],
        ),
      ),
    );
  }
}

/// Decoded-image cache so the avatar can also be drawn synchronously onto
/// a raw [Canvas] (map markers). Call [preload] once at startup.
class AvatarPartCache {
  AvatarPartCache._();

  static final Map<String, ui.Image> _images = {};
  static bool _loading = false;

  static bool get ready => _images.length >= AvatarParts.all().length;

  static Future<void> preload() async {
    if (ready || _loading) return;
    _loading = true;
    try {
      for (final asset in AvatarParts.all()) {
        if (_images.containsKey(asset)) continue;
        final data = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(data.buffer.asUint8List());
        _images[asset] = (await codec.getNextFrame()).image;
      }
    } finally {
      _loading = false;
    }
  }

  static void _draw(Canvas canvas, Rect box, String asset, PartLayout l) {
    final img = _images[asset];
    if (img == null) return;
    final w = l.w * box.width;
    final h = w * img.height / img.width;
    final dst = Rect.fromCenter(
      center: Offset(box.left + l.cx * box.width, box.top + l.cy * box.height),
      width: w,
      height: h,
    );
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  /// Draws the layered avatar clipped to a circle in [rect].
  static void drawAvatar(Canvas canvas, Rect rect, VirtualAvatar a) {
    canvas.save();
    canvas.clipRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.width / 2)));
    final bg = _images[AvatarParts.bg(a.backgroundIndex)];
    if (bg != null) {
      canvas.drawImageRect(
        bg,
        Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    _draw(canvas, rect, AvatarParts.face(a.faceIndex), AvatarLayouts.face);
    final hair = a.hairIndex % AvatarParts.hairCount;
    if (hair > 0) {
      _draw(canvas, rect, AvatarParts.hair(hair), AvatarLayouts.hair);
    }
    _draw(canvas, rect, AvatarParts.eyes(a.eyeIndex), AvatarLayouts.eyes);
    _draw(canvas, rect, AvatarParts.mouth(a.mouthIndex), AvatarLayouts.mouth);
    final acc = a.accessoryIndex % AvatarParts.accCount;
    if (acc > 0) {
      _draw(canvas, rect, AvatarParts.acc(acc),
          AvatarLayouts.accs[(acc - 1) % AvatarLayouts.accs.length]);
    }
    canvas.restore();
  }
}
