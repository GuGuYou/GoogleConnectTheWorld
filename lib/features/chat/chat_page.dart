import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  const ChatPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send({bool image = false}) {
    final text = _input.text.trim();
    if (!image && text.isEmpty) return;
    ref.read(chatProvider(widget.conversationId).notifier).send(text, isImage: image);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final mock = ref.watch(mockProvider);
    final peerId = widget.conversationId.replaceFirst('conv_', '');
    final peer = mock.userById(peerId);
    final messages = ref.watch(chatProvider(widget.conversationId));

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
                child: Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                    AvatarPlaceholder(seed: peer.avatarSeed, label: peer.nickname, size: 40, online: peer.online),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(peer.nickname, style: AppTextStyles.bodyStrong),
                          Text(peer.online ? ref.tr('online') : peer.city, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    if (peer.tags.isNotEmpty) IpTagChip(tag: peer.tags.first, small: true),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              // 消息区
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (c, i) => MessageBubble(message: messages[i], imageMsgLabel: ref.tr('image_msg')),
                ),
              ),
              // 输入栏
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: const BoxDecoration(
                  color: AppColors.bg1,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _send(image: true),
                        icon: const Icon(Icons.image_outlined, color: AppColors.neonCyan),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _input,
                          style: AppTextStyles.body.copyWith(color: Colors.white),
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: ref.tr('chat_input_hint'),
                            hintStyle: AppTextStyles.caption,
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _send(),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: const BoxDecoration(gradient: AppColors.pinkPurple, shape: BoxShape.circle),
                          child: const Icon(Icons.send, size: 20, color: Colors.white),
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
