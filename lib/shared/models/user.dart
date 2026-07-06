import 'package:flutter/material.dart';

import 'ip_tag.dart';
import 'virtual_avatar.dart';

enum UserStatus {
  gaming,
  openToChat,
  offline,
  exploring,
  busy;

  String label(String lang) {
    switch (this) {
      case UserStatus.gaming:
        return lang == 'en' ? 'Gaming now' : '正在玩';
      case UserStatus.openToChat:
        return lang == 'en' ? 'Open to chat' : '可聊天';
      case UserStatus.offline:
        return lang == 'en' ? 'Offline' : '离线';
      case UserStatus.exploring:
        return lang == 'en' ? 'Exploring' : '探索中';
      case UserStatus.busy:
        return lang == 'en' ? 'Busy' : '忙碌';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.gaming:
        return const Color(0xFF34A853);
      case UserStatus.openToChat:
        return const Color(0xFF4285F4);
      case UserStatus.offline:
        return const Color(0xFFAFAFAF);
      case UserStatus.exploring:
        return const Color(0xFFFBBC05);
      case UserStatus.busy:
        return const Color(0xFFEA4335);
    }
  }
}

/// 用户资料模型
class UserProfile {
  final String id;
  final String nickname;
  final String avatarSeed; // 用于生成占位头像渐变
  final VirtualAvatar? virtualAvatar;
  final String bio;
  final List<IpTag> tags;
  final double lat;
  final double lng;
  final String city;
  final bool online;
  final int age;
  final String gender; // m / f
  final bool verified;
  final UserStatus status;
  final int level;
  final String personality;

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarSeed,
    this.virtualAvatar,
    required this.bio,
    required this.tags,
    required this.lat,
    required this.lng,
    this.city = '深圳',
    this.online = false,
    this.age = 22,
    this.gender = 'f',
    this.verified = false,
    this.status = UserStatus.gaming,
    this.level = 1,
    this.personality = '',
  });

  UserProfile copyWith({
    String? nickname,
    String? bio,
    List<IpTag>? tags,
    VirtualAvatar? virtualAvatar,
    bool? verified,
    UserStatus? status,
    int? level,
    String? personality,
  }) {
    return UserProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarSeed: avatarSeed,
      virtualAvatar: virtualAvatar ?? this.virtualAvatar,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      lat: lat,
      lng: lng,
      city: city,
      online: online,
      age: age,
      gender: gender,
      verified: verified ?? this.verified,
      status: status ?? this.status,
      level: level ?? this.level,
      personality: personality ?? this.personality,
    );
  }

  /// 与另一用户的兴趣重合标签
  List<IpTag> commonTags(List<IpTag> others) {
    final otherIds = others.map((e) => e.id).toSet();
    return tags.where((t) => otherIds.contains(t.id)).toList();
  }

  /// 匹配度百分比（基于标签重合度 + 距离衰减），0-100
  int matchRate(List<IpTag> myTags) {
    if (myTags.isEmpty || tags.isEmpty) return 0;
    final common = commonTags(myTags).length;
    final union = {...myTags.map((e) => e.id), ...tags.map((e) => e.id)}.length;
    final jaccard = common / union;
    return (jaccard * 100).clamp(12, 99).round();
  }
}
