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
    ref.read(wallMessagesProvider.notifier).postWallMessage(
          content: text,
          lat: widget.spot.lat,
          lng: widget.spot.lng,
          author: me,
        );
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
    final author = ref.watch(mockProvider).userById(message.authorId);
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
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [for (final t in message.tags.take(3)) IpTagChip(tag: t, small: true)],
              ),
              const SizedBox(height: 6),
              Text(message.content, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
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
