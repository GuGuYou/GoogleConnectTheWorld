import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/data/repositories.dart';
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

    // 世界频道（特殊房间，无 rooms 下标）
    if (enteredRoomId == HiveSceneNotifier.globalChatRoomId) {
      return _GlobalChatRoom(
        onBack: () => ref.read(hiveSceneProvider.notifier).exitRoom(),
      );
    }

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

    final notifier = ref.read(hiveSceneProvider.notifier);
    return HiveRenderScene(
      rooms: sceneState.rooms,
      onRoomTap: notifier.enterRoom,
      onGlobalChatTap: notifier.enterGlobalChat,
    );
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
// 房间内部页面（外壳）
// =====================================================================

class _RoomInteriorShell extends ConsumerWidget {
  final SceneRoom room;
  final VoidCallback onBack;

  const _RoomInteriorShell({required this.room, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    '${_roomEmoji[room.type]} ${ref.tr(_roomTitleKey(room.type))}',
                    style: AppTextStyles.h2.copyWith(color: room.color),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: room.color.withOpacity(0.15),
                    ),
                    child: Text(
                      '${room.onlineCount} ${ref.tr('space_online_suffix')}',
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

class _GameRoomContent extends ConsumerWidget {
  const _GameRoomContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎮', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(ref.tr('space_room_game'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(ref.tr('room_game_stations'), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                        occupied
                            ? '${ref.tr('room_game_player')}${i + 1}'
                            : ref.tr('room_game_empty'),
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
                label: Text(ref.tr('room_game_match')),
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

class _CinemaRoomContent extends ConsumerWidget {
  const _CinemaRoomContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎬', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(ref.tr('room_cinema_playing'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(ref.tr('room_cinema_viewers'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
              label: Text(ref.tr('room_cinema_join'),
                  style: const TextStyle(color: AppColors.neonCyan)),
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

class _DrawGuessRoomContent extends ConsumerWidget {
  const _DrawGuessRoomContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Text(ref.tr('room_draw_topic'), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
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
                  Text(ref.tr('room_draw_chat'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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
                          child: TextField(
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: ref.tr('room_draw_hint'),
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
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

class _MusicBarRoomContent extends ConsumerWidget {
  const _MusicBarRoomContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎵', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(ref.tr('space_room_music'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(ref.tr('room_music_listening'), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                label: Text(ref.tr('room_music_request')),
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

// =====================================================================
// 🌍 世界频道（Global Chat）
// =====================================================================

class _GlobalChatRoom extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _GlobalChatRoom({required this.onBack});

  @override
  ConsumerState<_GlobalChatRoom> createState() => _GlobalChatRoomState();
}

class _GlobalChatRoomState extends ConsumerState<_GlobalChatRoom> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  /// (昵称, 内容, 是否自己)
  final List<(String, String, bool)> _messages = [];

  static const _greetings = [
    '你好呀！有人一起开黑吗？',
    'Bonjour! 🥖',
    'Hola, ¿qué tal?',
    'Konnichiwa 🌸',
    'Hello from the hive!',
    'Privet! ❄️',
    'Ciao a tutti ✨',
  ];

  static const _replies = [
    'Welcome! 🐝',
    '哈喽，欢迎来到蜂巢～',
    'Hola! 🎉',
    'Hi there 👋',
    '来啦来啦！',
  ];

  @override
  void initState() {
    super.initState();
    final users = ref.read(mockProvider).users;
    for (var i = 0; i < _greetings.length; i++) {
      _messages.add((users[i % users.length].nickname, _greetings[i], false));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final me = ref.read(mockProvider).me;
    setState(() => _messages.add((me.nickname, text, true)));
    _input.clear();
    _scrollToBottom();
    // 模拟世界频道里有人回应
    final users = ref.read(mockProvider).users;
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final i = _messages.length;
      setState(() => _messages.add((
            users[i % users.length].nickname,
            _replies[i % _replies.length],
            false,
          )));
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(hiveSceneProvider).rooms;
    final online = rooms.fold<int>(0, (s, r) => s + r.onlineCount);

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
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: AppColors.textSecondary, size: 18),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '🌍 ${ref.tr('space_global_chat')}',
                    style:
                        AppTextStyles.h2.copyWith(color: AppColors.neonYellow),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.neonYellow.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      '$online ${ref.tr('space_online_suffix')}',
                      style: const TextStyle(
                          color: AppColors.neonYellow, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Divider(height: 1, color: AppColors.divider),
            // 消息流
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (c, i) {
                  final (name, text, isMe) = _messages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(name,
                              style: AppTextStyles.tt(
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: AppColors.textMuted)),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFFE7A83A)
                                : const Color(0xFF161206),
                            borderRadius: BorderRadius.circular(14),
                            border: isMe
                                ? null
                                : Border.all(
                                    color: AppColors.neonYellow
                                        .withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            text,
                            style: AppTextStyles.tt(
                              size: 13,
                              weight: FontWeight.w500,
                              color: isMe
                                  ? AppColors.ctaText
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 输入栏
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: const BoxDecoration(
                color: Color(0xFF100C02),
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: ref.tr('chat_input_hint'),
                        hintStyle: AppTextStyles.caption,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: const BoxDecoration(
                          gradient: AppColors.pinkPurple,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.send,
                          size: 20, color: AppColors.ctaText),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
