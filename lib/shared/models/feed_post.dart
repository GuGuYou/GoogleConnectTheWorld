import 'ip_tag.dart';

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

  const FeedPost({
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
  });

  String content(String lang) => lang == 'en' ? contentEn : contentZh;
}
