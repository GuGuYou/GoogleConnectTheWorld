import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/distance.dart';
import '../../../shared/models/feed_post.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/avatar_placeholder.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/ip_tag_chip.dart';

class FeedCard extends StatelessWidget {
  final FeedPost post;
  final UserProfile author;
  final String lang;

  const FeedCard({super.key, required this.post, required this.author, required this.lang});

  @override
  Widget build(BuildContext context) {
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
                      Text(author.nickname, style: AppTextStyles.bodyStrong),
                      Text('${author.city} · ${formatDistance(post.distanceKm)}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IpTagChip(tag: post.tag, small: true),
              ],
            ),
            const SizedBox(height: 12),
            Text(post.content(lang), style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            // 占位图网格
            _ImageGrid(count: post.imageCount, tagColor: post.tag.color, seed: post.coverSeed),
            const SizedBox(height: 12),
            Row(
              children: [
                _stat(Icons.favorite_border, post.likes),
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
