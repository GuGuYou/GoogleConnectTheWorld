import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/distance.dart';
import '../models/activity.dart';
import '../models/feed_post.dart';
import '../models/gamification.dart';
import '../models/group.dart';
import '../models/ip_tag.dart';
import '../models/landmark.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'mock_data_source.dart';

final mockProvider = Provider<MockDataSource>((ref) => MockDataSource.instance);

/// 当前登录用户（可编辑：标签、昵称、简介、状态、人格）
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

  void updateAvatar(String avatarPath) {
    state = state.copyWith(avatarSeed: avatarPath);
    ref.read(mockProvider).me = state;
  }

  void updateStatus(UserStatus status) {
    state = state.copyWith(status: status);
    ref.read(mockProvider).me = state;
  }

  void setPersonality(String key) {
    state = state.copyWith(personality: key);
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

/// 动态类型筛选，null = 全部
final feedTypeFilterProvider = StateProvider<FeedType?>((ref) => null);

/// 发现页 Feed（支持发布 / 点赞）
final feedsProvider =
    NotifierProvider<FeedsNotifier, List<FeedPost>>(FeedsNotifier.new);

class FeedsNotifier extends Notifier<List<FeedPost>> {
  @override
  List<FeedPost> build() => [...ref.read(mockProvider).feeds];

  void addPost(FeedPost post) {
    state = [post, ...state];
    ref.read(mockProvider).feeds.insert(0, post);
  }

  void toggleLike(String id) {
    state = [
      for (final f in state)
        if (f.id == id) (f..liked = !f.liked) else f
    ];
    state = [...state];
  }
}

/// 经过距离 + 类型筛选后的 Feed
final filteredFeedsProvider = Provider<List<FeedPost>>((ref) {
  final all = ref.watch(feedsProvider);
  final maxKm = ref.watch(distanceFilterProvider);
  final type = ref.watch(feedTypeFilterProvider);
  return all.where((f) {
    final okKm = maxKm == 0 || f.distanceKm <= maxKm;
    final okType = type == null || f.type == type;
    return okKm && okType;
  }).toList();
});

/// 活动列表（支持报名 / 签到 / 发布 / 约起补位）
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

/// 圈子（Discord 化）：支持加入 / 退出
final groupsProvider =
    NotifierProvider<GroupsNotifier, List<IpGroup>>(GroupsNotifier.new);

class GroupsNotifier extends Notifier<List<IpGroup>> {
  @override
  List<IpGroup> build() => [...ref.read(mockProvider).groups];

  void toggleJoin(String id) {
    for (final g in state) {
      if (g.id == id) g.joined = !g.joined;
    }
    state = [...state];
  }

  IpGroup byId(String id) => state.firstWhere((g) => g.id == id);
}

/// 同好地标：支持标记"去过"
final landmarksProvider =
    NotifierProvider<LandmarksNotifier, List<Landmark>>(LandmarksNotifier.new);

class LandmarksNotifier extends Notifier<List<Landmark>> {
  @override
  List<Landmark> build() => [...ref.read(mockProvider).landmarks];

  void toggleVisited(String id) {
    for (final l in state) {
      if (l.id == id) l.visited = !l.visited;
    }
    state = [...state];
  }
}

/// 游戏化状态：连续打卡 / 经验 / 等级 / 每日任务
class GamificationState {
  final int streak; // 连续打卡天数
  final int xp; // 经验值
  final bool checkedToday;
  final List<DailyTask> tasks;
  const GamificationState({
    required this.streak,
    required this.xp,
    required this.checkedToday,
    required this.tasks,
  });

  int get level => (xp ~/ 100) + 1;
  int get xpInLevel => xp % 100;
  int get tasksDone => tasks.where((t) => t.done).length;

  GamificationState copyWith({int? streak, int? xp, bool? checkedToday, List<DailyTask>? tasks}) {
    return GamificationState(
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
      checkedToday: checkedToday ?? this.checkedToday,
      tasks: tasks ?? this.tasks,
    );
  }
}

final gamificationProvider =
    NotifierProvider<GamificationNotifier, GamificationState>(
        GamificationNotifier.new);

class GamificationNotifier extends Notifier<GamificationState> {
  @override
  GamificationState build() {
    return GamificationState(
      streak: 6,
      xp: 145,
      checkedToday: false,
      tasks: ref.read(mockProvider).buildDailyTasks(),
    );
  }

  void checkInToday() {
    if (state.checkedToday) return;
    state = state.copyWith(streak: state.streak + 1, xp: state.xp + 5, checkedToday: true);
  }

  /// 完成某项任务 +1 进度（达成时加经验）
  void progressTask(String id) {
    var gainedXp = 0;
    final tasks = [
      for (final t in state.tasks)
        if (t.id == id && !t.done)
          () {
            t.progress = (t.progress + 1).clamp(0, t.target);
            if (t.done) gainedXp = t.xp;
            return t;
          }()
        else
          t
    ];
    state = state.copyWith(tasks: tasks, xp: state.xp + gainedXp);
  }
}
