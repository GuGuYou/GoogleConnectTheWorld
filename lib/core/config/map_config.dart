import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Google Maps 配置：API Key 与暗色地图样式。
class MapConfig {
  MapConfig._();

  static String? _apiKey;
  static bool _loaded = false;

  /// 留言点聚合半径（米）
  static const double wallClusterRadiusMeters = 100;

  /// 雷达最大扫描半径（公里），以用户位置为中心。
  /// 决定地图初始视野、雷达同心圆最外圈，以及活动/用户/留言板图标的可见范围。
  static const double radarMaxRangeKm = 3.0;

  /// 雷达圆环与中心标记颜色（亮青色，与深蓝底图高对比）。
  static const Color radarColor = Color(0xFF5CEFFF);

  /// 雷达最大扫描半径（米）
  static double get radarMaxRangeMeters => radarMaxRangeKm * 1000;

  /// 雷达同心圆环半径（米）：内、中、外三圈，最外圈等于 [radarMaxRangeMeters]。
  static List<double> get radarRingRadiiMeters => [
        radarMaxRangeMeters / 3,
        radarMaxRangeMeters * 2 / 3,
        radarMaxRangeMeters,
      ];

  /// 根据纬度计算初始缩放级别，使视野直径约为 [radarMaxRangeKm] 的 2 倍。
  static double initialZoomForLatitude(double latitude, {double viewportHeightPx = 480}) {
    const earthCircumference = 40075016.686;
    const diameterMeters = radarMaxRangeKm * 2000 * 1.1;
    final latRad = latitude * math.pi / 180;
    final metersPerPixel = diameterMeters / viewportHeightPx;
    final zoom = math.log(earthCircumference * math.cos(latRad) / (256 * metersPerPixel)) / math.ln2;
    return zoom.clamp(10.0, 18.0);
  }

  /// 从 secrets/google_maps_api_key.json 加载 API Key。
  static Future<String?> loadApiKey() async {
    if (_loaded) return _apiKey;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString('secrets/google_maps_api_key.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final key = (json['apiKey'] as String?)?.trim();
      _apiKey = (key != null && key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY') ? key : null;
    } catch (_) {
      _apiKey = null;
    }
    return _apiKey;
  }

  static bool get hasValidApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  /// 深蓝底 + 黄色线稿地图样式（无 POI、无标签）。
  static const String mapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"elementType":"labels","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"landscape.man_made","elementType":"geometry","stylers":[{"color":"#1e2844"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"poi.park","elementType":"geometry.stroke","stylers":[{"color":"#fbbc05"},{"weight":1}]},
  {"featureType":"poi.park","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e8b923"},{"weight":1}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"road.arterial","elementType":"geometry.stroke","stylers":[{"color":"#fbbc05"},{"weight":1}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#ffd54f"},{"weight":2}]},
  {"featureType":"road.local","elementType":"geometry","stylers":[{"color":"#1a2238"}]},
  {"featureType":"road.local","elementType":"geometry.stroke","stylers":[{"color":"#c9a227"},{"weight":1}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#141c30"}]},
  {"featureType":"water","elementType":"geometry.stroke","stylers":[{"color":"#fbbc05"},{"weight":1}]},
  {"featureType":"water","elementType":"labels","stylers":[{"visibility":"off"}]}
]
''';
}
