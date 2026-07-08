import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// IP 标签：兴趣单元，含分类与展示色
class IpTag {
  final String id;
  final String nameZh;
  final String nameEn;
  final String category; // game / anime / drama / comic / music
  final IconData icon;

  /// 是否为官方预设标签（false = 用户自定义，需审核）
  final bool isOfficial;

  /// 自定义标签审核状态（官方标签始终为 true）
  final bool isApproved;

  /// 细粒度子标签：如 「原神/3.0/钟离/cp向」
  final List<String>? subTags;

  const IpTag({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.icon,
    this.isOfficial = true,
    this.isApproved = true,
    this.subTags,
  });

  /// 预设官方标签便捷构造（向后兼容）
  const IpTag.official({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.icon,
    this.subTags,
  })  : isOfficial = true,
        isApproved = true;

  /// 用户自定义标签构造
  const IpTag.custom({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.category,
    required this.icon,
    this.subTags,
  })  : isOfficial = false,
        isApproved = false;

  /// 标签展示名称（含审核中状态）
  String displayName(String lang) {
    final base = lang == 'en' ? nameEn : nameZh;
    if (!isOfficial && !isApproved) return '$base (审核中)';
    return base;
  }

  String name(String lang) => lang == 'en' ? nameEn : nameZh;

  Color get color => AppColors.categoryColors[category] ?? AppColors.neonPurple;

  @override
  bool operator ==(Object other) => other is IpTag && other.id == id;

  @override
  int get hashCode => id.hashCode;

  /// 创建一个审核通过的副本
  IpTag approved() => IpTag(
        id: id,
        nameZh: nameZh,
        nameEn: nameEn,
        category: category,
        icon: icon,
        isOfficial: isOfficial,
        isApproved: true,
        subTags: subTags,
      );
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
