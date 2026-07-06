import 'dart:convert';

import 'package:flutter/services.dart';

/// Google Maps 配置：API Key 与暗色地图样式。
class MapConfig {
  MapConfig._();

  static String? _apiKey;
  static bool _loaded = false;

  /// 留言点聚合半径（米）
  static const double wallClusterRadiusMeters = 100;

  /// 留言板地图可见半径（公里）
  static const double wallVisibleRadiusKm = 2.0;

  /// 从 gitignored 的 secrets JSON 加载 API Key。
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
