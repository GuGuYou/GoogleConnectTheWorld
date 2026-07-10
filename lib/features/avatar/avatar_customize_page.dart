import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/virtual_avatar_view.dart';

class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  static String _part(String slug, int n) =>
      'assets/images/avatars/parts/fig_${slug}_${(n + 2).toString().padLeft(2, '0')}.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final notifier = ref.read(avatarDraftProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GradientText(
          ref.tr('avatar_customize_title'),
          style: AppTextStyles.h2,
        ),
      ),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.neonYellow.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glowOrange.withValues(alpha: 0.25),
                        blurRadius: 36,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child:
                      VirtualAvatarView(avatar: avatar, size: 124, glow: true),
                ),
              ),
              const SizedBox(height: 22),
              _ColorRow(
                title: ref.tr('avatar_color'),
                iconAsset: _part('bg', -1),
                value: avatar.colorIndex,
                onTap: notifier.setColor,
              ),
              _PartRow(
                title: ref.tr('avatar_face'),
                slug: 'face',
                count: 3,
                value: avatar.faceIndex,
                onTap: notifier.setFace,
              ),
              _PartRow(
                title: ref.tr('avatar_eyes'),
                slug: 'eyes',
                count: 4,
                value: avatar.eyeIndex,
                onTap: notifier.setEyes,
              ),
              _PartRow(
                title: ref.tr('avatar_mouth'),
                slug: 'mouth',
                count: 4,
                value: avatar.mouthIndex,
                onTap: notifier.setMouth,
              ),
              _PartRow(
                title: ref.tr('avatar_accessory'),
                slug: 'acc',
                count: 5,
                value: avatar.accessoryIndex,
                onTap: notifier.setAccessory,
              ),
              const SizedBox(height: 22),
              NeonButton(
                label: ref.tr('avatar_save_next'),
                icon: Icons.check,
                onPressed: () {
                  ref
                      .read(currentUserProvider.notifier)
                      .updateVirtualAvatar(avatar);
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

/// Category row per the Figma comp: leading icon + gold label on the left,
/// thumbnail strip in an inset panel on the right.
class _CategoryRow extends StatelessWidget {
  final String title;
  final String iconAsset;
  final List<Widget> options;

  const _CategoryRow({
    required this.title,
    required this.iconAsset,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Image.asset(iconAsset, width: 24, height: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neonYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < options.length; i++) ...[
                        if (i != 0) const SizedBox(width: 6),
                        options[i],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  const _OptionBox({
    required this.selected,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 36,
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? AppColors.neonGreen : Colors.transparent,
            width: 1.4,
          ),
          color: selected
              ? AppColors.neonGreen.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}

class _PartRow extends StatelessWidget {
  final String title;
  final String slug;
  final int count;
  final int value;
  final ValueChanged<int> onTap;

  const _PartRow({
    required this.title,
    required this.slug,
    required this.count,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CategoryRow(
      title: title,
      iconAsset: AvatarCustomizePage._part(slug, -1),
      options: [
        for (var i = 0; i < count; i++)
          _OptionBox(
            selected: value == i,
            onTap: () => onTap(i),
            child: Image.asset(
              AvatarCustomizePage._part(slug, i),
              fit: BoxFit.contain,
            ),
          ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String title;
  final String iconAsset;
  final int value;
  final ValueChanged<int> onTap;

  const _ColorRow({
    required this.title,
    required this.iconAsset,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CategoryRow(
      title: title,
      iconAsset: iconAsset,
      options: [
        for (var i = 0; i < VirtualAvatarView.palettes.length; i++)
          _OptionBox(
            selected: value == i,
            onTap: () => onTap(i),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: VirtualAvatarView.palettes[i],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
