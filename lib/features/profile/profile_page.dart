import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final myActivities = ref.watch(activitiesProvider).where((a) => a.joined).length;

    return NeonBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => context.push('/profile/settings'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            // Hero
            Center(
              child: Column(
                children: [
                  AvatarPlaceholder(seed: me.avatarSeed, label: me.nickname, size: 100, glow: true, online: true),
                  const SizedBox(height: 14),
                  GradientText(me.nickname, style: AppTextStyles.h1),
                  const SizedBox(height: 4),
                  Text('ID: ${me.id} · ${me.city}', style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  Text(me.bio, textAlign: TextAlign.center, style: AppTextStyles.body),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 数据卡
            Row(
              children: [
                _stat('${me.tags.length}', ref.tr('edit_tags')),
                _stat('$myActivities', ref.tr('profile_activities')),
                _stat('${me.matchRate(me.tags) > 0 ? 99 : 88}', ref.tr('match_rate')),
              ],
            ),
            const SizedBox(height: 24),
            // 标签墙
            Text(ref.tr('edit_tags'), style: AppTextStyles.title),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final t in me.tags) IpTagChip(tag: t)],
            ),
            const SizedBox(height: 24),
            // 功能入口
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _entry(context, Icons.edit_outlined, ref.tr('profile_edit'), '/profile/edit'),
                  const Divider(height: 1, color: AppColors.divider),
                  _entry(context, Icons.celebration_outlined, ref.tr('profile_activities'), '/activity'),
                  const Divider(height: 1, color: AppColors.divider),
                  _entry(context, Icons.settings_outlined, ref.tr('profile_settings'), '/profile/settings'),
                  const Divider(height: 1, color: AppColors.divider),
                  _entry(context, Icons.info_outline, ref.tr('setting_about'), '/profile/about'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.number.copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      onTap: () => context.push(route),
      leading: Icon(icon, color: AppColors.neonCyan),
      title: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}
