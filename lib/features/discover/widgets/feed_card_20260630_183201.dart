import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/distance.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/models/feed_post.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/avatar_placeholder.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ip_tag_chip.dart';

class FeedCard extends ConsumerWidget {
  final FeedPost post;
  final UserProfile author;
  final String lang;

  const FeedCard({super.key, required this.post, required this.author, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        onTap: () => context.push('/user/${author.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarPlaceholder(seed: author.avatarSeed, label: author.nickname, size: 42, online: author.online),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(author.nickname, style: AppTextStyles.bodyStrong),
                          if (author.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 14, color: AppColors.neonCyan),
                          ],
                        ],
                      ),
                      Text('${author.city} · ${formatDistance(post.distanceKm)}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                _TypeBadge(type: post.type, lang: lang),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content(lang), style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            // 打卡 / 晒单 地点
            if (post.place(lang) != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(post.type.icon, size: 14, color: post.type.color),
                  const SizedBox(width: 5),
                  Text(post.place(lang)!, style: AppTextStyles.caption.copyWith(color: post.type.color)),
                ],
              ),
            ],
            if (post.imageCount > 0) ...[
              const SizedBox(height: 12),
              _ImageGrid(count: post.imageCount, tagColor: post.tag.color, seed: post.coverSeed),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(feedsProvider.notifier).toggleLike(post.id),
                  child: Row(
                    children: [
                      Icon(
                        post.liked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: post.liked ? AppColors.neonPink : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text('${post.likes + (post.liked ? 1 : 0)}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _stat(Icons.chat_bubble_outline, post.comments),
                const Spacer(),
                const Icon(Icons.bookmark_border, size: 18, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, int n) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text('$n', style: AppTextStyles.caption),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final FeedType type;
  final String lang;
  const _TypeBadge({required this.type, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: type.color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: type.color),
          const SizedBox(width: 4),
          Text(type.label(lang), style: TextStyle(color: type.color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final int count;
  final Color tagColor;
  final String seed;
  const _ImageGrid({required this.count, required this.tagColor, required this.seed});

  @override
  Widget build(BuildContext context) {
    final n = count.clamp(1, 3);
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          for (var i = 0; i < n; i++) ...[
            Expanded(
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [tagColor.withValues(alpha: 0.5), AppColors.bg2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.image_outlined, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            if (i != n - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
