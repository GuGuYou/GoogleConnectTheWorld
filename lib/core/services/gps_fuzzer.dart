import 'dart:math';

/// GPS 坐标模糊化工具：保护用户位置隐私，遵守 GDPR 等数据出境法规。
///
/// 策略：
/// 1. 格网截断：将坐标 snap 到 ~0.001° 格网（约 111m × 111m 在赤道附近）
/// 2. 随机抖动：在格网内加 ±0.0004° 随机偏移（约 ±44m）
/// 3. 总体精度控制在 ~100m 级别
///
/// 使用方式：
/// - 客户端本地仍用原始 GPS 做距离计算（haversine 等）
/// - 发送到服务端/他人可见的数据使用 fuzzed 坐标
/// - 服务端日志只记录格网 ID，不记录模糊坐标
class GpsFuzzer {
  GpsFuzzer._();

  /// 格网精度：约 0.001° ≈ 111m（纬度方向），经度方向随纬度缩放
  static const double _gridDegrees = 0.001;

  /// 随机抖动幅度：格网内 ±0.0004° ≈ ±44m
  static const double _jitterAmplitude = 0.0004;

  static final _rng = Random();

  /// 对原始坐标进行模糊化。
  ///
  /// 返回的坐标精度约为 100m 级别，无法反推出精确位置。
  static ({double lat, double lng}) fuzz(double lat, double lng) {
    final snappedLat = _snapToGrid(lat);
    final snappedLng = _snapToGrid(lng);

    final jitteredLat = snappedLat + (_rng.nextDouble() - 0.5) * 2 * _jitterAmplitude;
    final jitteredLng = snappedLng + (_rng.nextDouble() - 0.5) * 2 * _jitterAmplitude;

    return (lat: _round6(jitteredLat), lng: _round6(jitteredLng));
  }

  /// 批量模糊化，保证同一位置多次调用结果一致（使用预计算 jitter）。
  /// 用于 Mock 数据初始化时保证一致性。
  static ({double lat, double lng}) fuzzSeeded(double lat, double lng, int seed) {
    final r = Random(seed);
    final snappedLat = _snapToGrid(lat);
    final snappedLng = _snapToGrid(lng);

    final jitteredLat = snappedLat + (r.nextDouble() - 0.5) * 2 * _jitterAmplitude;
    final jitteredLng = snappedLng + (r.nextDouble() - 0.5) * 2 * _jitterAmplitude;

    return (lat: _round6(jitteredLat), lng: _round6(jitteredLng));
  }

  /// 获取坐标对应的格网 ID（用于日志脱敏）。
  ///
  /// 格式："grid_22.543_113.942"
  static String gridId(double lat, double lng) {
    final gLat = _snapToGrid(lat);
    final gLng = _snapToGrid(lng);
    return 'grid_${gLat.toStringAsFixed(3)}_${gLng.toStringAsFixed(3)}';
  }

  /// 将坐标截断到 0.001° 精度格网
  static double _snapToGrid(double coord) {
    return (coord / _gridDegrees).round() * _gridDegrees;
  }

  static double _round6(double v) {
    return (v * 1e6).round() / 1e6;
  }
}
