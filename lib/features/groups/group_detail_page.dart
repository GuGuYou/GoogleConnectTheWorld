import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/group.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/neon_button.dart';

/// 圈子详情：频道（文字/语音）+ 语音派对房（参考 Discord）
class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final group = ref.watch(groupsProvider).firstWhere((g) => g.id == groupId);
    final textChannels = group.channels.where((c) => c.type == ChannelType.text).toList();
    final voiceChannels = group.channels.where((c) => c.type == ChannelType.voice).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.bg0,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const CircleAvatar(backgroundColor: Colors.black38, child: Icon(Icons.arrow_back, color: Colors.white)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
              title: Text(group.name(lang), style: AppTextStyles.title),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [group.tag.color, AppColors.bg0],
                  ),
                ),
                child: Center(child: Icon(group.tag.icon, size: 80, color: Colors.white24)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _stat('${group.onlineNow}', ref.tr('online')),
                      const SizedBox(width: 24),
                      _stat(group.members >= 10000 ? '${(group.members / 10000).toStringAsFixed(1)}w' : '${group.members}', ref.tr('group_members')),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.read(groupsProvider.notifier).toggleJoin(group.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: group.joined ? null : AppColors.pinkPurple,
                            color: group.joined ? AppColors.bg2 : null,
                            borderRadius: BorderRadius.circular(20),
                            border: group.joined ? Border.all(color: AppColors.glassBorder) : null,
                          ),
                          child: Text(
                            group.joined ? ref.tr('group_joined') : ref.tr('group_join'),
                            style: TextStyle(color: group.joined ? AppColors.textSecondary : Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 语音派对房
                  Row(
                    children: [
                      const Icon(Icons.graphic_eq, color: AppColors.neonGreen, size: 18),
                      const SizedBox(width: 6),
                      Text(ref.tr('voice_rooms'), style: AppTextStyles.title),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < group.voiceRooms.length; i++)
                    _VoiceRoomCard(room: group.voiceRooms[i], lang: lang)
                        .animate()
                        .fadeIn(delay: (i * 90).ms, duration: 320.ms)
                        .slideX(begin: 0.12, curve: Curves.easeOut),
                  const SizedBox(height: 20),
                  // 文字频道
                  Text(ref.tr('text_channels'), style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  for (final c in textChannels) _channelTile(context, ref, c, lang, group.tag.color),
                  const SizedBox(height: 16),
                  // 语音频道
                  Text(ref.tr('voice_channels'), style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  for (final c in voiceChannels) _channelTile(context, ref, c, lang, AppColors.neonGreen),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v, style: AppTextStyles.number),
          Text(l, style: AppTextStyles.caption),
        ],
      );

  Widget _channelTile(BuildContext context, WidgetRef ref, GroupChannel c, String lang, Color color) {
    final isVoice = c.type == ChannelType.voice;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(isVoice ? Icons.volume_up : Icons.tag, color: color, size: 20),
      title: Text(c.name(lang), style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(10)),
        child: Text(
          isVoice ? '${c.activeCount} 🎙' : '${c.activeCount}',
          style: AppTextStyles.caption,
        ),
      ),
      onTap: () => context.showNeonSnack(
        lang == 'en' ? 'Entering #${c.name(lang)}…' : '进入 #${c.name(lang)}…',
      ),
    );
  }
}

class _VoiceRoomCard extends ConsumerWidget {
  final VoiceRoom room;
  final String lang;
  const _VoiceRoomCard({required this.room, required this.lang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.neonGreen.withOpacity(0.18), AppColors.bg1],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.graphic_eq, color: AppColors.neonGreen, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(room.title(lang), style: AppTextStyles.bodyStrong)),
              Text('${room.listeners} ${ref.tr('listening')}', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 36,
                width: room.speakerSeeds.length * 26.0 + 10,
                child: Stack(
                  children: [
                    for (var i = 0; i < room.speakerSeeds.length; i++)
                      Positioned(
                        left: i * 26.0,
                        child: Container(
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.neonGreen, width: 1.5)),
                          child: AvatarPlaceholder(seed: room.speakerSeeds[i], label: 'U', size: 32),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: NeonButton(
                  label: ref.tr('join_mic'),
                  icon: Icons.mic,
                  gradient: const LinearGradient(colors: [AppColors.neonGreen, AppColors.neonCyan]),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => context.showNeonSnack(lang == 'en' ? 'You are on mic 🎙' : '你已上麦 🎙'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
