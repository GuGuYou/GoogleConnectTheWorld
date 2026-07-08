import 'dart:math' as math;

/// Haversine 公式：根据经纬度计算两点间距离（单位：公里）
///
/// 注意：由于 GPS 模糊化（GpsFuzzer）的存在，实际展示给用户的坐标精度约为 ~100m。
/// 距离计算仍使用原始精度，但展示时建议配合 formatDistance 做模糊处理。
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371.0; // km
  final dLat = _deg2rad(lat2 - lat1);
  final dLng = _deg2rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _deg2rad(double deg) => deg * (math.pi / 180.0);

/// 判断两点距离是否在指定公里范围内
bool isWithinKm(double lat1, double lng1, double lat2, double lng2, double maxKm) {
  return haversineKm(lat1, lng1, lat2, lng2) <= maxKm;
}

/// 格式化距离展示（模糊化：<100m 显示 "附近"，避免暴露精确距离）
String formatDistance(double km, {bool fuzzy = false}) {
  if (fuzzy) {
    if (km < 0.1) return '附近';
    if (km < 0.5) return '500m内';
    if (km < 1) return '1km内';
    return '${km.round()}km内';
  }
  if (km < 1) return '${(km * 1000).round()}m';
  return '${km.toStringAsFixed(1)}km';
}

/// 模糊化距离展示："附近" / "500m内" / "1km内" / "2km内" 等
String formatDistanceFuzzy(double km) => formatDistance(km, fuzzy: true);
