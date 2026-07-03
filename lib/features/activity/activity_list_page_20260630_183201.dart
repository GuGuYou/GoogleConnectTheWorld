import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import 'widgets/activity_card.dart';

class ActivityListPage extends ConsumerWidget {
  const ActivityListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final activities = ref.watch(activitiesProvider);
    final hot = activities.take(5).toList();

    return NeonBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GradientText(ref.tr('activity_title'), style: AppTextStyles.h1),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/activity/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(gradient: AppColors.pinkPurple, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(ref.tr('activity_create'), style: AppTextStyles.button.copyWith(fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  // 热门活动横向轮播
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text('🔥 ${ref.tr('activity_hot')}', style: AppTextStyles.title),
                  ),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hot.length,
                      itemBuilder: (c, i) {
                        final a = hot[i];
                        return GestureDetector(
                          onTap: () => context.push('/activity/${a.id}'),
                          child: Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [a.tag.color, a.tag.color.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [BoxShadow(color: a.tag.color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8))],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(a.tag.icon, color: Colors.white, size: 30),
                                Text(a.title(lang), style: AppTextStyles.h2.copyWith(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text('${a.participants} ${ref.tr('activity_participants')}', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < activities.length; i++)
                    ActivityCard(activity: activities[i], lang: lang)
                        .animate()
                        .fadeIn(delay: (i * 30).ms)
                        .slideX(begin: 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
