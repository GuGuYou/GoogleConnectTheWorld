import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/gamification.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final me = ref.watch(currentUserProvider);
    final g = ref.watch(gamificationProvider);
    final myActivities = ref.watch(activitiesProvider).where((a) => a.joined).length;
    final personality = personalityOf(me.personality);

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
                  Hero(
                    tag: 'avatar_me',
                    child: AvatarPlaceholder(seed: me.avatarSeed, label: me.nickname, size: 100, glow: true, online: true),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GradientText(me.nickname, style: AppTextStyles.h1),
                      if (me.verified) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: AppColors.neonCyan, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('ID: ${me.id} · ${me.city}', style: AppTextStyles.caption),
                  const SizedBox(height: 10),
                  // 状态选择器（参考 Discord）
                  _StatusSelector(current: me.status, lang: lang),
                  const SizedBox(height: 12),
                  Text(me.bio, textAlign: TextAlign.center, style: AppTextStyles.body),
                  if (personality != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: personality.color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: personality.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(personality.icon, size: 14, color: personality.color),
                          const SizedBox(width: 6),
                          Text(personality.name(lang), style: TextStyle(color: personality.color, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 数据卡（玻璃面板 + 分隔线，更通透）
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  _stat('Lv.${g.level}', ref.tr('level_label')),
                  _statDivider(),
                  _stat('${g.streak}', ref.tr('day_streak')),
                  _statDivider(),
                  _stat('$myActivities', ref.tr('profile_activities')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 成长中心入口（Streak + 任务）
            GestureDetector(
              onTap: () => context.push('/profile/rewards'),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: AppColors.cyanPurple,
                  boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 30)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${g.streak} ${ref.tr('day_streak')}', style: AppTextStyles.bodyStrong.copyWith(color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('${g.tasksDone}/${g.tasks.length} ${ref.tr('daily_tasks')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, curve: Curves.easeOut),
            const SizedBox(height: 32),
            // 标签墙
            Row(
              children: [
                const Icon(Icons.tag, size: 18, color: AppColors.neonPink),
                const SizedBox(width: 6),
                Text(ref.tr('edit_tags'), style: AppTextStyles.title),
                const Spacer(),
                Text('${me.tags.length}', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 12,
              children: [for (final t in me.tags) IpTagChip(tag: t)],
            ),
            const SizedBox(height: 32),
            // 功能入口
            Text(ref.tr('profile_settings'), style: AppTextStyles.title),
            const SizedBox(height: 14),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _entry(context, Icons.edit_outlined, ref.tr('profile_edit'), '/profile/edit'),
                  _divider(),
                  _entry(context, Icons.emoji_events_outlined, ref.tr('rewards_entry'), '/profile/rewards'),
                  _divider(),
                  _entry(context, Icons.psychology_outlined, ref.tr('personality_entry'), '/profile/personality'),
                  _divider(),
                  _entry(context, Icons.celebration_outlined, ref.tr('profile_activities'), '/activity'),
                  _divider(),
                  _entry(context, Icons.settings_outlined, ref.tr('profile_settings'), '/profile/settings'),
                  _divider(),
                  _entry(context, Icons.info_outline, ref.tr('setting_about'), '/profile/about'),
                ],
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 350.ms).slideY(begin: 0.1, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: AppColors.divider,
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, color: AppColors.divider),
      );

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.number.copyWith(fontSize: 26)),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      onTap: () => context.push(route),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.neonCyan),
      title: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    );
  }
}

/// 状态选择器：在线 / 空闲 / 请勿打扰 / 活动中（参考 Discord）
class _StatusSelector extends ConsumerWidget {
  final UserStatus current;
  final String lang;
  const _StatusSelector({required this.current, required this.lang});

  Color _color(UserStatus s) {
    switch (s) {
      case UserStatus.online:
        return AppColors.neonGreen;
      case UserStatus.idle:
        return AppColors.neonYellow;
      case UserStatus.dnd:
        return AppColors.neonPink;
      case UserStatus.inEvent:
        return AppColors.neonCyan;
      case UserStatus.offline:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _pick(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color(current).withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: _color(current), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(current.label(lang), style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _pick(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(ref.tr('my_status'), style: AppTextStyles.title),
            ),
            for (final s in UserStatus.values)
              ListTile(
                leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: _color(s), shape: BoxShape.circle)),
                title: Text(s.label(lang), style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                trailing: s == current ? const Icon(Icons.check, color: AppColors.neonCyan) : null,
                onTap: () {
                  ref.read(currentUserProvider.notifier).updateStatus(s);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
