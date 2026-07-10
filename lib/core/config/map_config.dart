import 'dart:convert';
import 'dart:math' as math;

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

  /// 暗色赛博风格地图样式（替代原 OSM ColorFiltered 方案）。
  static const String neonDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d1d35"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a1a2e"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.land_parcel","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181830"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c54"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373773"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d3d8c"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f1f45"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#616161"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e0e1f"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
]
''';
}
