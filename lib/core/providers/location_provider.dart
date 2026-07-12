import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

export '../services/location_service.dart' show LocationFix;

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

/// 地图默认中心（同步可用，不阻塞 UI）。
final mapCenterProvider = Provider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).fallbackCenter;
});

/// 当前位置：后台尝试 GPS，失败降级到 Mock 中心点。
final currentLocationProvider = FutureProvider<LocationFix>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.currentFix();
});

/// 是否使用了真实 GPS（false 表示降级到 Mock 中心点）。
final usingRealLocationProvider = Provider<bool>((ref) {
  return ref.watch(currentLocationProvider).maybeWhen(
    data: (fix) => fix.isReal,
    orElse: () => false,
  );
});
