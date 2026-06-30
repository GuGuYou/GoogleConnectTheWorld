import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/feed_post.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

/// 发布动态：选择类型（畅聊/打卡/晒单/求搭子）+ 关联兴趣标签
class ComposePostPage extends ConsumerStatefulWidget {
  const ComposePostPage({super.key});

  @override
  ConsumerState<ComposePostPage> createState() => _ComposePostPageState();
}

class _ComposePostPageState extends ConsumerState<ComposePostPage> {
  final _text = TextEditingController();
  final _place = TextEditingController();
  FeedType _type = FeedType.talk;
  int _tagIndex = 0;

  @override
  void dispose() {
    _text.dispose();
    _place.dispose();
    super.dispose();
  }

  void _publish() {
    final me = ref.read(currentUserProvider);
    final mock = ref.read(mockProvider);
    final tag = me.tags.isNotEmpty ? me.tags[_tagIndex % me.tags.length] : mock.tags.first;
    final content = _text.text.trim();
    if (content.isEmpty) {
      context.showNeonSnack(ref.tr('post_empty'));
      return;
    }
    final needsPlace = _type == FeedType.checkin || _type == FeedType.haul;
    final post = FeedPost(
      id: 'f_${DateTime.now().millisecondsSinceEpoch}',
      authorId: 'me',
      contentZh: content,
      contentEn: content,
      tag: tag,
      likes: 0,
      comments: 0,
      distanceKm: 0.1,
      imageCount: _type == FeedType.talk ? 0 : 1,
      coverSeed: 'me_post_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      placeZh: needsPlace && _place.text.trim().isNotEmpty ? _place.text.trim() : null,
      placeEn: needsPlace && _place.text.trim().isNotEmpty ? _place.text.trim() : null,
    );
    ref.read(feedsProvider.notifier).addPost(post);
    // 完成"发布 1 条动态"任务
    ref.read(gamificationProvider.notifier).progressTask('t_post');
    context.showNeonSnack(ref.tr('post_done'));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final me = ref.watch(currentUserProvider);
    final needsPlace = _type == FeedType.checkin || _type == FeedType.haul;

    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('post_create'))),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(ref.tr('post_type'), style: AppTextStyles.title),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final t in FeedType.values)
                    GestureDetector(
                      onTap: () => setState(() => _type = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == t ? t.color.withOpacity(0.16) : AppColors.bg2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _type == t ? t.color : AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon, size: 16, color: t.color),
                            const SizedBox(width: 6),
                            Text(t.label(lang), style: TextStyle(color: _type == t ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(ref.tr('post_content'), style: AppTextStyles.title),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                maxLines: 5,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: ref.tr('post_hint'),
                  hintStyle: AppTextStyles.caption,
                  filled: true,
                  fillColor: AppColors.bg2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              if (needsPlace) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _place,
                  style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: Icon(_type.icon, color: _type.color, size: 18),
                    hintText: ref.tr('post_place_hint'),
                    hintStyle: AppTextStyles.caption,
                    filled: true,
                    fillColor: AppColors.bg2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(ref.tr('post_tag'), style: AppTextStyles.title),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < me.tags.length; i++)
                    IpTagChip(
                      tag: me.tags[i],
                      selected: _tagIndex == i,
                      onTap: () => setState(() => _tagIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              NeonButton(label: ref.tr('publish'), icon: Icons.send, onPressed: _publish),
            ],
          ),
        ),
      ),
    );
  }
}
