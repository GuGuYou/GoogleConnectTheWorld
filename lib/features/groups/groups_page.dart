import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/group.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';

/// 圈子列表页（参考 Discord 服务器）：每个 IP 一个官方运营圈子
class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final groups = ref.watch(groupsProvider);
    final joined = groups.where((g) => g.joined).toList();
    final discover = groups.where((g) => !g.joined).toList();

    return NeonBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: GradientText(ref.tr('tab_groups'), style: AppTextStyles.h1),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                children: [
                  if (joined.isNotEmpty) ...[
                    _sectionTitle(ref.tr('groups_joined')),
                    for (final g in joined) _GroupCard(group: g, lang: lang),
                    const SizedBox(height: 16),
                  ],
                  _sectionTitle(ref.tr('groups_discover')),
                  for (var i = 0; i < discover.length; i++)
                    _GroupCard(group: discover[i], lang: lang)
                        .animate()
                        .fadeIn(delay: (i * 40).ms)
                        .slideY(begin: 0.1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
        child: Text(t, style: AppTextStyles.title),
      );
}

class _GroupCard extends ConsumerWidget {
  final IpGroup group;
  final String lang;
  const _GroupCard({required this.group, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/group/${group.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.bg1,
          border: Border.all(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 头图
            Container(
              height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [group.tag.color.withOpacity(0.85), AppColors.bg1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(group.tag.icon, color: Colors.white, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name(lang), style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(
                          '${_fmt(group.members)} ${ref.tr('group_members')} · ${group.onlineNow} ${ref.tr('online')}',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text(group.desc(lang), style: AppTextStyles.caption, maxLines: 2)),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => ref.read(groupsProvider.notifier).toggleJoin(group.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: group.joined ? null : AppColors.pinkPurple,
                        color: group.joined ? AppColors.bg2 : null,
                        borderRadius: BorderRadius.circular(20),
                        border: group.joined ? Border.all(color: AppColors.glassBorder) : null,
                      ),
                      child: Text(
                        group.joined ? ref.tr('group_joined') : ref.tr('group_join'),
                        style: TextStyle(
                          color: group.joined ? AppColors.textSecondary : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n >= 10000 ? '${(n / 10000).toStringAsFixed(1)}w' : '$n';
}
