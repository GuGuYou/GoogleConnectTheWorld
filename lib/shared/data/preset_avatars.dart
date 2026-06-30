/// 预设头像库（图片来自 DiceBear，已下载到 assets/avatars）。
/// 通过 seed 稳定映射到一张预设头像，让头像更生动、产品更吸引人。
class PresetAvatars {
  PresetAvatars._();

  static const int count = 16;

  /// 所有预设头像资源路径
  static final List<String> all = List.generate(
    count,
    (i) => 'assets/avatars/avatar_${(i + 1).toString().padLeft(2, '0')}.png',
  );

  /// 根据 seed 稳定取一张预设头像
  static String fromSeed(String seed) {
    final idx = seed.hashCode.abs() % count;
    return all[idx];
  }

  /// 资源路径 -> 是否合法预设
  static bool isPreset(String path) => path.startsWith('assets/avatars/');
}
