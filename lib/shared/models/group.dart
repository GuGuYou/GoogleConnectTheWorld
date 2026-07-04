import 'ip_tag.dart';

/// 频道类型（参考 Discord 文字/语音频道）
enum ChannelType { text, voice }

/// 圈子内频道
class GroupChannel {
  final String id;
  final String nameZh;
  final String nameEn;
  final ChannelType type;
  final int activeCount; // 文字=今日消息数 / 语音=在麦人数
  const GroupChannel({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    this.type = ChannelType.text,
    this.activeCount = 0,
  });

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
}

/// 语音派对房（参考 Discord 语音房 + Soul 群聊派对）
class VoiceRoom {
  final String id;
  final String titleZh;
  final String titleEn;
  final String hostId;
  final List<String> speakerSeeds; // 麦上用户头像 seed
  final int listeners;
  const VoiceRoom({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.hostId,
    this.speakerSeeds = const [],
    this.listeners = 0,
  });

  String title(String lang) => lang == 'en' ? titleEn : titleZh;
}

/// IP 同好圈子（参考 Discord 服务器）
class IpGroup {
  final String id;
  final IpTag tag;
  final String nameZh;
  final String nameEn;
  final String descZh;
  final String descEn;
  final int members;
  final int onlineNow;
  final List<GroupChannel> channels;
  final List<VoiceRoom> voiceRooms;
  bool joined;

  IpGroup({
    required this.id,
    required this.tag,
    required this.nameZh,
    required this.nameEn,
    required this.descZh,
    required this.descEn,
    required this.members,
    required this.onlineNow,
    this.channels = const [],
    this.voiceRooms = const [],
    this.joined = false,
  });

  String name(String lang) => lang == 'en' ? nameEn : nameZh;
  String desc(String lang) => lang == 'en' ? descEn : descZh;
}
