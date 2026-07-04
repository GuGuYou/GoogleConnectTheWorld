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
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gugu_mascot.dart';
import '../../shared/widgets/neon_background.dart';

/// 成长中心：连续打卡 Streak + 等级 + 每日任务 + 同好度等级（参考 Duolingo）
class RewardsPage extends ConsumerWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final g = ref.watch(gamificationProvider);
    final mood = g.checkedToday ? GuguMood.cheer : GuguMood.happy;

    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('rewards_title'))),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            // 吉祥物 + Streak
            Center(
              child: GuguMascot(
                mood: mood,
                bubble: g.checkedToday
                    ? (lang == 'en' ? 'See you tomorrow!' : '明天也要来哦！')
                    : (lang == 'en' ? 'Keep the streak!' : '别断签呀～'),
              ),
            ),
            const SizedBox(height: 16),
            // Streak 卡
            GlassCard(
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g.streak} ${ref.tr('day_streak')}', style: AppTextStyles.h2),
                      Text(ref.tr('streak_desc'), style: AppTextStyles.caption),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => ref.read(gamificationProvider.notifier).checkInToday(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: g.checkedToday ? null : AppColors.pinkPurple,
                        color: g.checkedToday ? AppColors.bg2 : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        g.checkedToday ? ref.tr('checked_in') : ref.tr('check_in'),
                        style: TextStyle(color: g.checkedToday ? AppColors.textMuted : Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 等级进度
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Lv.${g.level}', style: AppTextStyles.number.copyWith(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(ref.tr('level_label'), style: AppTextStyles.body),
                      const Spacer(),
                      Text('${g.xpInLevel}/100 XP', style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: g.xpInLevel / 100,
                      minHeight: 10,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.neonCyan),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 每日任务
            Text('📋 ${ref.tr('daily_tasks')}', style: AppTextStyles.title),
            const SizedBox(height: 12),
            for (final t in g.tasks) _TaskRow(task: t, lang: lang),
            const SizedBox(height: 24),
            // 同好度等级体系
            Text('💞 ${ref.tr('relation_levels')}', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text(ref.tr('relation_desc'), style: AppTextStyles.caption),
            const SizedBox(height: 12),
            for (final lv in kRelationLevels)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lv.color.withValues(alpha: 0.18),
                        border: Border.all(color: lv.color),
                      ),
                      child: Icon(lv.icon, color: lv.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text('Lv.${lv.level} ${lv.name(lang)}', style: AppTextStyles.bodyStrong),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  final DailyTask task;
  final String lang;
  const _TaskRow({required this.task, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: task.done ? AppColors.neonGreen : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(task.icon, color: task.done ? AppColors.neonGreen : AppColors.neonCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title(lang), style: AppTextStyles.bodyStrong),
                  Text('+${task.xp} XP', style: AppTextStyles.caption.copyWith(color: AppColors.neonYellow)),
                ],
              ),
            ),
            if (task.done)
              const Icon(Icons.check_circle, color: AppColors.neonGreen)
                  .animate()
                  .scale(curve: Curves.easeOutBack)
            else
              GestureDetector(
                onTap: () => ref.read(gamificationProvider.notifier).progressTask(task.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(gradient: AppColors.cyanPurple, borderRadius: BorderRadius.circular(16)),
                  child: Text(ref.tr('go_do'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
