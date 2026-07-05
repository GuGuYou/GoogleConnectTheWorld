import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

/// 网咖广场（参考 Gather / Marvis 的 2D 虚拟空间），全屏独立页面。
/// 内部渲染逻辑已抽成 [PlazaSceneView]，供"空间"Tab 的"场景"模式复用。
class PlazaPage extends ConsumerWidget {
  const PlazaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final nearby = ref.watch(nearbyUsersProvider).take(23).toList();
    final onlineCount = nearby.where((n) => n.user.online).length + 1;

    return Scaffold(
      backgroundColor: _PlazaSceneViewState._floorTop,
      body: Stack(
        children: [
          const Positioned.fill(child: PlazaSceneView()),

          // ---- 顶部沉浸渐隐遮罩 ----
          IgnorePointer(
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_PlazaSceneViewState._floorTop, _PlazaSceneViewState._floorTop.withValues(alpha: 0)],
                ),
              ),
            ),
          ),

          // ---- 顶部 HUD ----
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 16, 0),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) => const LinearGradient(
                          colors: [_PlazaSceneViewState._gridColor, AppColors.neonPink],
                        ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                        child: Text(
                          ref.tr('plaza_title'),
                          style: AppTextStyles.h2.copyWith(
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Text(
                        'GUGU NET CAFÉ',
                        style: AppTextStyles.caption.copyWith(
                          color: _PlazaSceneViewState._gridColor.withValues(alpha: 0.6),
                          letterSpacing: 3,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _OnlinePill(count: onlineCount, label: ref.tr('plaza_online')),
                ],
              ),
            ),
          ),

          // ---- 底部操作提示 ----
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.fromLTRB(0, 40, 0, 26),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_PlazaSceneViewState._floorTop.withValues(alpha: 0.92), _PlazaSceneViewState._floorTop.withValues(alpha: 0)],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _PlazaSceneViewState._gridColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app,
                          size: 15, color: _PlazaSceneViewState._gridColor),
                      const SizedBox(width: 7),
                      Text(
                        ref.tr('plaza_hint'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 网咖场景本体：可平移缩放的俯视斜角空间，一排排电脑工位坐着附近的同好，
/// 屏幕被各自正在玩的 IP 点亮，点击任意工位即可查看资料并打招呼。
/// 不含外层 Scaffold / HUD，可自由嵌入 [PlazaPage] 或"空间"Tab。
class PlazaSceneView extends ConsumerStatefulWidget {
  const PlazaSceneView({super.key});

  @override
  ConsumerState<PlazaSceneView> createState() => _PlazaSceneViewState();
}

class _PlazaSceneViewState extends ConsumerState<PlazaSceneView>
    with SingleTickerProviderStateMixin {
  // ---- 场景内深色霓虹色板（局部，不污染全局亮色主题） ----
  static const _floorTop = Color(0xFF0A0D1C);
  static const _floorMid = Color(0xFF111634);
  static const _floorBottom = Color(0xFF1A2147);
  static const _gridColor = Color(0xFF31E6FF);

  // 工位网格尺寸
  static const double _itemW = 150;
  static const double _itemH = 172;
  static const int _cols = 4;
  static const double _gap = 14;
  static const double _hPad = 20;
  static double get _sceneW => _cols * _itemW + (_cols - 1) * _gap + _hPad * 2;

  final _tc = TransformationController();
  late final AnimationController _glow;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    // 全场共享一个辉光控制器，驱动所有显示器的呼吸发光（性能友好）。
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final me = ref.watch(currentUserProvider);
    final nearby = ref.watch(nearbyUsersProvider).take(23).toList();

    return LayoutBuilder(
      builder: (context, c) {
        if (!_fitted) {
          // 首帧按宽度自适应缩放，让整间网咖刚好入画。
          final scale = (c.maxWidth / _sceneW).clamp(0.4, 1.0);
          _tc.value = Matrix4.identity()..scale(scale);
          _fitted = true;
        }
        return InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          minScale: 0.35,
          maxScale: 2.4,
          boundaryMargin: const EdgeInsets.all(260),
          child: _Scene(
            nearby: nearby,
            me: me,
            lang: lang,
            glow: _glow,
            onTapUser: (n) => _showUserSheet(context, ref, n, lang),
          ),
        );
      },
    );
  }

  // ---- 用户资料底部卡（网咖深色风格） ----
  void _showUserSheet(
      BuildContext context, WidgetRef ref, UserWithDistance n, String lang) {
    final u = n.user;
    final screen = u.tags.isNotEmpty ? u.tags.first.color : _gridColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF161B33), Color(0xFF0E1226)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: screen.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: screen.withValues(alpha: 0.25), blurRadius: 30),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarPlaceholder(
                    seed: u.avatarSeed,
                    label: u.nickname,
                    size: 58,
                    online: u.online,
                    glow: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                u.nickname,
                                style: AppTextStyles.title
                                    .copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (u.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  size: 16, color: _gridColor),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: u.online
                                    ? AppColors.neonGreen
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              u.status.label(lang),
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white60),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${ref.tr('match_rate')} ${n.matchRate}%',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.neonPink),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.sports_esports,
                      size: 15, color: _gridColor),
                  const SizedBox(width: 6),
                  Text(
                    ref.tr('plaza_playing'),
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in u.tags.take(4)) IpTagChip(tag: t, small: true),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: ref.tr('say_hi'),
                      icon: Icons.waving_hand,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/chat/conv_${u.id}');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeonButton(
                      label: ref.tr('plaza_visit_profile'),
                      icon: Icons.person,
                      secondary: true,
                      gradient: AppColors.cyanPurple,
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/user/${u.id}');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 整间网咖：地板透视网格 + 霓虹招牌 + 工位网格。
class _Scene extends StatelessWidget {
  final List<UserWithDistance> nearby;
  final UserProfile me;
  final String lang;
  final Listenable glow;
  final ValueChanged<UserWithDistance> onTapUser;

  const _Scene({
    required this.nearby,
    required this.me,
    required this.lang,
    required this.glow,
    required this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _PlazaSceneViewState._sceneW,
      child: Stack(
        children: [
          // 地板与环境
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _PlazaSceneViewState._floorTop,
                    _PlazaSceneViewState._floorMid,
                    _PlazaSceneViewState._floorBottom,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: CustomPaint(painter: _FloorPainter()),
            ),
          ),
          // 内容：招牌 + 工位
          Padding(
            padding: const EdgeInsets.fromLTRB(
                _PlazaSceneViewState._hPad, 96, _PlazaSceneViewState._hPad, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const _NeonSign(),
                const SizedBox(height: 22),
                Wrap(
                  spacing: _PlazaSceneViewState._gap,
                  runSpacing: _PlazaSceneViewState._gap,
                  alignment: WrapAlignment.center,
                  children: [
                    // 我的工位排在最前
                    SizedBox(
                      width: _PlazaSceneViewState._itemW,
                      height: _PlazaSceneViewState._itemH,
                      child: _Workstation(
                        user: me,
                        lang: lang,
                        glow: glow,
                        isMe: true,
                        onTap: () {},
                      ),
                    ),
                    for (final n in nearby)
                      SizedBox(
                        width: _PlazaSceneViewState._itemW,
                        height: _PlazaSceneViewState._itemH,
                        child: _Workstation(
                          user: n.user,
                          lang: lang,
                          glow: glow,
                          isMe: false,
                          onTap: () => onTapUser(n),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 单个电脑工位：显示器（屏幕被正在玩的 IP 点亮）+ 桌面键盘 + 坐着的用户 + 名牌。
class _Workstation extends StatelessWidget {
  final UserProfile user;
  final String lang;
  final Listenable glow;
  final bool isMe;
  final VoidCallback onTap;

  const _Workstation({
    required this.user,
    required this.lang,
    required this.glow,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = user.tags.isNotEmpty ? user.tags.first : null;
    final screen = tag?.color ?? _PlazaSceneViewState._gridColor;
    final lit = user.online; // 在线 = 屏幕点亮 = 正在玩

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 名牌
          Positioned(
            top: 0,
            child: _NameTag(
              name: isMe ? 'YOU' : user.nickname,
              online: user.online,
              highlight: isMe,
            ),
          ),

          // 桌面（深色面板 + 顶部高光）
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A4366), Color(0xFF222A4A)],
                ),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          // 键盘
          Positioned(
            top: 78,
            child: Container(
              width: 56,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF161B30),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
          ),

          // 显示器
          Positioned(
            top: 26,
            child: _Monitor(color: screen, lit: lit, glow: glow),
          ),

          // 坐着的人（头像 + 椅背）
          Positioned(
            top: 104,
            child: _SeatedUser(user: user, accent: screen, isMe: isMe),
          ),
        ],
      ),
    );
  }
}

/// 显示器：发光屏 + 扫描线 + 呼吸辉光，离线时熄屏。
class _Monitor extends StatelessWidget {
  final Color color;
  final bool lit;
  final Listenable glow;
  const _Monitor({required this.color, required this.lit, required this.glow});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: glow,
          builder: (context, _) {
            final t = (glow as AnimationController).value;
            final intensity = lit ? (0.45 + t * 0.55) : 0.0;
            return Container(
              width: 64,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF05060E),
                border: Border.all(
                  color: lit
                      ? color.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
                boxShadow: lit
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.55 * intensity),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: CustomPaint(
                  painter: _ScreenPainter(color: color, intensity: intensity),
                ),
              ),
            );
          },
        ),
        // 支架
        Container(width: 6, height: 6, color: const Color(0xFF2A3152)),
        // 底座
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFF2A3152),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

/// 屏幕画面：渐变底 + 扫描线 + 简易"游戏 UI"亮条。
class _ScreenPainter extends CustomPainter {
  final Color color;
  final double intensity;
  _ScreenPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (intensity <= 0) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF0A0C16));
      return;
    }
    // 渐变底
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.85 * intensity),
          color.withValues(alpha: 0.25 * intensity),
          const Color(0xFF06070F),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // 高光斑
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.35 * intensity), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.32, size.height * 0.32),
          radius: size.width * 0.5));
    canvas.drawRect(rect, glowPaint);

    // 扫描线
    final line = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }

    // 底部"任务栏"亮条
    final bar = Paint()..color = Colors.white.withValues(alpha: 0.5 * intensity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, size.height - 7, size.width * 0.5, 2.5),
        const Radius.circular(1),
      ),
      bar,
    );
  }

  @override
  bool shouldRepaint(_ScreenPainter old) =>
      old.intensity != intensity || old.color != color;
}

/// 坐在椅子上的用户：头像 + 椅背，"我"带霓虹高亮环。
class _SeatedUser extends StatelessWidget {
  final UserProfile user;
  final Color accent;
  final bool isMe;
  const _SeatedUser(
      {required this.user, required this.accent, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 62,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // 椅背
          Positioned(
            top: 22,
            child: Container(
              width: 50,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isMe
                      ? [accent.withValues(alpha: 0.9), accent.withValues(alpha: 0.4)]
                      : const [Color(0xFF2C3358), Color(0xFF1A2038)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                  bottom: Radius.circular(8),
                ),
                border: Border.all(
                  color: isMe
                      ? accent
                      : Colors.white.withValues(alpha: 0.08),
                  width: isMe ? 1.5 : 1,
                ),
              ),
            ),
          ),
          // 头像（坐着的人）
          Positioned(
            top: 0,
            child: AvatarPlaceholder(
              seed: user.avatarSeed,
              label: user.nickname,
              size: 38,
              online: user.online,
              glow: isMe,
            ),
          ),
        ],
      ),
    );
  }
}

/// 工位名牌
class _NameTag extends StatelessWidget {
  final String name;
  final bool online;
  final bool highlight;
  const _NameTag(
      {required this.name, required this.online, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.neonPink.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppColors.neonPink
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? AppColors.neonGreen : AppColors.textMuted,
              boxShadow: online
                  ? [
                      BoxShadow(
                          color: AppColors.neonGreen.withValues(alpha: 0.8),
                          blurRadius: 5)
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 网咖顶部霓虹招牌
class _NeonSign extends StatelessWidget {
  const _NeonSign();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PlazaSceneViewState._gridColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
              color: _PlazaSceneViewState._gridColor.withValues(alpha: 0.35),
              blurRadius: 24),
          BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.2), blurRadius: 30),
        ],
        gradient: LinearGradient(
          colors: [
            _PlazaSceneViewState._gridColor.withValues(alpha: 0.10),
            AppColors.neonPink.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_esports,
              color: _PlazaSceneViewState._gridColor, size: 20),
          const SizedBox(width: 10),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => const LinearGradient(
              colors: [_PlazaSceneViewState._gridColor, AppColors.neonPink],
            ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
            child: Text(
              'GUGU · NET CAFÉ',
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 地板透视网格：纵线汇聚 + 横线，营造赛博空间纵深。
class _FloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _PlazaSceneViewState._gridColor.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final w = size.width;
    final h = size.height;
    // 消失点（顶部中心偏上）
    final vp = Offset(w / 2, -h * 0.35);

    // 纵向汇聚线
    const lines = 14;
    for (int i = 0; i <= lines; i++) {
      final x = w * i / lines;
      canvas.drawLine(Offset(x, h), vp, paint);
    }

    // 横向线：间距随高度指数变化，越往下越疏
    final hPaint = Paint()
      ..color = _PlazaSceneViewState._gridColor.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 1; i <= 20; i++) {
      final f = i / 20;
      final y = h * (1 - math.pow(1 - f, 2.2)).toDouble();
      canvas.drawLine(Offset(0, y), Offset(w, y), hPaint);
    }
  }

  @override
  bool shouldRepaint(_FloorPainter oldDelegate) => false;
}

// ---- HUD 小组件 ----

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  final int count;
  final String label;
  const _OnlinePill({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonGreen,
              boxShadow: [
                BoxShadow(
                    color: AppColors.neonGreen.withValues(alpha: 0.8), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$count $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
