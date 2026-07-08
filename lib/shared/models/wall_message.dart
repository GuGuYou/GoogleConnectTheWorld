import 'ip_tag.dart';

/// 留言内容类型
enum WallContentType { text, voice, image, mixed }

/// 异步留言墙单条留言（Block 1A 升级版）
class WallMessage {
  final String id;
  final String spotId;
  final double lat;
  final double lng;
  final String authorId;
  final String avatarSeed;
  final List<IpTag> tags;

  // ---- 多类型内容 ----
  final WallContentType contentType;
  final String content; // 文本内容（向后兼容）
  final String? voiceUrl; // 语音文件 URL（≤60s）
  final int? voiceDurationSec;
  final List<String>? imageUrls; // 图片 URL 列表（≤3张，≤5MB/张）

  // ---- 二级回复 ----
  final String? parentId; // 回复的目标留言 id（null = 根留言）
  final String? replyToAuthorId;

  // ---- 社交互动 ----
  final int likeCount; // 共鸣数
  final bool likedByMe; // 当前用户是否已赞

  // ---- 生命周期 ----
  final bool isVisible; // 审核状态：false = 机审隐藏
  final bool isDeleted; // 软删除标记
  final DateTime createdAt;
  final DateTime? editedAt;

  /// 占位锚点：用于在用户位置创建空留言板，不在留言列表中展示
  final bool isAnchor;

  const WallMessage({
    required this.id,
    required this.spotId,
    required this.lat,
    required this.lng,
    required this.authorId,
    required this.avatarSeed,
    required this.tags,
    this.contentType = WallContentType.text,
    required this.content,
    this.voiceUrl,
    this.voiceDurationSec,
    this.imageUrls,
    this.parentId,
    this.replyToAuthorId,
    this.likeCount = 0,
    this.likedByMe = false,
    this.isVisible = true,
    this.isDeleted = false,
    required this.createdAt,
    this.editedAt,
    this.isAnchor = false,
  });

  /// 创建带有默认审核通过状态的留言（便捷构造）
  const WallMessage.clean({
    required this.id,
    required this.spotId,
    required this.lat,
    required this.lng,
    required this.authorId,
    required this.avatarSeed,
    required this.tags,
    this.contentType = WallContentType.text,
    required this.content,
    this.voiceUrl,
    this.voiceDurationSec,
    this.imageUrls,
    this.parentId,
    this.replyToAuthorId,
    this.likeCount = 0,
    this.likedByMe = false,
    required this.createdAt,
    this.editedAt,
    this.isAnchor = false,
  })  : isVisible = true,
        isDeleted = false;

  /// 用于展示的可见留言（排除锚点、已删除、审核未通过）
  bool get isDisplayable => !isAnchor && !isDeleted && isVisible;
}
