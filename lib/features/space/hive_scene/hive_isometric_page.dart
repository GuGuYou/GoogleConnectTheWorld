import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'hive_render_scene.dart';
import 'octagon_kit.dart';
import 'room_interiors.dart';
import 'scene_models.dart';
import 'scene_provider.dart';

/// Space 主页：参考图风格的等距蜂巢场景，点击房间进入其内部。
/// 四个分区的内饰按《多人共玩界面设计方案》实现（room_interiors.dart）：
/// 游戏房=4a 等位圆桌 / 电影院=2c 观影房 / 音乐吧=2b 一起听 /
/// 附近聊天=2d 存在感轨道。
class HiveIsometricPage extends ConsumerWidget {
  final VoidCallback? onSwitchToMap;

  const HiveIsometricPage({super.key, this.onSwitchToMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneState = ref.watch(hiveSceneProvider);
    final enteredRoomId = sceneState.enteredRoomId;

    // 附近聊天（特殊房间，无 rooms 下标）→ 2d 存在感轨道
    if (enteredRoomId == HiveSceneNotifier.globalChatRoomId) {
      final online =
          sceneState.rooms.fold<int>(0, (s, r) => s + r.onlineCount);
      return _RoomShell(
        title: '📍 ${ref.tr('space_local_chat')}',
        onlineCount: online,
        onBack: () => ref.read(hiveSceneProvider.notifier).exitRoom(),
        child: const HiveOrbitRoom(),
      );
    }

    // 已进入普通房间 → 对应内饰
    if (enteredRoomId != null) {
      final roomIndex =
          int.tryParse(enteredRoomId.replaceAll('room_', '')) ?? 0;
      final room =
          sceneState.rooms.isNotEmpty && roomIndex < sceneState.rooms.length
              ? sceneState.rooms[roomIndex]
              : null;
      if (room != null) {
        return _RoomShell(
          title:
              '${_roomEmoji[room.type]} ${ref.tr(_roomTitleKey(room.type))}',
          onlineCount: room.onlineCount,
          onBack: () => ref.read(hiveSceneProvider.notifier).exitRoom(),
          child: _roomContent(room.type),
        );
      }
    }

    final notifier = ref.read(hiveSceneProvider.notifier);
    return HiveRenderScene(
      rooms: sceneState.rooms,
      onRoomTap: notifier.enterRoom,
      onGlobalChatTap: notifier.enterGlobalChat,
    );
  }

  Widget _roomContent(RoomType type) {
    switch (type) {
      case RoomType.game:
        return const GameWaitingRoom();
      case RoomType.cinema:
        return const MovieTheaterRoom();
      case RoomType.drawGuess:
        return const DrawGuessRoom();
      case RoomType.music:
        return const MusicBarRoom();
    }
  }
}

/// 房间类型 → 场景/内饰共用的 i18n 标题 key。
String _roomTitleKey(RoomType t) => switch (t) {
      RoomType.game => 'space_room_game',
      RoomType.cinema => 'space_room_movie',
      RoomType.drawGuess => 'space_room_draw',
      RoomType.music => 'space_room_music',
    };

const _roomEmoji = <RoomType, String>{
  RoomType.game: '🎮',
  RoomType.cinema: '🎬',
  RoomType.drawGuess: '🎨',
  RoomType.music: '🎵',
};

// =====================================================================
// 房间外壳：黑金星空底 + 返回栏 + 渐变金标题 + 在线数徽标
// =====================================================================

class _RoomShell extends ConsumerWidget {
  final String title;
  final int onlineCount;
  final VoidCallback onBack;
  final Widget child;

  const _RoomShell({
    required this.title,
    required this.onlineCount,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: GoldTokens.bg,
      child: SafeArea(
        child: Column(
          children: [
            // 顶栏
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          GoldTokens.goldFill.createShader(bounds),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: GoldTokens.brightGold.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      '$onlineCount ${ref.tr('space_online_suffix')}',
                      style: const TextStyle(
                          color: GoldTokens.brightGold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 房间内容
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
