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
import 'widgets/feed_card.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static const _distances = [0.0, 1.0, 5.0, 10.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final feeds = ref.watch(feedsProvider);
    final filter = ref.watch(distanceFilterProvider);

    return NeonBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  GradientText(ref.tr('discover_title'), style: AppTextStyles.h1),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.read(localeProvider.notifier).toggle(),
                    icon: const Icon(Icons.translate, color: AppColors.neonCyan),
                  ),
                  IconButton(
                    onPressed: () => context.push('/chat'),
                    icon: const Icon(Icons.forum_outlined, color: AppColors.neonPink),
                  ),
                ],
              ),
            ),
            // 距离筛选条
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final d in _distances)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _DistanceChip(
                        label: d == 0 ? ref.tr('filter_all') : '${d.toInt()}km',
                        active: filter == d,
                        onTap: () => ref.read(distanceFilterProvider.notifier).state = d,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: feeds.isEmpty
                  ? Center(child: Text(ref.tr('feed_empty'), style: AppTextStyles.body))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: feeds.length,
                      itemBuilder: (c, i) {
                        final post = feeds[i];
                        final author = ref.read(mockProvider).userById(post.authorId);
                        return FeedCard(post: post, author: author, lang: lang)
                            .animate()
                            .fadeIn(delay: (i * 40).ms, duration: 300.ms)
                            .slideY(begin: 0.15);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistanceChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DistanceChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: active ? AppColors.cyanPurple : null,
          color: active ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: active ? Colors.transparent : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
