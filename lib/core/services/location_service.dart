import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../shared/data/mock_data_source.dart';

/// 定位结果：区分真实 GPS 与 Mock 降级，避免仅靠坐标比对误判。
class LocationFix {
  const LocationFix({required this.position, required this.isReal});

  final LatLng position;
  final bool isReal;
}

/// 定位服务：获取真实 GPS，失败时返回 null（上层降级到 Mock 中心点）。
class LocationService {
  const LocationService();

  Future<LatLng?> current() async {
    try {
      return await _currentImpl();
    } catch (e, st) {
      debugPrint('LocationService.current failed: $e\n$st');
      return null;
    }
  }

  Future<LocationFix> currentFix() async {
    final real = await current();
    if (real != null) return LocationFix(position: real, isReal: true);
    return LocationFix(position: fallbackCenter, isReal: false);
  }

  Future<LatLng?> _currentImpl() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      debugPrint('LocationService: location services disabled');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    debugPrint('LocationService: permission=$permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('LocationService: after request permission=$permission');
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: _settingsForPlatform(),
    );
    debugPrint('LocationService: got ${pos.latitude}, ${pos.longitude}');
    return LatLng(pos.latitude, pos.longitude);
  }

  LocationSettings _settingsForPlatform() {
    if (kIsWeb) {
      // geolocator_web 把 timeLimit.inMicroseconds 误当作 PositionOptions.timeout（毫秒）。
      // Duration(microseconds: 15000) → 浏览器超时 15s。
      // maximumAge 允许返回缓存坐标，权限已开时通常能立刻拿到结果。
      return WebSettings(
        accuracy: LocationAccuracy.low,
        maximumAge: const Duration(minutes: 5),
        timeLimit: const Duration(microseconds: 15000),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 8),
    );
  }

  /// Mock 降级中心点（深圳南山区）。
  LatLng get fallbackCenter => const LatLng(MockDataSource.centerLat, MockDataSource.centerLng);
}
