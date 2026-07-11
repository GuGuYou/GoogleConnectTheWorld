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

/// Avatar customizer matching the Figma "Customize Avatar" frame: six part
/// rows (Face Shape / Hairstyle / Eyes / Mouth / Accessory / Background),
/// each a thumbnail strip + colour wheel. All selections persist to
/// [avatarDraftProvider]; the background choice composites live behind the
/// 3D hero. (Face/hair/eyes/mouth/accessory persist but aren't composited on
/// the static hero — that needs layered art or the AI-generated avatar.)
class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  static const _dir = 'assets/images/avatars/parts';
  static const _wheel = '$_dir/fig_face_07.png';

  static String _icon(String slug) => '$_dir/fig_${slug}_01.png';
  static String _opt(String slug, int i) =>
      '$_dir/fig_${slug}_${(i + 2).toString().padLeft(2, '0')}.png';
  static String _bg(int i) => _opt('bg', i);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final n = ref.read(avatarDraftProvider.notifier);

    final rows = <_RowCfg>[
      _RowCfg('avatar_face', 'face', 5, avatar.faceIndex, n.setFace),
      _RowCfg('avatar_hair', 'hair', 4, avatar.hairIndex, n.setHair),
      _RowCfg('avatar_eyes', 'eyes', 5, avatar.eyeIndex, n.setEyes),
      _RowCfg('avatar_mouth', 'mouth', 5, avatar.mouthIndex, n.setMouth),
      _RowCfg('avatar_accessory', 'acc', 5, avatar.accessoryIndex,
          n.setAccessory),
      _RowCfg('avatar_background', 'bg', 5, avatar.backgroundIndex,
          n.setBackground),
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
              Center(child: _Preview(bgIndex: avatar.backgroundIndex)),
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
  final String slug;
  final int count;
  final int value;
  final ValueChanged<int> onSelect;
  const _RowCfg(
      this.labelKey, this.slug, this.count, this.value, this.onSelect);
}

/// 3D hero avatar composited over the selected background orb (live).
class _Preview extends StatelessWidget {
  final int bgIndex;
  const _Preview({required this.bgIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.neonYellow.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowOrange.withValues(alpha: 0.3),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AvatarCustomizePage._bg(bgIndex), fit: BoxFit.cover),
            Image.asset(
              'assets/images/avatars/fig_avatar_hero.png',
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
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
          Image.asset(AvatarCustomizePage._icon(cfg.slug),
              width: 24, height: 24),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
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
              height: 44,
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
                      _OptionBox(
                        selected: cfg.value == i,
                        asset: AvatarCustomizePage._opt(cfg.slug, i),
                        onTap: () => cfg.onSelect(i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Colour wheel — cycles the row to the next option.
          GestureDetector(
            onTap: () => cfg.onSelect((cfg.value + 1) % cfg.count),
            child: Image.asset(AvatarCustomizePage._wheel,
                width: 26, height: 26),
          ),
        ],
      ),
    );
  }
}

class _OptionBox extends StatelessWidget {
  final bool selected;
  final String asset;
  final VoidCallback onTap;

  const _OptionBox({
    required this.selected,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 34,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? AppColors.neonGreen : Colors.transparent,
            width: 1.4,
          ),
          color: selected
              ? AppColors.neonGreen.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
