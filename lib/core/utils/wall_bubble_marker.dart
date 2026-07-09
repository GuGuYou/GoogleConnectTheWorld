import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/map_marker_icons.dart';
import 'map_icon_bitmap.dart';

/// 留言板地图标记：圆角半透明六边形（与活动、用户样式一致）。
class WallBubbleMarker {
  WallBubbleMarker._();

  static final _cache = <int, BitmapDescriptor>{};

  static Future<BitmapDescriptor> iconFor(Color color) async {
    final key = Object.hash(MapMarkerIcons.wallMessage.codePoint, color.toARGB32());
    final cached = _cache[key];
    if (cached != null) return cached;

    final descriptor = await MapIconBitmap.pin(
      icon: MapMarkerIcons.wallMessage,
      color: color,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  /// 开发时改图标后若仍不刷新，可热重启（Hot Restart）或调用此方法清缓存。
  static void clearCache() => _cache.clear();
}
