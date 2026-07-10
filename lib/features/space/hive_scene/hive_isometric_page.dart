import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'hive_render_scene.dart';
import 'scene_models.dart';
import 'scene_provider.dart';

/// Space 主页：参考图风格的等距蜂巢场景，点击房间进入其内部。
class HiveIsometricPage extends ConsumerWidget {
  final VoidCallback? onSwitchToMap;

  const HiveIsometricPage({super.key, this.onSwitchToMap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sceneState = ref.watch(hiveSceneProvider);
    final enteredRoomId = sceneState.enteredRoomId;

    // 如果已进入房间，显示房间内部
    if (enteredRoomId != null) {
      final roomIndex = int.tryParse(enteredRoomId.replaceAll('room_', '')) ?? 0;
      final room = sceneState.rooms.isNotEmpty && roomIndex < sceneState.rooms.length
          ? sceneState.rooms[roomIndex]
          : null;
      if (room != null) {
        return _RoomInteriorShell(
          room: room,
          onBack: () => ref.read(hiveSceneProvider.notifier).exitRoom(),
        );
      }
    }

    return HiveRenderScene(
      rooms: sceneState.rooms,
      onEnterRoom: (i) => ref.read(hiveSceneProvider.notifier).enterRoom(i),
      onSwitchToMap: onSwitchToMap,
    );
  }
}

// =====================================================================
// 房间内部页面（外壳）
// =====================================================================

class _RoomInteriorShell extends StatelessWidget {
  final SceneRoom room;
  final VoidCallback onBack;

  const _RoomInteriorShell({required this.room, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0700),
      child: SafeArea(
        child: Column(
          children: [
            // 顶栏
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 18),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    room.type.label,
                    style: AppTextStyles.h2.copyWith(color: room.color),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: room.color.withOpacity(0.15),
                    ),
                    child: Text('${room.onlineCount}人在线',
                      style: TextStyle(color: room.color, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 房间内部内容
            Expanded(
              child: _buildRoomContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomContent() {
    switch (room.type) {
      case RoomType.game:
        return const _GameRoomContent();
      case RoomType.cinema:
        return const _CinemaRoomContent();
      case RoomType.drawGuess:
        return const _DrawGuessRoomContent();
      case RoomType.music:
        return const _MusicBarRoomContent();
    }
  }
}

// =====================================================================
// 🎮 游戏房
// =====================================================================

class _GameRoomContent extends StatelessWidget {
  const _GameRoomContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('网吧 / 游戏房', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('4 个游戏工位 · 3 个已占', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            // 游戏工位
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(4, (i) {
                final occupied = i < 3;
                return Container(
                  width: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0x20FFD84A),
                    border: Border.all(color: occupied ? const Color(0x60FFD84A) : const Color(0x30FFFFFF)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        occupied ? Icons.sports_esports : Icons.add_circle_outline,
                        color: occupied ? const Color(0xFFFFD84A) : Colors.white38,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        occupied ? '玩家${i+1}' : '空位',
                        style: TextStyle(color: occupied ? AppColors.textPrimary : AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // 快速匹配按钮
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('⚡'),
                label: const Text('快速匹配'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xAAFFD84A),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 🎬 电影院
// =====================================================================

class _CinemaRoomContent extends StatelessWidget {
  const _CinemaRoomContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 简易屏幕
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A237E).withOpacity(0.6), const Color(0xFF303F9F).withOpacity(0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: const Color(0x40FFFFFF)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎬', style: TextStyle(fontSize: 32)),
                    SizedBox(height: 4),
                    Text('正在播放：进击的巨人 最终季',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('在线观众：7 人', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            // 座位排
            ...List.generate(2, (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (col) {
                  final occupied = (row + col) % 3 != 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: occupied ? const Color(0x30FFD84A) : const Color(0x15FFFFFF),
                        border: Border.all(color: occupied ? const Color(0x60FFD84A) : const Color(0x20FFFFFF)),
                      ),
                      child: Icon(
                        occupied ? Icons.person : Icons.event_seat,
                        color: occupied ? const Color(0xFFFFD84A) : Colors.white38,
                        size: 20,
                      ),
                    ),
                  );
                }),
              ),
            )),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_circle, color: AppColors.neonCyan),
              label: const Text('加入观看', style: TextStyle(color: AppColors.neonCyan)),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 🎨 你画我猜
// =====================================================================

class _DrawGuessRoomContent extends StatelessWidget {
  const _DrawGuessRoomContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 画板
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.95),
                border: Border.all(color: const Color(0x30FFD84A)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🖌️', style: TextStyle(fontSize: 36, color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('当前画题：动物', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 猜词区域
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x15FFFFFF),
                border: Border.all(color: const Color(0x20FFFFFF)),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('猜词聊天', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  ..._mockChats.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: '${c.name}：', style: TextStyle(color: AppColors.neonYellow, fontSize: 11)),
                          TextSpan(text: c.msg, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  )),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0x20FFFFFF),
                          ),
                          child: const TextField(
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: '输入你的猜测...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.send, color: AppColors.neonYellow.withOpacity(0.7), size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _mockChats = [
  _Chat(name: '小明', msg: '猫！'),
  _Chat(name: '小红', msg: '小狗？'),
  _Chat(name: '阿强', msg: '🐱'),
];

class _Chat {
  final String name;
  final String msg;
  const _Chat({required this.name, required this.msg});
}

// =====================================================================
// 🎵 音乐吧
// =====================================================================

class _MusicBarRoomContent extends StatelessWidget {
  const _MusicBarRoomContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('音乐吧', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('正在播放 · 7人在听', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            // 当前曲目
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0x30F59E0B), Color(0x10F59E0B)],
                ),
                border: Border.all(color: const Color(0x40F59E0B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Blinding Lights', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('The Weeknd · 添加者：DJ小王', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.favorite, color: const Color(0xFFF43F5E).withOpacity(0.8), size: 18),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 歌单
            ..._mockPlaylist.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white38, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t, style: const TextStyle(color: Colors.white60, fontSize: 12))),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('🎶'),
                label: const Text('点歌'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xAAF59E0B),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _mockPlaylist = [
  'Starboy - The Weeknd',
  'Uptown Funk - Mark Ronson',
  'Dance Monkey - Tones and I',
  'Shape of You - Ed Sheeran',
];
