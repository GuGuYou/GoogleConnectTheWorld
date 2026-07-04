import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/interest_radar.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

/// 匹配成功页：破冰问题卡 + 兴趣雷达图（解决"匹配后尬聊"）
class MatchSuccessPage extends ConsumerStatefulWidget {
  final String userId;
  const MatchSuccessPage({super.key, required this.userId});

  @override
  ConsumerState<MatchSuccessPage> createState() => _MatchSuccessPageState();
}

class _MatchSuccessPageState extends ConsumerState<MatchSuccessPage> {
  int _answered = 0;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final me = ref.watch(currentUserProvider);
    final mock = ref.read(mockProvider);
    final peer = mock.userById(widget.userId);
    final common = peer.commonTags(me.tags);
    final tag = common.isNotEmpty ? common.first : peer.tags.first;
    final questions = mock.icebreakerFor(lang, tag);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Center(
                      child: GradientText(
                        lang == 'en' ? "IT'S A MATCH!" : '匹配成功！',
                        style: AppTextStyles.display(context).copyWith(fontSize: 30),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        lang == 'en'
                            ? 'You share ${common.length} interests'
                            : '你们有 ${common.length} 个共同兴趣',
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 双方头像
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AvatarPlaceholder(seed: me.avatarSeed, label: me.nickname, size: 76, glow: true),
                        const SizedBox(width: 12),
                        const Icon(Icons.favorite, color: AppColors.neonPink, size: 30)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(duration: 700.ms, begin: const Offset(1, 1), end: const Offset(1.25, 1.25)),
                        const SizedBox(width: 12),
                        AvatarPlaceholder(seed: peer.avatarSeed, label: peer.nickname, size: 76, glow: true, online: peer.online),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 兴趣雷达图
                    Text(lang == 'en' ? 'Interest Radar' : '兴趣雷达图', style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Center(
                      child: InterestRadar(
                        me: radarFromTags(me.tags),
                        other: radarFromTags(peer.tags),
                        lang: lang,
                        size: 240,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend(AppColors.neonCyan, lang == 'en' ? 'You' : '你'),
                        const SizedBox(width: 20),
                        _legend(AppColors.neonPink, peer.nickname),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // 破冰问题卡
                    Row(
                      children: [
                        const Icon(Icons.ac_unit, color: AppColors.neonCyan, size: 18),
                        const SizedBox(width: 6),
                        Text(lang == 'en' ? 'Icebreaker Cards' : '破冰问题卡', style: AppTextStyles.title),
                        const Spacer(),
                        Text('$_answered/${questions.length}', style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang == 'en'
                          ? 'Answer to unlock chat, no more awkward "hi"'
                          : '回答后解锁聊天，告别"在吗"尬聊',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < questions.length; i++)
                      _IcebreakerCard(
                        index: i,
                        question: questions[i],
                        onAnswered: () => setState(() => _answered++),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: NeonButton(
                  label: _answered > 0
                      ? (lang == 'en' ? 'Start Chatting' : '开始聊天')
                      : (lang == 'en' ? 'Skip & Chat' : '跳过直接聊'),
                  icon: Icons.chat_bubble,
                  onPressed: () {
                    // 完成"匹配 1 位同好"任务
                    ref.read(gamificationProvider.notifier).progressTask('t_match');
                    context.pushReplacement('/chat/conv_${peer.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _IcebreakerCard extends StatefulWidget {
  final int index;
  final String question;
  final VoidCallback onAnswered;
  const _IcebreakerCard({required this.index, required this.question, required this.onAnswered});

  @override
  State<_IcebreakerCard> createState() => _IcebreakerCardState();
}

class _IcebreakerCardState extends State<_IcebreakerCard> {
  final _controller = TextEditingController();
  bool _answered = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: _answered ? AppColors.neonGreen : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: AppColors.cyanPurple, shape: BoxShape.circle),
                  child: Text('${widget.index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.question, style: AppTextStyles.bodyStrong)),
                if (_answered) const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 20),
              ],
            ),
            if (!_answered) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '…',
                  hintStyle: AppTextStyles.caption,
                  filled: true,
                  fillColor: AppColors.bg2,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, size: 18, color: AppColors.neonPink),
                    onPressed: () {
                      if (_controller.text.trim().isEmpty) return;
                      setState(() => _answered = true);
                      widget.onAnswered();
                    },
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  setState(() => _answered = true);
                  widget.onAnswered();
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(_controller.text, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }
}
