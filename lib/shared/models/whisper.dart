/// 异步留言（Whisper）：地理位置绑定的"漂流瓶"式匿名留言。
///
/// 与 [ChatMessage]（点对点实时聊天）是完全不同的两套模型——
/// 用户可以在地图/空间某个坐标留下一句话，路过的同好能看到历史留言、
/// 产生"共鸣"，但不强制建立好友关系或进行实时对话。这是产品
/// "异步、低压力、找同好而非加好友"核心理念的具体载体。
class Whisper {
  final String id;
  final String authorId;
  final String authorNickname;
  final String authorAvatarSeed;
  final String contentZh;
  final String contentEn;
  final double lat;
  final double lng;
  final DateTime createdAt;
  final int resonanceCount;

  const Whisper({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.authorAvatarSeed,
    required this.contentZh,
    required this.contentEn,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.resonanceCount = 0,
  });

  String content(String lang) => lang == 'en' ? contentEn : contentZh;

  Whisper copyWith({int? resonanceCount}) => Whisper(
        id: id,
        authorId: authorId,
        authorNickname: authorNickname,
        authorAvatarSeed: authorAvatarSeed,
        contentZh: contentZh,
        contentEn: contentEn,
        lat: lat,
        lng: lng,
        createdAt: createdAt,
        resonanceCount: resonanceCount ?? this.resonanceCount,
      );
}
