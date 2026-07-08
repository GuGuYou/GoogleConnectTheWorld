import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 推送通知设置模型（Block 5）
///
/// 所有推送严格遵守匿名原则：不包含任何用户身份信息。
/// 推送模板示例：
/// ✅ 「有 3 位同好在附近的留言板等你」
/// ✅ 「你的留言收到了 5 次共鸣」
/// ❌ 「张三 回复了你的留言」
class NotificationSettings {
  /// 留言共鸣提醒
  final bool likeAlert;

  /// 留言回复提醒
  final bool replyAlert;

  /// 留言板未读提醒
  final bool unreadAlert;

  /// 附近空间聚众提醒
  final bool nearbyAlert;

  const NotificationSettings({
    this.likeAlert = true,
    this.replyAlert = true,
    this.unreadAlert = true,
    this.nearbyAlert = false,
  });

  NotificationSettings copyWith({
    bool? likeAlert,
    bool? replyAlert,
    bool? unreadAlert,
    bool? nearbyAlert,
  }) {
    return NotificationSettings(
      likeAlert: likeAlert ?? this.likeAlert,
      replyAlert: replyAlert ?? this.replyAlert,
      unreadAlert: unreadAlert ?? this.unreadAlert,
      nearbyAlert: nearbyAlert ?? this.nearbyAlert,
    );
  }

  /// 是否有任何通知开启
  bool get hasAnyEnabled => likeAlert || replyAlert || unreadAlert || nearbyAlert;
}

/// 通知设置 Provider
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
        NotificationSettingsNotifier.new);

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() => const NotificationSettings();

  void toggleLike() =>
      state = state.copyWith(likeAlert: !state.likeAlert);

  void toggleReply() =>
      state = state.copyWith(replyAlert: !state.replyAlert);

  void toggleUnread() =>
      state = state.copyWith(unreadAlert: !state.unreadAlert);

  void toggleNearby() =>
      state = state.copyWith(nearbyAlert: !state.nearbyAlert);
}
