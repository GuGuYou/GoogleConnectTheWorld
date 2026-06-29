import 'ip_tag.dart';

/// 线下活动模型
class ActivityItem {
  final String id;
  final String titleZh;
  final String titleEn;
  final String category;
  final IpTag tag;
  final DateTime time;
  final String locationZh;
  final String locationEn;
  final double lat;
  final double lng;
  final String hostId;
  final String descZh;
  final String descEn;
  final int participants;
  final int maxParticipants;
  final List<String> participantAvatarSeeds;
  bool joined;
  bool checkedIn;

  ActivityItem({
    required this.id,
    required this.titleZh,
    required this.titleEn,
    required this.category,
    required this.tag,
    required this.time,
    required this.locationZh,
    required this.locationEn,
    required this.lat,
    required this.lng,
    required this.hostId,
    required this.descZh,
    required this.descEn,
    required this.participants,
    this.maxParticipants = 20,
    this.participantAvatarSeeds = const [],
    this.joined = false,
    this.checkedIn = false,
  });

  String title(String lang) => lang == 'en' ? titleEn : titleZh;
  String location(String lang) => lang == 'en' ? locationEn : locationZh;
  String desc(String lang) => lang == 'en' ? descEn : descZh;
}
