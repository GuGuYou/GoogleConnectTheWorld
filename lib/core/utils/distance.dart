import 'dart:math' as math;

/// Haversine 公式：根据经纬度计算两点间距离（单位：公里）
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

/// 格式化距离展示
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()}m';
  return '${km.toStringAsFixed(1)}km';
}
