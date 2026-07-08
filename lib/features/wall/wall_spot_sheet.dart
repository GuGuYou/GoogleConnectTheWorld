import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/wall_message.dart';
import '../../shared/models/wall_spot.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';
import '../avatar/widgets/virtual_avatar_view.dart';

void showWallSpotSheet(BuildContext context, WidgetRef ref, WallSpot spot) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.fromLTRB(20, 72, 20, 108),
      child: _WallSpotSheet(spot: spot),
    ),
  );
}

class _WallSpotSheet extends ConsumerStatefulWidget {
  final WallSpot spot;
  const _WallSpotSheet({required this.spot});

  @override
  ConsumerState<_WallSpotSheet> createState() => _WallSpotSheetState();
}

class _WallSpotSheetState extends ConsumerState<_WallSpotSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(currentUserProvider);
    final (msg, error) = ref.read(wallMessagesProvider.notifier).postWallMessage(
          content: text,
          lat: widget.spot.lat,
          lng: widget.spot.lng,
          author: me,
        );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(wallMessagesForSpotProvider(widget.spot.id));
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: GlassCard(
        blur: 20,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.58),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ref.tr('wall_spot_title'), style: AppTextStyles.title),
                        const SizedBox(height: 4),
                        Text(
                          ref.tr('wall_spot_summary').replaceAll('{count}', '${messages.length}'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: messages.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: messages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => WallMessageTile(message: messages[i]),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: ref.tr('wall_input_hint'),
                        hintStyle: AppTextStyles.caption,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.glassBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  NeonButton(
                    label: ref.tr('send'),
                    icon: Icons.send,
                    expand: false,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WallMessageTile extends ConsumerWidget {
  final WallMessage message;
  const WallMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!message.isDisplayable) return const SizedBox.shrink();

    final author = ref.watch(mockProvider).userById(message.authorId);
    final isDeleted = message.isDeleted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        author.virtualAvatar != null
            ? VirtualAvatarView(avatar: author.virtualAvatar!, size: 40)
            : AvatarPlaceholder(seed: message.avatarSeed, label: '', size: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDeleted) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [for (final t in message.tags.take(3)) IpTagChip(tag: t, small: true)],
                ),
                const SizedBox(height: 6),
                if (message.parentId != null)
                  Text(ref.tr('wall_reply_prefix'),
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
              ],
              Text(
                message.content,
                style: AppTextStyles.body.copyWith(
                  color: isDeleted ? AppColors.textMuted : null,
                  fontStyle: isDeleted ? FontStyle.italic : null,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // 共鸣（点赞）
                  _ActionBtn(
                    icon: message.likedByMe ? Icons.favorite : Icons.favorite_border,
                    label: '${message.likeCount}',
                    color: message.likedByMe ? AppColors.neonPink : AppColors.textMuted,
                    onTap: isDeleted
                        ? null
                        : () => ref.read(wallMessagesProvider.notifier).toggleLike(message.id),
                  ),
                  const SizedBox(width: 12),
                  // 回复
                  _ActionBtn(
                    icon: Icons.reply,
                    label: ref.tr('wall_reply'),
                    color: AppColors.textMuted,
                    onTap: isDeleted ? null : () => _showReplySheet(context, ref),
                  ),
                  const Spacer(),
                  // 软删除（仅自己的留言）
                  if (message.authorId == ref.read(currentUserProvider).id && !isDeleted)
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      label: '',
                      color: AppColors.textMuted,
                      onTap: () {
                        ref.read(wallMessagesProvider.notifier).softDelete(message.id);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReplySheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(ref.tr('wall_reply_title'), style: AppTextStyles.title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: ref.tr('wall_reply_hint'),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.tr('cancel'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          NeonButton(
            label: ref.tr('send'),
            icon: Icons.send,
            expand: false,
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final me = ref.read(currentUserProvider);
              ref.read(wallMessagesProvider.notifier).postReply(
                    content: text,
                    parent: message,
                    author: me,
                  );
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label,
                style: AppTextStyles.caption.copyWith(color: color, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 40, color: AppColors.neonCyan.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            ref.tr('wall_empty_hint'),
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
