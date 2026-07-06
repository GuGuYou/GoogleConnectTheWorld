import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/distance.dart';
import '../../shared/data/repositories.dart';
import '../avatar/widgets/virtual_avatar_view.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

class UserDetailPage extends ConsumerWidget {
  final String userId;
  const UserDetailPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final user = ref.read(mockProvider).userById(userId);
    final dist = haversineKm(me.lat, me.lng, user.lat, user.lng);
    final common = user.commonTags(me.tags);
    final rate = user.matchRate(me.tags);

    return Scaffold(
      body: Stack(
        children: [
          // 顶部渐变背景
          Container(
            height: 320,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [user.tags.first.color.withValues(alpha: 0.7), AppColors.bg0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 10),
                      Center(
                        child: Column(
                          children: [
                            user.virtualAvatar != null
                                ? VirtualAvatarView(avatar: user.virtualAvatar!, size: 110, glow: true, online: user.online)
                                : AvatarPlaceholder(seed: user.avatarSeed, label: user.nickname, size: 110, glow: true, online: user.online),
                            const SizedBox(height: 14),
                            GradientText(user.nickname, style: AppTextStyles.h1),
                            const SizedBox(height: 6),
                            Text('${user.age} · ${user.city} · ${formatDistance(dist)}', style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 匹配度
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.pinkPurple,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('${ref.tr('match_rate')}  $rate%', style: AppTextStyles.button.copyWith(fontSize: 18)),
                            const Spacer(),
                            Text('${common.length} ${ref.tr('common_tags')}', style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(user.bio, style: AppTextStyles.body.copyWith(height: 1.7, color: AppColors.textPrimary)),
                      const SizedBox(height: 20),
                      Text(ref.tr('common_tags'), style: AppTextStyles.title),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final t in user.tags)
                            IpTagChip(tag: t, selected: common.any((c) => c.id == t.id)),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        color: AppColors.bg1,
        child: SafeArea(
          top: false,
          child: NeonButton(
            label: ref.tr('say_hi'),
            icon: Icons.waving_hand,
            onPressed: () => context.push('/chat/conv_${user.id}'),
          ),
        ),
      ),
    );
  }
}
