import 'package:flutter/material.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/message.dart';

/// 消息气泡：自己右侧霓虹渐变，对方左侧玻璃拟态
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String imageMsgLabel;
  const MessageBubble({super.key, required this.message, required this.imageMsgLabel});

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bg2.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('✨ ${AppText.get('zh', 'matched_tip')}', style: AppTextStyles.caption),
        ),
      );
    }

    final me = message.isMe;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: me ? AppColors.pinkPurple : null,
        color: me ? null : AppColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(me ? 16 : 4),
          bottomRight: Radius.circular(me ? 4 : 16),
        ),
        border: me ? null : Border.all(color: AppColors.divider),
      ),
      child: message.type == MessageType.image
          ? _imageContent()
          : Text(
              message.content,
              style: AppTextStyles.body.copyWith(color: me ? Colors.white : AppColors.textPrimary),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [bubble],
      ),
    );
  }

  Widget _imageContent() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 160,
        height: 120,
        decoration: const BoxDecoration(gradient: AppColors.cyanPurple),
        child: const Icon(Icons.image, color: Colors.white, size: 40),
      ),
    );
  }
}
