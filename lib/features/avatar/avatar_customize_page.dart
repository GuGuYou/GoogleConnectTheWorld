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
import 'widgets/layered_avatar.dart';
import 'widgets/virtual_avatar_view.dart';

/// Avatar customizer (Figma "Customize Avatar"): part rows over a live,
/// layer-composed watercolor avatar. Option chips show the part sprites
/// themselves (like the Figma comp); every choice updates the preview and
/// persists to [avatarDraftProvider].
class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final n = ref.read(avatarDraftProvider.notifier);

    final rows = <_RowCfg>[
      _RowCfg('avatar_face', Icons.face, AvatarParts.faceCount,
          avatar.faceIndex, n.setFace, AvatarParts.face),
      _RowCfg('avatar_hair', Icons.content_cut, AvatarParts.hairCount,
          avatar.hairIndex, n.setHair, (i) => i == 0 ? null : AvatarParts.hair(i)),
      _RowCfg('avatar_eyes', Icons.visibility, AvatarParts.eyeCount,
          avatar.eyeIndex, n.setEyes, AvatarParts.eyes),
      _RowCfg('avatar_mouth', Icons.sentiment_satisfied, AvatarParts.mouthCount,
          avatar.mouthIndex, n.setMouth, AvatarParts.mouth),
      _RowCfg('avatar_accessory', Icons.auto_awesome, AvatarParts.accCount,
          avatar.accessoryIndex, n.setAccessory,
          (i) => i == 0 ? null : AvatarParts.acc(i)),
      _RowCfg('avatar_background', Icons.gradient, AvatarParts.bgCount,
          avatar.backgroundIndex, n.setBackground, AvatarParts.bg,
          cover: true),
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

  /// Part sprite for option [i]; null renders the "none" chip.
  final String? Function(int) asset;

  /// Fill the chip (backgrounds) instead of containing with padding.
  final bool cover;

  const _RowCfg(this.labelKey, this.icon, this.count, this.value,
      this.onSelect, this.asset,
      {this.cover = false});
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
            width: 64,
            child: Text(
              ref.tr(cfg.labelKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                color: AppColors.neonYellow,
                fontWeight: FontWeight.w700,
                height: 1.15,
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
                      _OptionChip(
                        selected: cfg.value % cfg.count == i,
                        asset: cfg.asset(i),
                        cover: cfg.cover,
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

/// Option chip showing the part sprite itself (Figma comp style); a slashed
/// circle for the "none" option; gold ring when selected.
class _OptionChip extends StatelessWidget {
  final bool selected;
  final String? asset;
  final bool cover;
  final VoidCallback onTap;

  const _OptionChip({
    required this.selected,
    required this.asset,
    required this.cover,
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
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF17130A),
          ),
          clipBehavior: Clip.antiAlias,
          padding: cover || asset == null
              ? EdgeInsets.zero
              : const EdgeInsets.all(5),
          child: asset == null
              ? const Icon(Icons.block,
                  size: 16, color: AppColors.textMuted)
              : Image.asset(
                  asset!,
                  fit: cover ? BoxFit.cover : BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
        ),
      ),
    );
  }
}
