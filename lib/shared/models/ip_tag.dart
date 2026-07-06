import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// IP 标签：兴趣单元，含分类与展示色
class IpTag {
  final String id;
  final String nameZh;
  final String nameEn;
  final String category; // game / anime / drama / comic / music / custom
  final IconData icon;

  const IpTag({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.icon,
  });

  Color get color => AppColors.categoryColors[category] ?? AppColors.neonPurple;

  String name(String lang) => lang == 'en' ? nameEn : nameZh;

  @override
  bool operator ==(Object other) => other is IpTag && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 标签分类元信息
class TagCategory {
  final String key;
  final String nameZh;
  final String nameEn;
  final Color color;
  const TagCategory(this.key, this.nameZh, this.nameEn, this.color);

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
}

const kTagCategories = <TagCategory>[
  TagCategory('game', '游戏', 'Game', AppColors.neonCyan),
  TagCategory('anime', '动漫', 'Anime', AppColors.neonPink),
  TagCategory('drama', '剧集', 'Drama', AppColors.neonPurple),
  TagCategory('comic', '漫画', 'Comic', AppColors.neonYellow),
  TagCategory('music', '音乐', 'Music', AppColors.neonGreen),
];
