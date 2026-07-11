import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/activity.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/gold_glow.dart';
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
                  Flexible(
                    child: GradientText(ref.tr('activity_title'),
                        style: AppTextStyles.h1),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.auto_awesome,
                      size: 14, color: Color(0xFFFFE523)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/activity/create'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFC94D),
                            Color(0xFFFFAF3A),
                            Color(0xFFFF8C1F),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(200),
                        border: Border.all(
                            color: const Color(0xFFFFFED6)
                                .withValues(alpha: 0.8),
                            width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFEA000)
                                .withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(children: [
                        const Icon(Icons.add, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(ref.tr('activity_create'),
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
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
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GradientText(ref.tr('activity_hot'),
                                style: AppTextStyles.title
                                    .copyWith(fontSize: 18)),
                            const SizedBox(width: 4),
                            const Icon(Icons.auto_awesome,
                                size: 10, color: Color(0xFFFF8223)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 55,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            borderRadius: BorderRadius.circular(200),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFEA000)
                                    .withValues(alpha: 0.6),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 113,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: hot.length,
                      itemBuilder: (c, i) {
                        final a = hot[i];
                        return GestureDetector(
                          onTap: () => context.push('/activity/${a.id}'),
                          child: _HotCard(
                            activity: a,
                            lang: lang,
                            joinedLabel: ref.tr('activity_participants'),
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

/// Hot-carousel card per the Figma comp: hexagon icon, two-line title,
/// joined count, HOT ribbon in the top-right corner.
class _HotCard extends StatelessWidget {
  final ActivityItem activity;
  final String lang;
  final String joinedLabel;

  const _HotCard({
    required this.activity,
    required this.lang,
    required this.joinedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 8),
      child: CustomPaint(
        foregroundPainter: const GoldCardBorderPainter(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: AppColors.cardSurface,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gold wash from the top-right corner (Figma layer 2 @20%).
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.75, -0.95),
                      radius: 1.0,
                      colors: [
                        const Color(0xFFFFC000).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlowHexagon(
                      width: 32,
                      height: 36.5,
                      strokeWidth: 0.6,
                      child: Icon(activity.tag.icon,
                          size: 15, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        activity.title(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${activity.participants} $joinedLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // HOT ribbon: 4px below the top edge, flush right, rounded left.
              Positioned(
                top: 4,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0900),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7.5),
                      bottomLeft: Radius.circular(7.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 10, color: Color(0xFFF05005)),
                      const SizedBox(width: 2),
                      Text(
                        'HOT',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neonYellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
