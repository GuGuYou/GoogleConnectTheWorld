import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/feed_post.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import 'widgets/feed_card.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  static const _distances = [0.0, 1.0, 5.0, 10.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final feeds = ref.watch(filteredFeedsProvider);
    final filter = ref.watch(distanceFilterProvider);
    final typeFilter = ref.watch(feedTypeFilterProvider);

    return NeonBackground(
      child: Stack(
        children: [
          SafeArea(
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
            // 网咖广场入口
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: _PlazaEntry(
                title: ref.tr('plaza_entry'),
                subtitle: ref.tr('plaza_entry_sub'),
                onTap: () => context.push('/plaza'),
              ),
            ),
            // 动态类型筛选条（畅聊 / 打卡 / 晒单 / 求搭子）
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _TypeChip(
                    label: ref.tr('filter_all'),
                    icon: Icons.dashboard_customize,
                    color: AppColors.neonPurple,
                    active: typeFilter == null,
                    onTap: () => ref.read(feedTypeFilterProvider.notifier).state = null,
                  ),
                  for (final t in FeedType.values)
                    _TypeChip(
                      label: t.label(lang),
                      icon: t.icon,
                      color: t.color,
                      active: typeFilter == t,
                      onTap: () => ref.read(feedTypeFilterProvider.notifier).state = t,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // 距离筛选条
            SizedBox(
              height: 40,
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
          // 发布动态悬浮按钮
          Positioned(
            right: 20,
            bottom: 100,
            child: GestureDetector(
              onTap: () => context.push('/discover/compose'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.pinkPurple,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.5), blurRadius: 18)],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(ref.tr('post_create'), style: AppTextStyles.button.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.icon, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.16) : AppColors.bg2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? color : AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: active ? color : AppColors.textMuted),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: active ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlazaEntry extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _PlazaEntry({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF161B33), Color(0xFF2A2150)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF31E6FF), AppColors.neonPink]),
                boxShadow: [BoxShadow(color: const Color(0xFF31E6FF).withValues(alpha: 0.5), blurRadius: 14)],
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
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
          color: active ? null : AppColors.bg2,
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
