import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_text_styles.dart';
import 'octagon_kit.dart';

/// ===========================================================================
/// 蜂巢场景四个分区的高保真界面（黑金奢华 · 蜂巢八边形）
/// 复刻 `多人共玩界面设计方案`：4a 等位圆桌 / 2c 观影房 / 2b 音乐吧 / 你画我猜
/// 每个 Room 都嵌入 `_RoomInteriorShell` 的内容区（外层已提供返回栏 + 在线数）。
/// ===========================================================================

/// 星尘背景（近黑 + 金色微粒），铺在每个房间底部。
class _Starfield extends StatelessWidget {
  const _Starfield();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(painter: _StarfieldPainter()),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final p = Paint();
    for (var i = 0; i < 46; i++) {
      final o = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      p.color = const Color(0xFFF6DE9C)
          .withValues(alpha: 0.12 + rnd.nextDouble() * 0.45);
      canvas.drawCircle(o, 0.5 + rnd.nextDouble() * 1.2, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===========================================================================
// 4a — 游戏等位圆桌
// ===========================================================================

class GameWaitingRoom extends ConsumerStatefulWidget {
  const GameWaitingRoom({super.key});

  @override
  ConsumerState<GameWaitingRoom> createState() => _GameWaitingRoomState();
}

class _GameWaitingRoomState extends ConsumerState<GameWaitingRoom> {
  bool _joined = false;

  // 6 个座位：名字、是否游戏中、是否为"你"
  static const _seats = <(String, bool, bool)>[
    ('俊', true, false),
    ('柚', true, false),
    ('波', true, false),
    ('你', false, true),
    ('林', false, false),
    ('鱼', false, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _Starfield(),
        Column(
          children: [
            // 副标题
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ref.tr('room_game_sub'),
                  style: AppTextStyles.tt(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ),
            // 圆桌区
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = math.min(c.maxWidth, c.maxHeight);
                  final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
                  final ringR = side * 0.40;
                  final seat = (side * 0.16).clamp(44.0, 52.0);
                  final cardSize = (side * 0.42).clamp(104.0, 128.0);

                  final children = <Widget>[
                    // 虚线圆环
                    Positioned(
                      left: center.dx - ringR,
                      top: center.dy - ringR,
                      child: CustomPaint(
                        size: Size(ringR * 2, ringR * 2),
                        painter: _DashedRingPainter(),
                      ),
                    ),
                    // 中心状态卡（八边形）
                    Positioned(
                      left: center.dx - cardSize / 2,
                      top: center.dy - cardSize / 2,
                      child: OctagonBox(
                        size: cardSize,
                        filled: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('英雄联盟',
                                style: AppTextStyles.tt(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: GoldTokens.brightGold)),
                            const SizedBox(height: 4),
                            Text('23:41',
                                style: AppTextStyles.tt(
                                    size: 18,
                                    weight: FontWeight.w700,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('第 2 局 · ${ref.tr('room_game_live')}',
                                style: AppTextStyles.tt(
                                    size: 9,
                                    weight: FontWeight.w600,
                                    color: const Color(0x99F6DE9C))),
                          ],
                        ),
                      ),
                    ),
                  ];

                  // 6 个座位环绕
                  for (var i = 0; i < _seats.length; i++) {
                    final (name, inGame, isMe) = _seats[i];
                    final angle = -math.pi / 2 + i * (math.pi / 3);
                    final sx = center.dx + ringR * math.cos(angle);
                    final sy = center.dy + ringR * math.sin(angle);
                    children.add(Positioned(
                      left: sx - seat / 2,
                      top: sy - seat / 2 - 8,
                      child: _SeatCell(
                        name: name,
                        inGame: inGame,
                        isMe: isMe,
                        joined: _joined,
                        size: seat,
                      ),
                    ));
                  }

                  return Stack(clipBehavior: Clip.none, children: children);
                },
              ),
            ),
            // 底部操作区
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  GoldPill(
                    label: _joined
                        ? '${ref.tr('room_game_joined')} ✓'
                        : '${ref.tr('room_game_join')} ✋',
                    outlined: _joined,
                    onTap: () => setState(() => _joined = !_joined),
                  ),
                  const SizedBox(height: 9),
                  GoldPill(
                    label: ref.tr('room_game_mic'),
                    emoji: '🎙️',
                    outlined: true,
                    height: 44,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SeatCell extends ConsumerWidget {
  final String name;
  final bool inGame;
  final bool isMe;
  final bool joined;
  final double size;
  const _SeatCell({
    required this.name,
    required this.inGame,
    required this.isMe,
    required this.joined,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = OctagonAvatar(
      initial: name,
      size: size,
      active: inGame,
      glow: inGame,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + 12,
          height: size + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isMe) RippleRing(size: size + 10),
              avatar,
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (inGame)
          StatusPill(text: ref.tr('room_game_ingame'), active: true)
        else
          StatusPill(
            text: isMe && joined
                ? ref.tr('room_game_queued')
                : ref.tr('room_game_waiting'),
            active: isMe && joined,
          ),
      ],
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x40F6DE9C);
    const dashCount = 60;
    for (var i = 0; i < dashCount; i++) {
      final a0 = (i / dashCount) * 2 * math.pi;
      final a1 = a0 + (2 * math.pi / dashCount) * 0.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        a0,
        a1 - a0,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===========================================================================
// 2c — 观影房 Movie Theater
// ===========================================================================

class MovieTheaterRoom extends ConsumerWidget {
  const MovieTheaterRoom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const _Starfield(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          child: Column(
            children: [
              // 金框剧幕
              LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                const h = 260.0;
                return SizedBox(
                  width: w,
                  height: h,
                  child: ClipPath(
                    clipper: const _WideOctagonClipper(),
                    child: Container(
                      decoration: const BoxDecoration(gradient: GoldTokens.goldFill),
                      padding: const EdgeInsets.all(1.5),
                      child: ClipPath(
                        clipper: const _WideOctagonClipper(),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF17110A), Color(0xFF0F0B06)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text('[ 影片画面 · 1080P ]',
                                  style: AppTextStyles.tt(
                                      size: 10,
                                      weight: FontWeight.w700,
                                      color: const Color(0x66F6DE9C),
                                      letterSpacing: 1)),
                            ),
                            // 弹幕
                            Positioned(
                              top: 34,
                              left: w,
                              child: Danmaku(
                                travel: w + 200,
                                duration: const Duration(seconds: 8),
                                child: const DanmakuCapsule(text: '这段太好哭了 😭'),
                              ),
                            ),
                            Positioned(
                              top: 92,
                              left: w,
                              child: Danmaku(
                                travel: w + 200,
                                duration: const Duration(seconds: 10),
                                delay: const Duration(milliseconds: 2500),
                                child: const DanmakuCapsule(
                                    text: '名场面来了！！', filled: false),
                              ),
                            ),
                            Positioned(
                              top: 150,
                              left: w,
                              child: Danmaku(
                                travel: w + 200,
                                duration: const Duration(seconds: 9),
                                delay: const Duration(seconds: 5),
                                child: const DanmakuCapsule(
                                    text: '音乐一起鸡皮疙瘩', filled: false),
                              ),
                            ),
                            // 底部升起表情
                            Positioned(
                              bottom: 16,
                              left: w * 0.18,
                              child: const RiseFadeEmoji(emoji: '😂', fontSize: 20),
                            ),
                            Positioned(
                              bottom: 16,
                              left: w * 0.46,
                              child: const RiseFadeEmoji(
                                  emoji: '✨',
                                  fontSize: 18,
                                  delay: Duration(milliseconds: 1400)),
                            ),
                            Positioned(
                              bottom: 16,
                              left: w * 0.74,
                              child: const RiseFadeEmoji(
                                  emoji: '🔥',
                                  fontSize: 20,
                                  delay: Duration(milliseconds: 700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              // 进度条
              const _MovieProgress(),
              const SizedBox(height: 18),
              // 人脸小格
              _FaceStrip(),
              const SizedBox(height: 16),
              // 底部操作栏
              Row(
                children: [
                  Expanded(
                    child: GoldPill(
                      label: ref.tr('room_cinema_send'),
                      emoji: '💬',
                      outlined: true,
                      height: 44,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 9),
                  _RoundIconBtn(emoji: '😍', filled: false, onTap: () {}),
                  const SizedBox(width: 9),
                  _RoundIconBtn(emoji: '🎤', filled: true, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MovieProgress extends StatelessWidget {
  const _MovieProgress();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            const frac = 0.36;
            return SizedBox(
              height: 12,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0x2EF6DE9C),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 3,
                    width: w * frac,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [GoldTokens.brightGold, GoldTokens.deepGold]),
                      borderRadius: BorderRadius.all(Radius.circular(3)),
                    ),
                  ),
                  Positioned(
                    left: w * frac - 5.5,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        color: GoldTokens.brightGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0xE6E8B54D), blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('00:42:15',
                  style: AppTextStyles.tt(
                      size: 10,
                      weight: FontWeight.w600,
                      color: const Color(0x8CF6DE9C))),
              Text('01:58:00',
                  style: AppTextStyles.tt(
                      size: 10,
                      weight: FontWeight.w600,
                      color: const Color(0x8CF6DE9C))),
            ],
          ),
        ],
      ),
    );
  }
}

class _FaceStrip extends StatelessWidget {
  // 名字 / 是否说话中；末格为 +2
  static const _faces = <(String, bool)>[
    ('俊', true),
    ('鱼', false),
    ('🙈', false),
    ('糖', false),
    ('林', false),
    ('+2', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final (label, speaking) in _faces)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _OctFace(label: label, speaking: speaking),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 自适应填充的八边形人脸格（实心=说话中 / 描边=在场）。
class _OctFace extends StatelessWidget {
  final String label;
  final bool speaking;
  const _OctFace({required this.label, required this.speaking});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.tt(
        size: label.runes.length > 1 ? 11 : 13,
        weight: FontWeight.w700,
        color: speaking ? GoldTokens.inkOnGold : GoldTokens.midGold,
      ),
    );
    return ClipPath(
      clipper: const OctagonClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: speaking ? GoldTokens.goldFill : null,
          color: speaking ? null : const Color(0x80F6DE9C),
        ),
        alignment: Alignment.center,
        child: speaking
            ? text
            : Padding(
                padding: const EdgeInsets.all(1.5),
                child: ClipPath(
                  clipper: const OctagonClipper(),
                  child: Container(
                    color: GoldTokens.cardDark,
                    alignment: Alignment.center,
                    child: text,
                  ),
                ),
              ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final String emoji;
  final bool filled;
  final VoidCallback onTap;
  const _RoundIconBtn(
      {required this.emoji, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? GoldTokens.goldFill : null,
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: const Color(0x66F6DE9C)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 17)),
      ),
    );
  }
}

// ===========================================================================
// 2b — 一起听 Music Bar
// ===========================================================================

class MusicBarRoom extends ConsumerWidget {
  const MusicBarRoom({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        const _Starfield(),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
          child: Column(
            children: [
              // LIVE 徽标
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [GoldTokens.brightGold, GoldTokens.midGold]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('LIVE · 7',
                        style: AppTextStyles.tt(
                            size: 10,
                            weight: FontWeight.w700,
                            color: GoldTokens.inkOnGold)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 八边形专辑封面（浮动）
              Floaty(
                child: LayoutBuilder(builder: (context, _) {
                  const s = 200.0;
                  return SizedBox(
                    width: s,
                    height: s,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 光晕
                        Container(
                          width: s * 0.9,
                          height: s * 0.9,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0x59E8B54D), blurRadius: 40),
                            ],
                          ),
                        ),
                        OctagonBox(
                          size: s,
                          filled: false,
                          borderWidth: 1.5,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text('[ 专辑封面 ]',
                                  style: AppTextStyles.tt(
                                      size: 9,
                                      weight: FontWeight.w700,
                                      color: const Color(0x80F6DE9C))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              Text('夜航 Night Flight',
                  style: AppTextStyles.tt(
                      size: 19, weight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 5),
              Text('The Lantern',
                  style: AppTextStyles.tt(
                      size: 12,
                      weight: FontWeight.w500,
                      color: const Color(0xA6F6DE9C))),
              const SizedBox(height: 18),
              // 律动条
              const SizedBox(
                height: 46,
                child: Center(child: EqualizerBars(count: 12)),
              ),
              const SizedBox(height: 8),
              // 底部：听众 + 反应按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Row(
                  children: [
                    const _ListenerStack(initials: ['俊', '鱼', '柚', '糖'], extra: 3),
                    const SizedBox(width: 12),
                    Text('7 ${ref.tr('room_music_count')}',
                        style: AppTextStyles.tt(
                            size: 12,
                            weight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6))),
                    const Spacer(),
                    // 🔥 反应按钮
                    SizedBox(
                      width: 44,
                      height: 64,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          const Positioned(
                            bottom: 30,
                            left: 4,
                            child: RiseFadeEmoji(emoji: '✨', fontSize: 15),
                          ),
                          const Positioned(
                            bottom: 30,
                            right: 2,
                            child: RiseFadeEmoji(
                                emoji: '🔥',
                                fontSize: 14,
                                delay: Duration(milliseconds: 1100)),
                          ),
                          Positioned(
                            bottom: 0,
                            child: OctagonBox(
                              size: 44,
                              filled: true,
                              child: const Text('🔥',
                                  style: TextStyle(fontSize: 19)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 叠放的圆形听众头像。
class _ListenerStack extends StatelessWidget {
  final List<String> initials;
  final int extra;
  const _ListenerStack({required this.initials, this.extra = 0});

  @override
  Widget build(BuildContext context) {
    const d = 36.0;
    const overlap = 12.0;
    final items = <Widget>[];
    for (var i = 0; i < initials.length; i++) {
      items.add(Positioned(
        left: i * (d - overlap),
        child: _circleAvatar(initials[i], first: i == 0),
      ));
    }
    if (extra > 0) {
      items.add(Positioned(
        left: initials.length * (d - overlap),
        child: _circleAvatar('+$extra', first: false),
      ));
    }
    final width = (initials.length + (extra > 0 ? 1 : 0)) * (d - overlap) + overlap;
    return SizedBox(width: width, height: d, child: Stack(children: items));
  }

  Widget _circleAvatar(String text, {required bool first}) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: first ? GoldTokens.goldFill : null,
        color: first ? null : GoldTokens.cardDark,
        shape: BoxShape.circle,
        border: Border.all(color: GoldTokens.bg, width: 2),
        boxShadow: first
            ? null
            : const [BoxShadow(color: Color(0x8CF6DE9C), blurRadius: 0, spreadRadius: 1)],
      ),
      child: Text(text,
          style: AppTextStyles.tt(
              size: text.length > 1 ? 11 : 13,
              weight: FontWeight.w700,
              color: first ? GoldTokens.inkOnGold : GoldTokens.midGold)),
    );
  }
}

// ===========================================================================
// 你画我猜 —— 套用黑金八边形设计语言
// ===========================================================================

class DrawGuessRoom extends ConsumerStatefulWidget {
  const DrawGuessRoom({super.key});

  @override
  ConsumerState<DrawGuessRoom> createState() => _DrawGuessRoomState();
}

class _DrawGuessRoomState extends ConsumerState<DrawGuessRoom> {
  final _input = TextEditingController();

  static const _chats = <(String, String)>[
    ('小明', '猫！'),
    ('小红', '小狗？'),
    ('阿强', '🐱'),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _Starfield(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              // 画题徽标
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [GoldTokens.brightGold, GoldTokens.midGold]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(ref.tr('room_draw_topic'),
                      style: AppTextStyles.tt(
                          size: 11,
                          weight: FontWeight.w700,
                          color: GoldTokens.inkOnGold)),
                ),
              ),
              const SizedBox(height: 12),
              // 画板（八边形金框 + 浅底）
              Expanded(
                flex: 2,
                child: ClipPath(
                  clipper: const _WideOctagonClipper(),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: GoldTokens.goldFill),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipPath(
                      clipper: const _WideOctagonClipper(),
                      child: Container(
                        color: const Color(0xFFF3ECDD),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🖌️', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 6),
                            Text('阿俊 ${ref.tr('room_draw_current')}',
                                style: AppTextStyles.tt(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    color: const Color(0xFF8A7A55))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 猜词聊天
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: GoldTokens.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x33F6DE9C)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.tr('room_draw_chat'),
                          style: AppTextStyles.tt(
                              size: 11,
                              weight: FontWeight.w600,
                              color: const Color(0xA6F6DE9C))),
                      const SizedBox(height: 6),
                      ..._chats.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: RichText(
                              text: TextSpan(children: [
                                TextSpan(
                                    text: '${c.$1}：',
                                    style: AppTextStyles.tt(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: GoldTokens.brightGold)),
                                TextSpan(
                                    text: c.$2,
                                    style: AppTextStyles.tt(
                                        size: 11,
                                        weight: FontWeight.w500,
                                        color: Colors.white70)),
                              ]),
                            ),
                          )),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 36,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: const Color(0x14FFFFFF),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: TextField(
                                controller: _input,
                                style: AppTextStyles.tt(
                                    size: 12,
                                    weight: FontWeight.w500,
                                    color: Colors.white),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: ref.tr('room_draw_hint'),
                                  hintStyle: AppTextStyles.tt(
                                      size: 12,
                                      weight: FontWeight.w500,
                                      color: Colors.white38),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.send,
                              color: GoldTokens.brightGold.withValues(alpha: 0.8),
                              size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// 2d — 存在感轨道 Hive Orbit（附近聊天分区：谁在场、谁在说话）
// ===========================================================================

class HiveOrbitRoom extends ConsumerStatefulWidget {
  const HiveOrbitRoom({super.key});

  @override
  ConsumerState<HiveOrbitRoom> createState() => _HiveOrbitRoomState();
}

class _HiveOrbitRoomState extends ConsumerState<HiveOrbitRoom>
    with TickerProviderStateMixin {
  // 内圈 26s 正转，外圈 40s 反转（设计稿 spin / reverse）
  late final AnimationController _inner = AnimationController(
      vsync: this, duration: const Duration(seconds: 26))
    ..repeat();
  late final AnimationController _outer = AnimationController(
      vsync: this, duration: const Duration(seconds: 40))
    ..repeat();

  static const _members = ['俊', '柚', '波', '鱼', '糖', '林'];
  int _speaker = 0;
  Timer? _speakerTimer;

  @override
  void initState() {
    super.initState();
    // 演示：每 4s 轮换"正在说话"的人（真实实现应接语音活动状态）
    _speakerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() => _speaker = (_speaker + 1) % _members.length);
      }
    });
  }

  @override
  void dispose() {
    _speakerTimer?.cancel();
    _inner.dispose();
    _outer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _Starfield(),
        Column(
          children: [
            // 副标题：N 人在线 · 谁正在说话
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_members.length + 1} ${ref.tr('space_online_suffix')}'
                  ' · ${_members[_speaker]} ${ref.tr('room_orbit_speaking')}',
                  style: AppTextStyles.tt(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ),
            ),
            // 轨道区
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = math.min(c.maxWidth, c.maxHeight);
                  final center = Offset(c.maxWidth / 2, c.maxHeight / 2);
                  final rIn = side * 0.27;
                  final rOut = side * 0.44;

                  return AnimatedBuilder(
                    animation: Listenable.merge([_inner, _outer]),
                    builder: (_, __) {
                      final children = <Widget>[
                        // 两个同心虚线环
                        Positioned(
                          left: center.dx - rIn,
                          top: center.dy - rIn,
                          child: CustomPaint(
                            size: Size(rIn * 2, rIn * 2),
                            painter: _DashedRingPainter(),
                          ),
                        ),
                        Positioned(
                          left: center.dx - rOut,
                          top: center.dy - rOut,
                          child: CustomPaint(
                            size: Size(rOut * 2, rOut * 2),
                            painter: _DashedRingPainter(),
                          ),
                        ),
                        // 中心「客厅」节点（呼吸）
                        Positioned(
                          left: center.dx - 38,
                          top: center.dy - 38,
                          child: Breathe(
                            child: OctagonBox(
                              size: 76,
                              filled: true,
                              child: Text(
                                ref.tr('room_orbit_center'),
                                style: AppTextStyles.tt(
                                    size: 12,
                                    weight: FontWeight.w700,
                                    color: GoldTokens.inkOnGold),
                              ),
                            ),
                          ),
                        ),
                      ];

                      // 内圈 3 人公转
                      for (var i = 0; i < 3; i++) {
                        final angle = -math.pi / 2 +
                            i * (2 * math.pi / 3) +
                            2 * math.pi * _inner.value;
                        final p = Offset(center.dx + rIn * math.cos(angle),
                            center.dy + rIn * math.sin(angle));
                        children.add(_orbitAvatar(p, i, 48));
                      }
                      // 外圈 3 人反向公转
                      for (var i = 3; i < 6; i++) {
                        final angle = math.pi / 6 +
                            (i - 3) * (2 * math.pi / 3) -
                            2 * math.pi * _outer.value;
                        final p = Offset(center.dx + rOut * math.cos(angle),
                            center.dy + rOut * math.sin(angle));
                        children.add(_orbitAvatar(p, i, 44));
                      }

                      return Stack(clipBehavior: Clip.none, children: children);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }

  /// 轨道头像：位置随公转更新（自身不旋转，文字始终水平）。
  Widget _orbitAvatar(Offset p, int index, double size) {
    final speaking = index == _speaker;
    return Positioned(
      left: p.dx - size / 2,
      top: p.dy - size / 2,
      child: OctagonAvatar(
        initial: _members[index],
        size: size,
        active: speaking,
        glow: speaking,
        fontSize: size * 0.34,
      ),
    );
  }
}

// ===========================================================================
// 宽八边形裁剪（剧幕/画板：14/86 切角）
// ===========================================================================

class _WideOctagonClipper extends CustomClipper<Path> {
  const _WideOctagonClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(0.12 * w, 0)
      ..lineTo(0.88 * w, 0)
      ..lineTo(w, 0.12 * h)
      ..lineTo(w, 0.88 * h)
      ..lineTo(0.88 * w, h)
      ..lineTo(0.12 * w, h)
      ..lineTo(0, 0.88 * h)
      ..lineTo(0, 0.12 * h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
