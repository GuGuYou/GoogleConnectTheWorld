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
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/minimal_avatar.dart';
import 'widgets/virtual_avatar_view.dart';

/// Avatar customizer (Figma "Customize Avatar"): six part rows over a live,
/// procedurally-composed minimal avatar. Every choice updates the preview and
/// each thumbnail instantly, and persists to [avatarDraftProvider].
class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final n = ref.read(avatarDraftProvider.notifier);

    final rows = <_RowCfg>[
      _RowCfg('avatar_face', Icons.face, 5, avatar.faceIndex, n.setFace,
          (i) => avatar.copyWith(faceIndex: i)),
      _RowCfg('avatar_eyes', Icons.visibility, 5, avatar.eyeIndex, n.setEyes,
          (i) => avatar.copyWith(eyeIndex: i)),
      _RowCfg('avatar_mouth', Icons.sentiment_satisfied, 5, avatar.mouthIndex,
          n.setMouth, (i) => avatar.copyWith(mouthIndex: i)),
      _RowCfg('avatar_accessory', Icons.auto_awesome, 5, avatar.accessoryIndex,
          n.setAccessory, (i) => avatar.copyWith(accessoryIndex: i)),
      _RowCfg('avatar_background', Icons.gradient, 5, avatar.backgroundIndex,
          n.setBackground, (i) => avatar.copyWith(backgroundIndex: i)),
    ];

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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.neonYellow.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glowOrange.withValues(alpha: 0.28),
                        blurRadius: 34,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: VirtualAvatarView(avatar: avatar, size: 124),
                ),
              ),
              const SizedBox(height: 22),
              for (final r in rows) ...[
                _PartRow(cfg: r),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 10),
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

class _RowCfg {
  final String labelKey;
  final IconData icon;
  final int count;
  final int value;
  final ValueChanged<int> onSelect;
  final VirtualAvatar Function(int) preview;
  const _RowCfg(this.labelKey, this.icon, this.count, this.value,
      this.onSelect, this.preview);
}

class _PartRow extends ConsumerWidget {
  final _RowCfg cfg;
  const _PartRow({required this.cfg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Icon(cfg.icon, size: 22, color: AppColors.neonYellow),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(
              ref.tr(cfg.labelKey),
              maxLines: 2,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.neonYellow,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(7),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < cfg.count; i++) ...[
                      if (i != 0) const SizedBox(width: 6),
                      _OptionAvatar(
                        selected: cfg.value == i,
                        avatar: cfg.preview(i),
                        onTap: () => cfg.onSelect(i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionAvatar extends StatelessWidget {
  final bool selected;
  final VirtualAvatar avatar;
  final VoidCallback onTap;

  const _OptionAvatar({
    required this.selected,
    required this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.neonGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipOval(
          child: CustomPaint(painter: MinimalAvatarPainter(avatar)),
        ),
      ),
    );
  }
}
