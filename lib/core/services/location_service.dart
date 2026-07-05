import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/data/mock_data_source.dart';

/// 定位服务：获取真实 GPS，失败时返回 null（上层降级到 Mock 中心点）。
class LocationService {
  const LocationService();

  static const _timeout = Duration(seconds: 5);

  Future<LatLng?> current() async {
    try {
      return await _currentImpl().timeout(_timeout);
    } catch (e, st) {
      debugPrint('LocationService.current failed: $e\n$st');
      return null;
    }
  }

  Future<LatLng?> _currentImpl() async {
    if (kIsWeb) {
      // Web 上权限弹窗/定位 API 可能长时间不返回，Demo 直接走 Mock 中心点。
      return null;
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 5),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Mock 降级中心点（深圳南山区）。
  LatLng get fallbackCenter => const LatLng(MockDataSource.centerLat, MockDataSource.centerLng);
}
