import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());

/// 地图默认中心（同步可用，不阻塞 UI）。
final mapCenterProvider = Provider<LatLng>((ref) {
  return ref.watch(locationServiceProvider).fallbackCenter;
});

/// 当前位置：后台尝试 GPS，失败降级到 Mock 中心点。
final currentLocationProvider = FutureProvider<LatLng>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return await service.current() ?? service.fallbackCenter;
});

/// 是否使用了真实 GPS（false 表示降级到 Mock 中心点）。
final usingRealLocationProvider = Provider<bool>((ref) {
  final loc = ref.watch(currentLocationProvider);
  final fallback = ref.watch(locationServiceProvider).fallbackCenter;
  return loc.maybeWhen(
    data: (pos) =>
        (pos.latitude - fallback.latitude).abs() > 1e-6 ||
        (pos.longitude - fallback.longitude).abs() > 1e-6,
    orElse: () => false,
  );
});
