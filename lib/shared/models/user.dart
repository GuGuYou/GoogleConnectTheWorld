import 'ip_tag.dart';
import 'virtual_avatar.dart';

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
  final bool verified;
  final int age;
  final String gender; // m / f
  /// 地图用户气泡是否绘制六边形外框。
  final bool showHexFrame;

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
    this.verified = false,
    this.age = 22,
    this.gender = 'f',
    this.showHexFrame = true,
  });

  UserProfile copyWith({
    String? nickname,
    String? bio,
    List<IpTag>? tags,
    VirtualAvatar? virtualAvatar,
    double? lat,
    double? lng,
    String? city,
    bool? showHexFrame,
  }) {
    return UserProfile(
      id: id,
      nickname: nickname ?? this.nickname,
      avatarSeed: avatarSeed,
      virtualAvatar: virtualAvatar ?? this.virtualAvatar,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      city: city ?? this.city,
      online: online,
      verified: verified,
      age: age,
      gender: gender,
      showHexFrame: showHexFrame ?? this.showHexFrame,
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
