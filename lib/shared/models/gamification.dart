import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 同好关系链等级（参考 Duolingo 段位成长）
class RelationLevel {
  final int level;
  final String nameZh;
  final String nameEn;
  final IconData icon;
  final Color color;
  const RelationLevel(this.level, this.nameZh, this.nameEn, this.icon, this.color);

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
}

const kRelationLevels = <RelationLevel>[
  RelationLevel(1, '邂逅', 'Encounter', Icons.auto_awesome, AppColors.neonCyan),
  RelationLevel(2, '网友', 'Net Pal', Icons.forum, AppColors.neonPurple),
  RelationLevel(3, '见面', 'Met IRL', Icons.handshake, AppColors.neonYellow),
  RelationLevel(4, '同好搭子', 'Tribe Buddy', Icons.favorite, AppColors.neonPink),
];

RelationLevel relationLevelOf(int level) =>
    kRelationLevels[(level - 1).clamp(0, kRelationLevels.length - 1)];

/// 每日任务（参考 Duolingo 每日目标）
class DailyTask {
  final String id;
  final String titleZh;
  final String titleEn;
  final IconData icon;
  final int xp;
  final int target;
  int progress;
  DailyTask({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.icon,
    required this.xp,
    this.target = 1,
    this.progress = 0,
  });

  bool get done => progress >= target;
  String title(String lang) => lang == 'en' ? titleEn : titleZh;
}

/// 兴趣人格（参考 Soul 灵魂测试，聚焦兴趣风格而非性格）
class InterestPersonality {
  final String key;
  final String nameZh;
  final String nameEn;
  final String descZh;
  final String descEn;
  final IconData icon;
  final Color color;
  const InterestPersonality(
    this.key,
    this.nameZh,
    this.nameEn,
    this.descZh,
    this.descEn,
    this.icon,
    this.color,
  );

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
  String desc(String lang) => lang == 'en' ? descEn : descZh;
}

const kPersonalities = <InterestPersonality>[
  InterestPersonality('hardcore', '硬核考据派', 'Lore Master',
      '设定细节如数家珍，热衷深挖世界观与彩蛋。', 'Knows every detail and loves digging deep into lore.',
      Icons.menu_book, AppColors.neonCyan),
  InterestPersonality('vibe', '氛围体验派', 'Vibe Seeker',
      '为情绪与氛围而来，享受沉浸式的当下。', 'Here for the mood and immersive moments.',
      Icons.spa, AppColors.neonPurple),
  InterestPersonality('social', '社交玩乐派', 'Party Animal',
      '人越多越开心，组局开黑永远在线。', 'The more the merrier, always up for a squad.',
      Icons.celebration, AppColors.neonPink),
  InterestPersonality('creator', '创作输出派', 'Creator',
      '二创、cos、攻略，热爱把热爱变成作品。', 'Fan art, cosplay, guides — turns passion into work.',
      Icons.brush, AppColors.neonYellow),
];

InterestPersonality? personalityOf(String key) {
  for (final p in kPersonalities) {
    if (p.key == key) return p;
  }
  return null;
}

/// 人格测试题
class PersonalityQuestion {
  final String qZh;
  final String qEn;
  final List<MapEntry<String, String>> optionsZh; // (key, text)
  final List<MapEntry<String, String>> optionsEn;
  const PersonalityQuestion(this.qZh, this.qEn, this.optionsZh, this.optionsEn);
}
