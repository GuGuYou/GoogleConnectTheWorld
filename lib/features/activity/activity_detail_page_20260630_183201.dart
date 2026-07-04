import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

class ActivityDetailPage extends ConsumerWidget {
  final String activityId;
  const ActivityDetailPage({super.key, required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final activities = ref.watch(activitiesProvider);
    final a = activities.firstWhere((e) => e.id == activityId);
    final host = ref.read(mockProvider).userById(a.hostId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.bg0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const CircleAvatar(backgroundColor: Colors.black38, child: Icon(Icons.arrow_back, color: Colors.white)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [a.tag.color, AppColors.bg0],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: Icon(a.tag.icon, size: 96, color: Colors.white24)),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.bg0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title(lang), style: AppTextStyles.h1),
                  const SizedBox(height: 12),
                  IpTagChip(tag: a.tag),
                  const SizedBox(height: 20),
                  _info(Icons.schedule, DateFormat('yyyy-MM-dd  HH:mm').format(a.time)),
                  _info(Icons.location_on_outlined, a.location(lang)),
                  _info(Icons.group_outlined, '${a.participants} / ${a.maxParticipants} ${ref.tr('activity_participants')}'),
                  const SizedBox(height: 20),
                  // 主办人
                  Row(
                    children: [
                      AvatarPlaceholder(seed: host.avatarSeed, label: host.nickname, size: 44),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.tr('activity_host'), style: AppTextStyles.caption),
                          Text(host.nickname, style: AppTextStyles.bodyStrong),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 参与者头像堆叠
                  SizedBox(
                    height: 40,
                    child: Stack(
                      children: [
                        for (var i = 0; i < a.participantAvatarSeeds.length; i++)
                          Positioned(
                            left: i * 26.0,
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.bg0, width: 2)),
                              child: AvatarPlaceholder(seed: a.participantAvatarSeeds[i], label: 'U', size: 36),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(a.desc(lang), style: AppTextStyles.body.copyWith(height: 1.7)),
                  const SizedBox(height: 24),
                  // 一键约起 / 候补池智能补齐
                  if (a.needsMore) _TeamUpBlock(activity: a, lang: lang),
                  // 签到后的回忆录
                  if (a.checkedIn) _MemoryBlock(activity: a, lang: lang),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        color: AppColors.bg1,
        child: SafeArea(
          top: false,
          child: a.joined
              ? Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        label: a.checkedIn ? ref.tr('activity_checked') : ref.tr('activity_checkin'),
                        icon: a.checkedIn ? Icons.verified : Icons.qr_code_scanner,
                        gradient: AppColors.cyanPurple,
                        onPressed: a.checkedIn
                            ? null
                            : () {
                                ref.read(activitiesProvider.notifier).checkIn(a.id);
                                context.showNeonSnack(ref.tr('activity_checked'));
                              },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        label: ref.tr('activity_joined'),
                        icon: Icons.check,
                        secondary: true,
                        onPressed: () => ref.read(activitiesProvider.notifier).toggleJoin(a.id),
                      ),
                    ),
                  ],
                )
              : NeonButton(
                  label: ref.tr('activity_join'),
                  icon: Icons.celebration,
                  onPressed: () {
                    ref.read(activitiesProvider.notifier).toggleJoin(a.id);
                    context.showNeonSnack(ref.tr('activity_joined'));
                  },
                ),
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.neonCyan),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

/// 一键约起：差人时从候补池智能补齐（参考"组队匹配"）
class _TeamUpBlock extends ConsumerWidget {
  final dynamic activity;
  final String lang;
  const _TeamUpBlock({required this.activity, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = activity;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.neonPink.withValues(alpha: 0.16), AppColors.bg1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_add, color: AppColors.neonPink, size: 18),
              const SizedBox(width: 6),
              Text(ref.tr('team_up'), style: AppTextStyles.title),
              const Spacer(),
              Text(
                '${ref.tr('still_need')} ${a.vacancy}',
                style: AppTextStyles.caption.copyWith(color: AppColors.neonPink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(ref.tr('team_up_desc'), style: AppTextStyles.caption),
          const SizedBox(height: 14),
          // 候补池
          Text(ref.tr('candidate_pool'), style: AppTextStyles.bodyStrong),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final seed in (a.candidateSeeds as List).cast<String>())
                Column(
                  children: [
                    AvatarPlaceholder(seed: seed, label: 'U', size: 44),
                    const SizedBox(height: 4),
                    Text('${70 + (seed.hashCode.abs() % 29)}%', style: AppTextStyles.caption.copyWith(color: AppColors.neonCyan)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          NeonButton(
            label: ref.tr('one_tap_invite'),
            icon: Icons.bolt,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: () => context.showNeonSnack(ref.tr('invite_sent')),
          ),
        ],
      ),
    );
  }
}

/// 签到回忆录：活动结束后自动生成（头像墙 + 话题 + 日期）
class _MemoryBlock extends ConsumerWidget {
  final dynamic activity;
  final String lang;
  const _MemoryBlock({required this.activity, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = activity;
    final seeds = (a.participantAvatarSeeds as List).cast<String>();
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.neonCyan.withValues(alpha: 0.16), AppColors.bg1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_album, color: AppColors.neonCyan, size: 18),
              const SizedBox(width: 6),
              Text(ref.tr('memory_book'), style: AppTextStyles.title),
            ],
          ),
          const SizedBox(height: 4),
          Text(ref.tr('memory_desc'), style: AppTextStyles.caption),
          const SizedBox(height: 14),
          // 大合照占位
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [a.tag.color.withOpacity(0.5), AppColors.bg2]),
            ),
            child: const Center(child: Icon(Icons.camera_alt, color: Colors.white54, size: 36)),
          ),
          const SizedBox(height: 12),
          // 头像墙
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in seeds) AvatarPlaceholder(seed: s, label: 'U', size: 36),
            ],
          ),
          const SizedBox(height: 12),
          // 当天聊过的话题
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in [a.tag.name(lang), lang == 'en' ? 'Offline' : '线下面基', lang == 'en' ? 'Squad' : '组队'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('# $topic', style: AppTextStyles.caption),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
