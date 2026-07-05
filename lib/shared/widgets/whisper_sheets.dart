import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../data/repositories.dart';
import '../models/whisper.dart';
import 'avatar_placeholder.dart';
import 'glass_card.dart';
import 'neon_button.dart';

/// 异步留言（Whisper）相关的公共 UI 入口，供"空间"页的场景模式 / 地图模式共用，
/// 是"Lobby 异步留言系统"当前落地的核心交互载体。

String whisperTimeAgo(DateTime time, String lang) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return lang == 'en' ? 'just now' : '刚刚';
  if (diff.inHours < 1) return lang == 'en' ? '${diff.inMinutes}m ago' : '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return lang == 'en' ? '${diff.inHours}h ago' : '${diff.inHours} 小时前';
  return lang == 'en' ? '${diff.inDays}d ago' : '${diff.inDays} 天前';
}

/// 查看单条留言详情：内容 + 作者 + 相对时间 + 共鸣按钮。
void showWhisperDetailSheet(BuildContext context, WidgetRef ref, Whisper w, String lang) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        blur: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarPlaceholder(seed: w.authorAvatarSeed, label: w.authorNickname, size: 40, online: false),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.authorNickname, style: AppTextStyles.title),
                      Text(whisperTimeAgo(w.createdAt, lang), style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(w.content(lang), style: AppTextStyles.body.copyWith(height: 1.5)),
            const SizedBox(height: 16),
            NeonButton(
              label: '${ref.tr('whisper_resonate')} · ${w.resonanceCount}',
              icon: Icons.favorite_rounded,
              gradient: AppColors.pinkPurple,
              onPressed: () {
                ref.read(whispersProvider.notifier).resonate(w.id);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// 发布一条新留言（默认落在指定坐标，通常为当前用户所在位置）。
void showComposeWhisperSheet(BuildContext context, WidgetRef ref, double lat, double lng) {
  final controller = TextEditingController();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: GlassCard(
        blur: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ref.tr('whisper_leave'), style: AppTextStyles.title),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 120,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: ref.tr('whisper_input_hint'),
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            NeonButton(
              label: ref.tr('whisper_post'),
              icon: Icons.send_rounded,
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                ref.read(whispersProvider.notifier).post(text, lat: lat, lng: lng);
                Navigator.pop(sheetContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ref.tr('whisper_posted_toast'))),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

/// 留言列表（浮层）：不依赖地图坐标展示，可在"场景"模式下作为
/// 留言 Feed 使用，点击任一条即可查看详情并共鸣。
void showWhisperFeedSheet(BuildContext context, WidgetRef ref, String lang) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (ctx, innerRef, __) {
        final whispers = innerRef.watch(whispersProvider);
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(innerRef.tr('whisper_title'), style: AppTextStyles.h2.copyWith(color: Colors.white)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                Expanded(
                  child: whispers.isEmpty
                      ? Center(
                          child: Text(
                            innerRef.tr('whisper_empty_hint'),
                            style: AppTextStyles.caption.copyWith(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: whispers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final w = whispers[i];
                            return GestureDetector(
                              onTap: () => showWhisperDetailSheet(context, innerRef, w, lang),
                              child: GlassCard(
                                child: Row(
                                  children: [
                                    AvatarPlaceholder(seed: w.authorAvatarSeed, label: w.authorNickname, size: 34, online: false),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            w.content(lang),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.body,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${w.authorNickname} · ${whisperTimeAgo(w.createdAt, lang)}',
                                            style: AppTextStyles.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.favorite, size: 14, color: AppColors.neonPink.withValues(alpha: 0.8)),
                                    const SizedBox(width: 3),
                                    Text('${w.resonanceCount}', style: AppTextStyles.caption),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
