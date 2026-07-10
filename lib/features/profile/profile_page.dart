import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/avatar/widgets/virtual_avatar_view.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/hexagon.dart';
import '../../shared/widgets/neon_background.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final myActivities =
        ref.watch(activitiesProvider).where((a) => a.joined).length;

    return NeonBackground(
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -40,
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                'assets/images/decorations/fig_constellation.png',
                width: 225,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HexIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/profile/settings'),
                    ),
                  ],
                ),
                // Hero
                Center(
                  child: Column(
                    children: [
                      me.virtualAvatar != null
                          ? VirtualAvatarView(
                              avatar: me.virtualAvatar!,
                              size: 96,
                              glow: true,
                              online: true,
                              heroPlaceholder: true)
                          : AvatarPlaceholder(
                              seed: me.avatarSeed,
                              label: me.nickname,
                              size: 96,
                              glow: true,
                              online: true),
                      const SizedBox(height: 14),
                      GradientText(me.nickname, style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ID: ${me.id} · ${me.city}',
                              style: AppTextStyles.caption),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 12, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        me.bio,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 数据卡
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _stat('${me.tags.length}', ref.tr('edit_tags')),
                        _vDivider(),
                        _stat('$myActivities', ref.tr('profile_activities')),
                        _vDivider(),
                        _stat('${me.matchRate(me.tags) > 0 ? 99 : 88}',
                            ref.tr('match_rate')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // 功能入口
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      _Entry(
                        icon: Icons.edit_outlined,
                        label: ref.tr('profile_edit'),
                        sublabel: ref.tr('profile_edit_sub'),
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _Entry(
                        icon: Icons.face_retouching_natural,
                        label: ref.tr('avatar_recreate'),
                        sublabel: ref.tr('profile_avatar_sub'),
                        onTap: () =>
                            context.push('/avatar-setup?return=/profile'),
                      ),
                      _Entry(
                        icon: Icons.celebration_outlined,
                        label: ref.tr('profile_activities'),
                        sublabel: ref.tr('profile_activities_sub'),
                        onTap: () => context.push('/activity'),
                      ),
                      _Entry(
                        icon: Icons.settings_outlined,
                        label: ref.tr('profile_settings'),
                        sublabel: ref.tr('profile_settings_sub'),
                        onTap: () => context.push('/profile/settings'),
                      ),
                      _Entry(
                        icon: Icons.info_outline,
                        label: ref.tr('setting_about'),
                        sublabel: ref.tr('profile_about_sub'),
                        onTap: () => context.push('/profile/about'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.number),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.divider,
    );
  }
}

/// Hexagonal icon tile used for the settings button and entry leading icons.
class _HexIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HexIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const HexagonClipper(),
        child: Container(
          width: 37,
          height: 37,
          color: AppColors.hexFill.withValues(alpha: 0.3),
          child: Icon(icon, size: 18, color: AppColors.neonYellow),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _Entry({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            _HexIconButton(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.title),
                  const SizedBox(height: 2),
                  Text(sublabel, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
