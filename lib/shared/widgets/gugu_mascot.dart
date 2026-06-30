import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';

/// 咕咕情绪（参考 Duolingo 猫头鹰的情绪反馈）
enum GuguMood { happy, cheer, sleepy, sad, love }

extension GuguMoodX on GuguMood {
  String get face {
    switch (this) {
      case GuguMood.happy:
        return '(•ᴗ•)';
      case GuguMood.cheer:
        return '(ﾉ◕ヮ◕)ﾉ';
      case GuguMood.sleepy:
        return '(-_-) zZ';
      case GuguMood.sad:
        return '(╥﹏╥)';
      case GuguMood.love:
        return '(♥ω♥)';
    }
  }

  Color get color {
    switch (this) {
      case GuguMood.happy:
        return AppColors.neonCyan;
      case GuguMood.cheer:
        return AppColors.neonYellow;
      case GuguMood.sleepy:
        return AppColors.textMuted;
      case GuguMood.sad:
        return AppColors.neonPurple;
      case GuguMood.love:
        return AppColors.neonPink;
    }
  }
}

/// 吉祥物「咕咕」：随状态变化表情，提供情绪价值
class GuguMascot extends StatelessWidget {
  final GuguMood mood;
  final double size;
  final String? bubble; // 头顶气泡文案
  const GuguMascot({super.key, this.mood = GuguMood.happy, this.size = 88, this.bubble});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bubble != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: mood.color.withOpacity(0.5)),
            ),
            child: Text(bubble!, style: TextStyle(color: mood.color, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [mood.color.withOpacity(0.4), AppColors.bg2]),
            border: Border.all(color: mood.color, width: 2),
            boxShadow: [BoxShadow(color: mood.color.withOpacity(0.5), blurRadius: 20)],
          ),
          alignment: Alignment.center,
          child: Text(
            mood.face,
            style: TextStyle(color: AppColors.textPrimary, fontSize: size * 0.18, fontWeight: FontWeight.bold),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 1600.ms, curve: Curves.easeInOut),
      ],
    );
  }
}
