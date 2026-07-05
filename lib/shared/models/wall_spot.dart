import 'ip_tag.dart';

/// 聚合后的留言板地点
class WallSpot {
  final String id;
  final double lat;
  final double lng;
  final IpTag primaryTag;
  final int messageCount;
  final List<IpTag> tags;

  const WallSpot({
    required this.id,
    required this.lat,
    required this.lng,
    required this.primaryTag,
    required this.messageCount,
    required this.tags,
  });

  /// 标记着色：优先与用户重合的标签，否则用主标签
  IpTag displayTag(List<IpTag> userTags) {
    for (final t in tags) {
      if (userTags.contains(t)) return t;
    }
    return primaryTag;
  }
}
