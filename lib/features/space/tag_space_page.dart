import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

/// Tag 专属空间入口页面（通过 tagId 查找 tag）
class TagSpaceByTagIdPage extends ConsumerWidget {
  final String tagId;
  const TagSpaceByTagIdPage({super.key, required this.tagId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = ref.watch(mockProvider).tags;
    final tag = tags.where((t) => t.id == tagId).firstOrNull;
    if (tag == null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: Text('Tag not found')),
      );
    }
    return TagSpacePage(tag: tag);
  }
}

/// Tag 专属空间入口页面（R009 核心卖点）
///
/// 从地图用户标记 → 名片 → "进入 Ta 的 XX 空间" → 此页面。
/// 展示该 tag 下的同好、留言板、相关活动等信息。
class TagSpacePage extends ConsumerStatefulWidget {
  final IpTag tag;

  const TagSpacePage({super.key, required this.tag});

  @override
  ConsumerState<TagSpacePage> createState() => _TagSpacePageState();
}

class _TagSpacePageState extends ConsumerState<TagSpacePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            IpTagChip(tag: widget.tag, small: true),
            const SizedBox(width: 8),
            Text(
              '${widget.tag.name('zh')} ${ref.tr('tag_space')}',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.tag.icon,
                size: 64,
                color: widget.tag.color.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.tag.name('zh')} 同好空间',
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              Text(
                ref.tr('tag_space_coming'),
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeonButton(
                label: ref.tr('tag_space_browse'),
                icon: Icons.explore,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
