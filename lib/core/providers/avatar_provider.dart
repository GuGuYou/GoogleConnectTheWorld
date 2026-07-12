import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/virtual_avatar.dart';

final avatarDraftProvider = NotifierProvider<AvatarDraftNotifier, VirtualAvatar>(
  AvatarDraftNotifier.new,
);

class AvatarDraftNotifier extends Notifier<VirtualAvatar> {
  /// 默认草稿：内置小男孩预设图。进入定制器改任意部件会切回 local
  /// 分层头像；AI 生成 / 导入照片会替换 generatedImageUrl。
  @override
  VirtualAvatar build() => VirtualAvatar.seeded('me_avatar_seed').copyWith(
        source: AvatarSource.photo,
        generatedImageUrl: kDefaultAvatarAsset,
      );

  /// 用户导入的照片（data URI）直接作为头像。
  void setPhoto(String dataUri) {
    state = state.copyWith(
      source: AvatarSource.photo,
      generatedImageUrl: dataUri,
    );
  }

  void setPresetAvatar(String assetPath) {
    state = state.copyWith(
      source: AvatarSource.photo,
      generatedImageUrl: 'asset:$assetPath',
    );
  }

  void setStyle(AvatarVisualStyle style) {
    state = state.copyWith(style: style, source: AvatarSource.local);
  }

  void setColor(int index) {
    state = state.copyWith(colorIndex: index, source: AvatarSource.local);
  }

  void setFace(int index) {
    state = state.copyWith(faceIndex: index, source: AvatarSource.local);
  }

  void setHair(int index) {
    state = state.copyWith(hairIndex: index, source: AvatarSource.local);
  }

  void setEyes(int index) {
    state = state.copyWith(eyeIndex: index, source: AvatarSource.local);
  }

  void setMouth(int index) {
    state = state.copyWith(mouthIndex: index, source: AvatarSource.local);
  }

  void setAccessory(int index) {
    state = state.copyWith(accessoryIndex: index, source: AvatarSource.local);
  }

  /// Background selection also drives the avatar's theme color so the
  /// procedural avatar (shown elsewhere) matches the chosen backdrop.
  void setBackground(int index) {
    state = state.copyWith(
      backgroundIndex: index,
      colorIndex: index,
      source: AvatarSource.local,
    );
  }

  void applyGenerated(VirtualAvatar avatar) {
    state = avatar;
  }
}
