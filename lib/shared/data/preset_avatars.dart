import '../models/virtual_avatar.dart';

/// 预设头像库（mock / 演示用户照片，位于 assets/avatars_1）。
/// 通过 index 稳定映射，避免 seed hash 碰撞导致多人同头像。
class PresetAvatars {
  PresetAvatars._();

  static const int count = 7;

  /// 所有预设头像资源路径
  static final List<String> all = List.generate(
    count,
    (i) => 'assets/avatars_1/avatar-${i + 1}.jpg',
  );

  /// 根据 index 取预设头像路径（稳定、无 hash 碰撞）
  static String atIndex(int index) => all[index.abs() % count];

  /// 根据 seed 稳定取一张预设头像路径（兼容旧调用）
  static String fromSeed(String seed) {
    final idx = seed.hashCode.abs() % count;
    return all[idx];
  }

  /// 按 index 生成带照片的 [VirtualAvatar]
  static VirtualAvatar asVirtualAvatarAt(int index) {
    final i = index.abs() % count;
    final base = VirtualAvatar.seeded('preset_$i');
    return base.copyWith(
      source: AvatarSource.photo,
      generatedImageUrl: 'asset:${all[i]}',
    );
  }

  /// 根据 seed 生成带照片的 [VirtualAvatar]（供 mock 用户使用）
  static VirtualAvatar asVirtualAvatar(String seed) {
    final base = VirtualAvatar.seeded(seed);
    return base.copyWith(
      source: AvatarSource.photo,
      generatedImageUrl: 'asset:${fromSeed(seed)}',
    );
  }

  /// 资源路径 -> 是否合法预设
  static bool isPreset(String path) => path.startsWith('assets/avatars_1/');
}
