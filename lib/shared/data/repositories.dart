import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/config/map_config.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/services/content_filter.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/wall_cluster.dart';
import '../models/activity.dart';
import '../models/hive_room.dart';
import '../models/ip_tag.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/virtual_avatar.dart';
import '../models/board.dart';
import '../models/wall_spot.dart';
import 'avatar_generator_repository.dart';
import 'mock_data_source.dart';

final mockProvider = Provider<MockDataSource>((ref) => MockDataSource.instance);

/// 设备/用户唯一标识，用于后端统计每日生成配额（首次生成随机生成并持久化）
final deviceTokenProvider = Provider<String>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  const key = 'ai_avatar_device_token';
  var token = prefs.getString(key);
  if (token == null || token.isEmpty) {
    final rand = Random();
    token = List.generate(16, (_) => rand.nextInt(16).toRadixString(16)).join();
    prefs.setString(key, token);
  }
  return token;
});

/// AI 头像生成仓库：真实实现调用自建后端代理 Gemini 图生图。
/// 若需要离线/演示模式，可手动切换回 MockAvatarGeneratorRepository()。
final avatarGeneratorProvider = Provider<AvatarGeneratorRepository>((ref) {
  return GeminiAvatarGeneratorRepository(
    endpoint: Uri.parse(ApiConfig.generateAvatarUrl),
    userToken: ref.watch(deviceTokenProvider),
  );
});

final avatarByUserIdProvider = Provider.family<VirtualAvatar?, String>((ref, userId) {
  if (userId == 'me') return ref.watch(currentUserProvider).virtualAvatar;
  return ref.watch(mockProvider).userById(userId).virtualAvatar;
});

/// 当前登录用户（可编辑：标签、昵称、简介）
final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, UserProfile>(CurrentUserNotifier.new);

class CurrentUserNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => ref.read(mockProvider).me;

  /// 用户可关注的最大标签数（鼓励聚焦）
  int get maxTags => 8;

  void updateTags(List<IpTag> tags) {
    final capped = tags.take(maxTags).toList();
    state = state.copyWith(tags: capped);
    ref.read(mockProvider).me = state;
  }

  void updateProfile({String? nickname, String? bio}) {
    state = state.copyWith(nickname: nickname, bio: bio);
    ref.read(mockProvider).me = state;
  }

  void updateVirtualAvatar(VirtualAvatar avatar) {
    state = state.copyWith(virtualAvatar: avatar);
    ref.read(mockProvider).me = state;
  }
}

/// 好友：存储好友用户 id 集合（内存态 + 少量初始好友用于演示）。
final friendsProvider =
    NotifierProvider<FriendsNotifier, Set<String>>(FriendsNotifier.new);

class FriendsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final users = ref.read(mockProvider).users;
    return users.take(2).map((u) => u.id).toSet();
  }

  void add(String id) => state = {...state, id};
  void remove(String id) => state = ({...state}..remove(id));
  void toggle(String id) => state.contains(id) ? remove(id) : add(id);
}

/// 带距离信息的附近用户
class UserWithDistance {
  final UserProfile user;
  final double distanceKm;
  final int matchRate;
  final List<IpTag> common;
  const UserWithDistance(this.user, this.distanceKm, this.matchRate, this.common);
}

/// 附近同好：按距离排序 + 计算匹配度（可被距离过滤）
final nearbyUsersProvider = Provider<List<UserWithDistance>>((ref) {
  final mock = ref.watch(mockProvider);
  final me = ref.watch(currentUserProvider);
  final list = mock.users.map((u) {
    final d = haversineKm(me.lat, me.lng, u.lat, u.lng);
    final common = u.commonTags(me.tags);
    return UserWithDistance(u, d, u.matchRate(me.tags), common);
  }).toList()
    ..sort((a, b) {
      // 先按匹配度，再按距离
      final m = b.matchRate.compareTo(a.matchRate);
      return m != 0 ? m : a.distanceKm.compareTo(b.distanceKm);
    });
  return list;
});

/// 活动列表（支持报名 / 签到 / 发布）
final activitiesProvider =
    NotifierProvider<ActivitiesNotifier, List<ActivityItem>>(
        ActivitiesNotifier.new);

class ActivitiesNotifier extends Notifier<List<ActivityItem>> {
  @override
  List<ActivityItem> build() => [...ref.read(mockProvider).activities];

  void toggleJoin(String id) {
    state = [
      for (final a in state)
        if (a.id == id)
          (a
            ..joined = !a.joined
            ..checkedIn = a.joined ? a.checkedIn : a.checkedIn)
        else
          a
    ];
    // 触发刷新
    state = [...state];
  }

  void checkIn(String id) {
    for (final a in state) {
      if (a.id == id) a.checkedIn = true;
    }
    state = [...state];
  }

  void create(ActivityItem item) {
    state = [item, ...state];
    ref.read(mockProvider).activities.insert(0, item);
  }

  ActivityItem byId(String id) => state.firstWhere((a) => a.id == id);
}

/// 会话列表
final conversationsProvider = Provider((ref) => ref.watch(mockProvider).conversations);

/// 单个会话消息流（支持发送 + 自动回复）
final chatProvider =
    NotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
        ChatNotifier.new);

class ChatNotifier extends FamilyNotifier<List<ChatMessage>, String> {
  @override
  List<ChatMessage> build(String convId) {
    return [...?ref.read(mockProvider).messages[convId]];
  }

  void send(String text, {bool isImage = false}) {
    final msg = ChatMessage(
      id: '${arg}_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: arg,
      senderId: 'me',
      type: isImage ? MessageType.image : MessageType.text,
      content: isImage ? 'my_img' : text,
      time: DateTime.now(),
    );
    state = [...state, msg];
    // 模拟对方 1-2s 后回复
    Future.delayed(const Duration(milliseconds: 1400), () {
      final reply = ref.read(mockProvider).autoReply(arg);
      state = [...state, reply];
    });
  }
}

/// 异步留言墙消息列表
final boardsProvider =
    NotifierProvider<BoardsNotifier, List<Board>>(BoardsNotifier.new);

class BoardsNotifier extends Notifier<List<Board>> {
  @override
  List<Board> build() => [...ref.read(mockProvider).boards];

  /// 发布留言（含内容审核）。
  /// 返回 (Board?, String?) — 成功返回留言对象，失败返回拦截原因。
  (Board?, String?) postBoard({
    required String content,
    required double lat,
    required double lng,
    required UserProfile author,
  }) {
    final trimmed = content.trim();
    final (code, reason) = ContentFilter.check(trimmed);
    final isVisible = code == ContentFilter.pass;

    final spotId = spotIdForCoordinate(state, lat, lng);
    final msg = Board(
      id: 'wm_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      lat: lat,
      lng: lng,
      authorId: author.id,
      avatarSeed: author.avatarSeed,
      tags: author.tags,
      content: trimmed,
      isVisible: isVisible,
      createdAt: DateTime.now(),
    );
    state = [...state, msg];
    ref.read(mockProvider).boards.add(msg);

    if (!isVisible) {
      return (null, reason ?? '内容包含不当信息，请修改后重试');
    }
    return (msg, null);
  }

  /// 在当前位置创建留言板并发布首条留言；100m 内已有留言板时在该板追加留言。
  /// 内容经过审核，违规内容返回 null。
  WallSpot? createWallSpot({
    required double lat,
    required double lng,
    required UserProfile author,
    required List<IpTag> tags,
    required String content,
  }) {
    final trimmed = content.trim();
    final (code, _) = ContentFilter.check(trimmed);
    final isVisible = code == ContentFilter.pass;

    final spotId = spotIdForCoordinate(state, lat, lng);
    final msg = Board(
      id: 'wm_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      lat: lat,
      lng: lng,
      authorId: author.id,
      avatarSeed: author.avatarSeed,
      tags: tags,
      content: trimmed,
      isVisible: isVisible,
      createdAt: DateTime.now(),
    );
    state = [...state, msg];
    ref.read(mockProvider).boards.add(msg);

    if (!isVisible) return null;
    return findSpotNear(state, lat, lng);
  }

  /// 点赞/取消点赞（共鸣）
  void toggleLike(String messageId) {
    state = [
      for (final m in state)
        if (m.id == messageId)
          Board(
            id: m.id,
            spotId: m.spotId,
            lat: m.lat,
            lng: m.lng,
            authorId: m.authorId,
            avatarSeed: m.avatarSeed,
            tags: m.tags,
            content: m.content,
            likeCount: m.likedByMe ? m.likeCount - 1 : m.likeCount + 1,
            likedByMe: !m.likedByMe,
            isVisible: m.isVisible,
            isDeleted: m.isDeleted,
            createdAt: m.createdAt,
            parentId: m.parentId,
          )
        else
          m,
    ];
  }

  /// 回复留言
  (Board?, String?) postReply({
    required String content,
    required Board parent,
    required UserProfile author,
  }) {
    final trimmed = content.trim();
    final (code, reason) = ContentFilter.check(trimmed);
    final isVisible = code == ContentFilter.pass;

    final msg = Board(
      id: 'wm_${DateTime.now().millisecondsSinceEpoch}',
      spotId: parent.spotId,
      lat: parent.lat,
      lng: parent.lng,
      authorId: author.id,
      avatarSeed: author.avatarSeed,
      tags: author.tags,
      content: trimmed,
      parentId: parent.id,
      replyToAuthorId: parent.authorId,
      isVisible: isVisible,
      createdAt: DateTime.now(),
    );
    state = [...state, msg];
    ref.read(mockProvider).boards.add(msg);

    if (!isVisible) {
      return (null, reason ?? '回复包含不当内容');
    }
    return (msg, null);
  }

  /// 软删除留言
  void softDelete(String messageId) {
    state = [
      for (final m in state)
        if (m.id == messageId)
          Board(
            id: m.id,
            spotId: m.spotId,
            lat: m.lat,
            lng: m.lng,
            authorId: m.authorId,
            avatarSeed: m.avatarSeed,
            tags: m.tags,
            content: '[该留言已删除]',
            likeCount: m.likeCount,
            likedByMe: m.likedByMe,
            isVisible: m.isVisible,
            isDeleted: true,
            createdAt: m.createdAt,
            parentId: m.parentId,
          )
        else
          m,
    ];
  }
}

/// 全量留言板聚合点
final wallSpotsProvider = Provider<List<WallSpot>>((ref) {
  final messages = ref.watch(boardsProvider);
  return buildWallSpots(messages);
});

/// 地图标签筛选。
/// 初始化时默认全选当前用户的全部标签（底部按钮均为选中态）；空集 = 全部隐藏。
/// 同时作用于地图上的留言板、活动与附近用户三类标记。
final wallTagFilterProvider = StateProvider<Set<IpTag>>(
  (ref) => ref.read(currentUserProvider).tags.toSet(),
);

/// 雷达范围内 + 标签过滤后的可见留言板
final visibleWallSpotsProvider = Provider<List<WallSpot>>((ref) {
  final spots = ref.watch(wallSpotsProvider);
  final fallback = ref.watch(mapCenterProvider);
  final loc = ref.watch(currentLocationProvider).valueOrNull;
  final lat = loc?.latitude ?? fallback.latitude;
  final lng = loc?.longitude ?? fallback.longitude;
  final filters = ref.watch(wallTagFilterProvider);
  // 一个标签都不选 = 全部隐藏。
  if (filters.isEmpty) return const [];
  const maxKm = MapConfig.radarMaxRangeKm;
  return spots.where((spot) {
    if (!isWithinKm(lat, lng, spot.lat, spot.lng, maxKm)) return false;
    if (!spot.tags.any((tag) => filters.contains(tag))) return false;
    return true;
  }).toList();
});

/// 某留言板的历史留言（按时间倒序）
final boardsForSpotProvider = Provider.family<List<Board>, String>((ref, spotId) {
  final messages = ref.watch(boardsProvider);
  final spots = ref.watch(wallSpotsProvider);
  WallSpot? spot;
  for (final s in spots) {
    if (s.id == spotId) {
      spot = s;
      break;
    }
  }
  if (spot == null) return [];
  return messagesForSpot(messages, spot);
});

// ══════════════════════════════════════════════════════════════════
// Block 3：蜂巢数据驱动
// ══════════════════════════════════════════════════════════════════

/// 蜂巢房间列表（从用户 tag 动态生成，3-6 格）
///
/// 逻辑：
/// 1. 取当前用户的前 6 个 tag，每个 tag = 一个房间
/// 2. 按同好数排序（附近有多少用户共享此 tag）
/// 3. 不足 3 格时从全局热门 tag 补位
/// 4. 每 60s 重新计算（或推送即时刷新）
final hiveRoomsProvider = Provider<List<HiveRoomData>>((ref) {
  final mock = ref.watch(mockProvider);
  final me = ref.watch(currentUserProvider);
  final nearby = ref.watch(nearbyUsersProvider);

  // 1. 取当前用户 tag（最多 6 个）
  final myTags = me.tags.take(6).toList();

  // 2. 每个 tag 生成一个房间
  final rooms = <HiveRoomData>[];
  for (final tag in myTags) {
    final sameTagUsers = nearby.where((u) {
      return u.user.tags.any((t) => t.id == tag.id);
    }).toList();

    rooms.add(HiveRoomData(
      id: 'hive_${tag.id}',
      tag: tag,
      title: tag.name('zh'),
      action: _actionForTag(tag),
      icon: tag.icon,
      emoji: _emojiForTag(tag),
      color: tag.color,
      onlineCount: sameTagUsers.where((u) => u.user.online).length,
      users: sameTagUsers.take(4).map((u) => u.user).toList(),
    ));
  }

  // 3. 按同好数排序
  rooms.sort((a, b) => b.onlineCount.compareTo(a.onlineCount));

  // 4. 不足 3 格时从全局热门补位
  if (rooms.length < 3) {
    final allTags = mock.tags;
    // 取未被用户 tag 包含的热门 tag
    final hotTags = allTags
        .where((t) => !myTags.any((mt) => mt.id == t.id))
        .take(3 - rooms.length)
        .toList();

    for (final tag in hotTags) {
      final sameTagUsers = nearby.where((u) {
        return u.user.tags.any((t) => t.id == tag.id);
      }).toList();

      rooms.add(HiveRoomData(
        id: 'hive_${tag.id}',
        tag: tag,
        title: '🔥 ${tag.name('zh')}',
        action: '热门推荐',
        icon: tag.icon,
        emoji: _emojiForTag(tag),
        color: tag.color,
        onlineCount: sameTagUsers.where((u) => u.user.online).length,
        users: sameTagUsers.take(4).map((u) => u.user).toList(),
        isHotFill: true,
      ));
    }
  }

  return rooms.take(6).toList();
});

String _emojiForTag(ipTag) {
  switch (ipTag.category) {
    case 'game':
      return '🎮';
    case 'anime':
      return '🎬';
    case 'drama':
      return '📺';
    case 'comic':
      return '📚';
    case 'music':
      return '🎵';
    default:
      return '⬡';
  }
}

String _actionForTag(ipTag) {
  switch (ipTag.category) {
    case 'game':
      return '一起开黑';
    case 'anime':
      return '一起追番';
    case 'drama':
      return '一起追剧';
    case 'comic':
      return '一起看漫';
    case 'music':
      return '一起听歌';
    default:
      return '一起玩耍';
  }
}
