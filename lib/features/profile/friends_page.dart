import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../avatar/widgets/virtual_avatar_view.dart';

/// Friends: your friends (message them) + suggested people to add. Reached
/// from the profile page; adding here or from a user's detail page updates the
/// same [friendsProvider].
class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendIds = ref.watch(friendsProvider);
    final mock = ref.watch(mockProvider);
    final me = ref.watch(currentUserProvider);
    final users = mock.users;
    final friends = users.where((u) => friendIds.contains(u.id)).toList();
    final suggest = users.where((u) => !friendIds.contains(u.id)).toList();

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back)),
                    GradientText(ref.tr('friends_title'),
                        style: AppTextStyles.h1),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _sectionTitle('${ref.tr('friends_mine')}  ${friends.length}'),
                    if (friends.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(ref.tr('friends_empty'),
                            style: AppTextStyles.body),
                      ),
                    for (final u in friends) _FriendTile(user: u, isFriend: true),
                    const SizedBox(height: 22),
                    _sectionTitle(ref.tr('friends_suggest')),
                    for (final u in suggest)
                      _FriendTile(
                          user: u,
                          isFriend: false,
                          match: u.matchRate(me.tags)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
        child: Text(text,
            style: AppTextStyles.title.copyWith(color: AppColors.neonYellow)),
      );
}

class _FriendTile extends ConsumerWidget {
  final UserProfile user;
  final bool isFriend;
  final int? match;

  const _FriendTile({required this.user, required this.isFriend, this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final displayName = user.name(lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => context.push('/user/${user.id}'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            user.virtualAvatar != null
                ? VirtualAvatarView(
                    avatar: user.virtualAvatar!, size: 48, online: user.online)
                : AvatarPlaceholder(
                    seed: user.avatarSeed,
                    label: displayName,
                    size: 48,
                    online: user.online),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: 2),
                  Text(
                    isFriend
                        ? user.bio
                        : '${ref.tr('match_rate')} ${match ?? 0}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isFriend)
              _RoundAction(
                icon: Icons.chat_bubble_outline,
                onTap: () => context.push('/chat/conv_${user.id}'),
              )
            else
              _AddButton(
                onTap: () => ref.read(friendsProvider.notifier).add(user.id),
                label: ref.tr('friends_add'),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.neonYellow.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 18, color: AppColors.neonYellow),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _AddButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: AppColors.pinkPurple,
          borderRadius: BorderRadius.circular(200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 14, color: AppColors.ctaText),
            const SizedBox(width: 3),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.ctaText, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
