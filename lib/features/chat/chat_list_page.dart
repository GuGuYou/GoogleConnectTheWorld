import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/repositories.dart';
import '../avatar/widgets/virtual_avatar_view.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convs = ref.watch(conversationsProvider);
    final mock = ref.watch(mockProvider);

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
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                    GradientText(ref.tr('chat_title'), style: AppTextStyles.h1),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: convs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (c, i) {
                    final conv = convs[i];
                    final peer = mock.userById(conv.peerId);
                    return ListTile(
                      onTap: () => context.push('/chat/${conv.id}'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      leading: peer.virtualAvatar != null
                          ? VirtualAvatarView(avatar: peer.virtualAvatar!, size: 50, online: peer.online)
                          : AvatarPlaceholder(seed: peer.avatarSeed, label: peer.nickname, size: 50, online: peer.online),
                      title: Text(peer.nickname, style: AppTextStyles.bodyStrong),
                      subtitle: Text(
                        conv.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(conv.lastTime.relativeLabel(), style: AppTextStyles.caption),
                          const SizedBox(height: 6),
                          if (conv.unread > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(gradient: AppColors.pinkPurple, shape: BoxShape.circle),
                              child: Text('${conv.unread}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
