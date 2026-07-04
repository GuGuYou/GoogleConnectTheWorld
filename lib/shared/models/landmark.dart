import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 同好地标类型
enum LandmarkType { con, goods, boardgame, cafe }

extension LandmarkTypeX on LandmarkType {
  String label(String lang) {
    switch (this) {
      case LandmarkType.con:
        return lang == 'en' ? 'Comic Con' : '漫展';
      case LandmarkType.goods:
        return lang == 'en' ? 'Goods Shop' : '谷子店';
      case LandmarkType.boardgame:
        return lang == 'en' ? 'Board Game' : '桌游吧';
      case LandmarkType.cafe:
        return lang == 'en' ? 'Anime Cafe' : '二次元咖啡';
    }
  }

  IconData get icon {
    switch (this) {
      case LandmarkType.con:
        return Icons.festival;
      case LandmarkType.goods:
        return Icons.storefront;
      case LandmarkType.boardgame:
        return Icons.casino;
      case LandmarkType.cafe:
        return Icons.local_cafe;
    }
  }

  Color get color {
    switch (this) {
      case LandmarkType.con:
        return AppColors.neonPink;
      case LandmarkType.goods:
        return AppColors.neonYellow;
      case LandmarkType.boardgame:
        return AppColors.neonGreen;
      case LandmarkType.cafe:
        return AppColors.neonCyan;
    }
  }
}

/// 附近同好地标（不只找人，还找好去处）
class Landmark {
  final String id;
  final String nameZh;
  final String nameEn;
  final LandmarkType type;
  final double lat;
  final double lng;
  final double distanceKm;
  final int fansHere; // 附近多少同好来过 / 想去
  final bool hasEvent; // 周末是否有活动
  bool visited;

  Landmark({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.type,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.fansHere = 0,
    this.hasEvent = false,
    this.visited = false,
  });

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
}
