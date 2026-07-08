import 'package:flutter/material.dart';

import 'ip_tag.dart';
import 'user.dart';

/// 蜂巢房间数据模型（Block 3：数据驱动改造成果）
///
/// 每个房间对应一个 tag，从用户 tag 列表动态生成。
/// 3-6 格自适应布局，不足 3 格时从全局热门补位。
class HiveRoomData {
  final String id;
  final IpTag tag;
  final String title;
  final String action;
  final IconData icon;
  final String emoji;
  final Color color;
  final int onlineCount;
  final int unreadCount;
  final List<UserProfile> users;
  final bool isHotFill; // 是否为热门补位房间

  const HiveRoomData({
    required this.id,
    required this.tag,
    required this.title,
    required this.action,
    this.icon = Icons.hexagon_rounded,
    this.emoji = '⬡',
    this.color = Colors.amber,
    this.onlineCount = 0,
    this.unreadCount = 0,
    this.users = const [],
    this.isHotFill = false,
  });

  bool get hasUnread => unreadCount > 0;
}
