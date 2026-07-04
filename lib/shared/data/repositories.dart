import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/distance.dart';
import '../models/activity.dart';
import '../models/feed_post.dart';
import '../models/ip_tag.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/virtual_avatar.dart';
import 'avatar_generator_repository.dart';
import 'mock_data_source.dart';

final mockProvider = Provider<MockDataSource>((ref) => MockDataSource.instance);

final avatarGeneratorProvider = Provider<AvatarGeneratorRepository>(
  (ref) => MockAvatarGeneratorRepository(),
);

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

  void updateTags(List<IpTag> tags) {
    state = state.copyWith(tags: tags);
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

/// 距离筛选（公里），0 = 全部
final distanceFilterProvider = StateProvider<double>((ref) => 0);

/// 发现页 Feed（可按距离筛选）
final feedsProvider = Provider<List<FeedPost>>((ref) {
  final mock = ref.watch(mockProvider);
  final maxKm = ref.watch(distanceFilterProvider);
  final list = [...mock.feeds];
  if (maxKm > 0) {
    return list.where((f) => f.distanceKm <= maxKm).toList();
  }
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
