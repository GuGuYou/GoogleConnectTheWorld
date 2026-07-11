import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/virtual_avatar.dart';

final avatarDraftProvider = NotifierProvider<AvatarDraftNotifier, VirtualAvatar>(
  AvatarDraftNotifier.new,
);

class AvatarDraftNotifier extends Notifier<VirtualAvatar> {
  @override
  VirtualAvatar build() => VirtualAvatar.seeded('me_avatar_seed');

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
