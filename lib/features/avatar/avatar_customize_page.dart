import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/virtual_avatar_view.dart';

class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final notifier = ref.read(avatarDraftProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('avatar_customize_title'))),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: VirtualAvatarView(avatar: avatar, size: 150, glow: true)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StyleSegment(
                      label: ref.tr('avatar_style_cute'),
                      active: avatar.style == AvatarVisualStyle.cute,
                      onTap: () => notifier.setStyle(AvatarVisualStyle.cute),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StyleSegment(
                      label: ref.tr('avatar_style_pixel'),
                      active: avatar.style == AvatarVisualStyle.pixel,
                      onTap: () => notifier.setStyle(AvatarVisualStyle.pixel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Selector(title: ref.tr('avatar_color'), count: 6, value: avatar.colorIndex, onTap: notifier.setColor),
              _Selector(title: ref.tr('avatar_face'), count: 3, value: avatar.faceIndex, onTap: notifier.setFace),
              _Selector(title: ref.tr('avatar_eyes'), count: 4, value: avatar.eyeIndex, onTap: notifier.setEyes),
              _Selector(title: ref.tr('avatar_mouth'), count: 4, value: avatar.mouthIndex, onTap: notifier.setMouth),
              _Selector(title: ref.tr('avatar_accessory'), count: 5, value: avatar.accessoryIndex, onTap: notifier.setAccessory),
              const SizedBox(height: 22),
              NeonButton(
                label: ref.tr('avatar_save_next'),
                icon: Icons.check,
                onPressed: () {
                  ref.read(currentUserProvider.notifier).updateVirtualAvatar(avatar);
                  context.go(returnLocation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleSegment extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StyleSegment({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? AppColors.cyanPurple : null,
          color: active ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? Colors.transparent : AppColors.glassBorder),
        ),
        child: Text(label, style: active ? AppTextStyles.button : AppTextStyles.body),
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  final String title;
  final int count;
  final int value;
  final ValueChanged<int> onTap;

  const _Selector({required this.title, required this.count, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < count; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: value == i ? AppColors.pinkPurple : null,
                            color: value == i ? null : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: value == i ? Colors.transparent : AppColors.glassBorder),
                          ),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: value == i ? AppTextStyles.button : AppTextStyles.caption),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
