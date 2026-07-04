import 'ip_tag.dart';

/// 用户在线状态（参考 Discord：精准告知"现在能不能聊"）
enum UserStatus { online, idle, dnd, inEvent, offline }

extension UserStatusX on UserStatus {
  String label(String lang) {
    switch (this) {
      case UserStatus.online:
        return lang == 'en' ? 'Online' : '在线';
      case UserStatus.idle:
        return lang == 'en' ? 'Idle' : '空闲';
      case UserStatus.dnd:
        return lang == 'en' ? 'Do Not Disturb' : '请勿打扰';
      case UserStatus.inEvent:
        return lang == 'en' ? 'In an Event' : '活动中';
      case UserStatus.offline:
        return lang == 'en' ? 'Offline' : '离线';
    }
  }
}

/// 用户资料模型
class UserProfile {
  final String id;
  final String nickname;
  final String avatarSeed; // 用于生成占位头像渐变
  final String bio;
  final List<IpTag> tags;
  final double lat;
  final double lng;
  final String city;
  final bool online;
  final int age;
  final String gender; // m / f
  final UserStatus status; // 精准状态
  final bool verified; // 资深同好认证
  final int level; // 同好度等级 1-4
  final String personality; // 兴趣人格 key（可空）

  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarSeed,
    required this.bio,
    required this.tags,
    required this.lat,
    required this.lng,
    this.city = '深圳',
    this.online = false,
    this.age = 22,
    this.gender = 'f',
    this.status = UserStatus.offline,
    this.verified = false,
    this.level = 1,
    this.personality = '',
  });

  UserProfile copyWith({
    String? nickname,
    String? avatarSeed,
    String? bio,
    List<IpTag>? tags,
    UserStatus? status,
    bool? verified,
    int? level,
    String? personality,
  }) {
    return UserProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarSeed: avatarSeed ?? this.avatarSeed,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      lat: lat,
      lng: lng,
      city: city,
      online: online,
      age: age,
      gender: gender,
      status: status ?? this.status,
      verified: verified ?? this.verified,
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
