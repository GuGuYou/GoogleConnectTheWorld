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
                      AvatarPlaceholder(seed: host.avatarSeed, label: host.name(lang), size: 44),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ref.tr('activity_host'), style: AppTextStyles.caption),
                          Text(host.name(lang), style: AppTextStyles.bodyStrong),
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
                        gradient: const LinearGradient(colors: [AppColors.bg2, AppColors.bg2]),
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
