import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'ip_tag.dart';

/// 动态类型（参考 Soul 瞬间 + 小红书）
enum FeedType { talk, checkin, haul, seeking }

extension FeedTypeX on FeedType {
  String label(String lang) {
    switch (this) {
      case FeedType.talk:
        return lang == 'en' ? 'Moment' : '畅聊';
      case FeedType.checkin:
        return lang == 'en' ? 'Check-in' : '打卡';
      case FeedType.haul:
        return lang == 'en' ? 'Haul' : '晒单';
      case FeedType.seeking:
        return lang == 'en' ? 'Find Buddy' : '求搭子';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedType.talk:
        return Icons.chat_bubble_outline;
      case FeedType.checkin:
        return Icons.location_on_outlined;
      case FeedType.haul:
        return Icons.shopping_bag_outlined;
      case FeedType.seeking:
        return Icons.group_add_outlined;
    }
  }

  Color get color {
    switch (this) {
      case FeedType.talk:
        return AppColors.neonPurple;
      case FeedType.checkin:
        return AppColors.neonCyan;
      case FeedType.haul:
        return AppColors.neonYellow;
      case FeedType.seeking:
        return AppColors.neonPink;
    }
  }
}

/// 发现页 Feed 流内容卡
class FeedPost {
  final String id;
  final String authorId;
  final String contentZh;
  final String contentEn;
  final IpTag tag;
  final int likes;
  final int comments;
  final double distanceKm;
  final int imageCount; // 占位图数量
  final String coverSeed;
  final FeedType type;
  final String? placeZh; // 打卡/晒单关联地点
  final String? placeEn;
  bool liked;

  FeedPost({
    required this.id,
    required this.authorId,
    required this.contentZh,
    required this.contentEn,
    required this.tag,
    required this.likes,
    required this.comments,
    required this.distanceKm,
    this.imageCount = 1,
    required this.coverSeed,
    this.type = FeedType.talk,
    this.placeZh,
    this.placeEn,
    this.liked = false,
  });

  String content(String lang) => lang == 'en' ? contentEn : contentZh;
  String? place(String lang) => lang == 'en' ? placeEn : placeZh;
}
