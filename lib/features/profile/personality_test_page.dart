import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/gamification.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

/// 兴趣人格测试：硬核考据派 / 氛围体验派 / 社交玩乐派 / 创作输出派
class PersonalityTestPage extends ConsumerStatefulWidget {
  const PersonalityTestPage({super.key});

  @override
  ConsumerState<PersonalityTestPage> createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends ConsumerState<PersonalityTestPage> {
  int _step = 0;
  final Map<String, int> _scores = {};
  String? _result;

  void _pick(String key) {
    _scores[key] = (_scores[key] ?? 0) + 1;
    final qs = MockDataSource.personalityQuestions;
    if (_step < qs.length - 1) {
      setState(() => _step++);
    } else {
      // 计算最高分人格
      final best = _scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      ref.read(currentUserProvider.notifier).setPersonality(best);
      setState(() => _result = best);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final qs = MockDataSource.personalityQuestions;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: _result != null
              ? _buildResult(lang, _result!)
              : _buildQuestion(lang, qs),
        ),
      ),
    );
  }

  Widget _buildQuestion(String lang, List<PersonalityQuestion> qs) {
    final q = qs[_step];
    final options = lang == 'en' ? q.optionsEn : q.optionsZh;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / qs.length,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.neonPink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Text('${_step + 1} / ${qs.length}', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(lang == 'en' ? q.qEn : q.qZh, style: AppTextStyles.h1),
          const SizedBox(height: 30),
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => _pick(options[i].key),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bg2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(options[i].value, style: AppTextStyles.bodyStrong),
                ),
              ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildResult(String lang, String key) {
    final p = personalityOf(key)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [p.color.withOpacity(0.5), AppColors.bg2]),
              border: Border.all(color: p.color, width: 2),
              boxShadow: [BoxShadow(color: p.color.withOpacity(0.5), blurRadius: 30)],
            ),
            child: Icon(p.icon, size: 60, color: p.color),
          ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
          const SizedBox(height: 24),
          Text(lang == 'en' ? 'You are' : '你的兴趣人格是', style: AppTextStyles.body),
          const SizedBox(height: 6),
          GradientText(p.name(lang), style: AppTextStyles.display(context).copyWith(fontSize: 30)),
          const SizedBox(height: 16),
          Text(p.desc(lang), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(height: 1.7)),
          const SizedBox(height: 40),
          NeonButton(
            label: lang == 'en' ? 'Apply to Profile' : '应用到主页',
            icon: Icons.check,
            gradient: LinearGradient(colors: [p.color, AppColors.neonPurple]),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
