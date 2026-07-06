import 'ip_tag.dart';

/// 异步留言墙单条留言
class WallMessage {
  final String id;
  final String spotId;
  final double lat;
  final double lng;
  final String authorId;
  final String avatarSeed;
  final List<IpTag> tags;
  final String content;
  final DateTime createdAt;

  const WallMessage({
    required this.id,
    required this.spotId,
    required this.lat,
    required this.lng,
    required this.authorId,
    required this.avatarSeed,
    required this.tags,
    required this.content,
    required this.createdAt,
  });
}
