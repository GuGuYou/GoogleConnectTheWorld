import 'package:flutter/material.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/distance.dart';
import '../../../shared/data/repositories.dart';
import '../../../shared/widgets/avatar_placeholder.dart';
import '../../../shared/widgets/ip_tag_chip.dart';

/// 附近同好匹配卡（Tinder 风格大卡）
class MatchCard extends StatelessWidget {
  final UserWithDistance data;
  final String lang;
  const MatchCard({super.key, required this.data, required this.lang});

  @override
  Widget build(BuildContext context) {
    final u = data.user;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg2, AppColors.bg1],
        ),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [BoxShadow(color: AppColors.neonPurple.withOpacity(0.25), blurRadius: 30)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 顶部头像区
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [u.tags.first.color.withOpacity(0.6), AppColors.bg0],
                    ),
                  ),
                ),
                Center(
                  child: AvatarPlaceholder(
                    seed: u.avatarSeed,
                    label: u.nickname,
                    size: 140,
                    glow: true,
                    online: u.online,
                  ),
                ),
                // 匹配度徽标
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.pinkPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.white),
                        Text('${data.matchRate}%', style: AppTextStyles.button.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 底部信息区
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(u.nickname, style: AppTextStyles.h2),
                    if (u.verified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified, size: 18, color: AppColors.neonCyan),
                    ],
                    const SizedBox(width: 8),
                    Text('${u.age}', style: AppTextStyles.body),
                    const Spacer(),
                    const Icon(Icons.location_on, size: 14, color: AppColors.neonCyan),
                    Text(formatDistance(data.distanceKm), style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 8),
                Text(u.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final t in u.tags.take(4)) IpTagChip(tag: t, small: true)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
