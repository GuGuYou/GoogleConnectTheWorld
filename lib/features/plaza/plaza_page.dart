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

/// GoBuzz 蜂巢（虚拟社区场景），全屏独立页面。
///
/// 整张场景被设计成"蜂巢"：一格格六边形蜂室围绕中心的"我"展开，
/// 每格住着一位附近的同好，离线则蜂室变暗。整体配色采用蜂蜜/琥珀
/// 色系（暖金、棕褐、深色背景），呼应 App 主形象「GoBuzz 小蜜蜂」。
///
/// 内部渲染逻辑已抽成 [PlazaSceneView]，供"空间"Tab 的"场景"模式复用。
class PlazaPage extends ConsumerWidget {
  const PlazaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(nearbyUsersProvider).take(24).toList();
    final onlineCount = nearby.where((n) => n.user.online).length + 1;

    return Scaffold(
      backgroundColor: _PlazaSceneViewState._bgTop,
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
                  colors: [_PlazaSceneViewState._bgTop, _PlazaSceneViewState._bgTop.withValues(alpha: 0)],
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
                          colors: [_PlazaSceneViewState._honey, _PlazaSceneViewState._honeyDeep],
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
                        'HIVE · HONEYCOMB',
                        style: AppTextStyles.caption.copyWith(
                          color: _PlazaSceneViewState._honey.withValues(alpha: 0.55),
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
                    colors: [_PlazaSceneViewState._bgTop.withValues(alpha: 0.92), _PlazaSceneViewState._bgTop.withValues(alpha: 0)],
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _PlazaSceneViewState._honey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app,
                          size: 15, color: _PlazaSceneViewState._honey),
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

/// 蜂巢场景本体：可平移缩放的六边形蜂巢，"我"在中心，其他蜂室环绕。
/// 不含外层 Scaffold / HUD，可自由嵌入 [PlazaPage] 或"空间"Tab。
class PlazaSceneView extends ConsumerStatefulWidget {
  const PlazaSceneView({super.key});

  @override
  ConsumerState<PlazaSceneView> createState() => _PlazaSceneViewState();
}

class _PlazaSceneViewState extends ConsumerState<PlazaSceneView>
    with SingleTickerProviderStateMixin {
  // ---- 蜂巢暖色调色板 ----
  static const _bgTop = Color(0xFF1A0F00);
  static const _bgMid = Color(0xFF2A1B05);
  static const _bgBottom = Color(0xFF3D2A0E);
  static const _honey = Color(0xFFFFC107);
  static const _honeyBright = Color(0xFFFFE082);
  static const _honeyDeep = Color(0xFFB8860B);
  static const _combEmpty = Color(0xFF3A2A12);

  // ---- 六边形（尖顶）几何参数 ----
  // 尖顶六边形：从中心到顶点距离 = size
  // width  = sqrt(3) * size
  // height = 2 * size
  // 同列间距 = sqrt(3) * size；同列垂直步进 = 1.5 * size
  // 奇数行水平偏移 = sqrt(3)/2 * size
  static const double _size = 44.0;
  static const double _hexW = 1.7320508 * _size;
  static const double _hexH = 2.0 * _size;
  static const double _hStep = 1.7320508 * _size;
  static const double _vStep = 1.5 * _size;
  static const double _hOffset = 0.8660254 * _size;

  // 5 行 5 列蜂室：中心 [2,2] 留给"我"，其余 24 格给附近同好
  static const int _rows = 5;
  static const int _cols = 5;
  static const int _meRow = 2;
  static const int _meCol = 2;
  static const double _pad = _size + 4; // 周边留出足够呼吸空间

  static double get _sceneW => _hStep * (_cols - 1) + _hexW + _pad * 2;
  static double get _sceneH => _vStep * (_rows - 1) + _hexH + _pad * 2;

  final _tc = TransformationController();
  late final AnimationController _glow;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    // 全场共享呼吸辉光控制器，驱动所有在线蜂室的"蜂光"呼吸。
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
    final nearby = ref.watch(nearbyUsersProvider).take(24).toList();

    return LayoutBuilder(
      builder: (context, c) {
        if (!_fitted) {
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
          child: _Honeycomb(
            nearby: nearby,
            me: me,
            onTapUser: (n) => _showUserSheet(context, ref, n, lang),
          ),
        );
      },
    );
  }

  // ---- 用户资料底部卡（蜂巢暖色风格） ----
  void _showUserSheet(
      BuildContext context, WidgetRef ref, UserWithDistance n, String lang) {
    final u = n.user;
    final displayName = u.name(lang);
    final accent = u.tags.isNotEmpty ? u.tags.first.color : _honey;
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
              colors: [Color(0xFF2A1B05), Color(0xFF160B00)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: _honey.withValues(alpha: 0.2), blurRadius: 30),
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
                    label: displayName,
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
                                displayName,
                                style: AppTextStyles.title
                                    .copyWith(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (u.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  size: 16, color: _honey),
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
                                    ? _honey
                                    : AppColors.textMuted,
                                boxShadow: u.online
                                    ? [
                                        BoxShadow(
                                            color: _honey.withValues(alpha: 0.8),
                                            blurRadius: 5),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              u.online
                                  ? ref.tr('online')
                                  : (lang == 'zh' ? '离线' : 'Offline'),
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white60),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${ref.tr('match_rate')} ${n.matchRate}%',
                              style: AppTextStyles.caption
                                  .copyWith(color: _honeyBright),
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
                  const Icon(Icons.local_fire_department,
                      size: 15, color: _honey),
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

/// 整张蜂巢：暖色背景 + 25 个六边形蜂室网格。
class _Honeycomb extends StatelessWidget {
  final List<UserWithDistance> nearby;
  final UserProfile me;
  final ValueChanged<UserWithDistance> onTapUser;

  const _Honeycomb({
    required this.nearby,
    required this.me,
    required this.onTapUser,
  });

  @override
  Widget build(BuildContext context) {
    // 将附近用户按"米字形/螺旋形"展开到 24 个蜂室（不含中心）
    final cells = _buildCellLayout(nearby);

    return SizedBox(
      width: _PlazaSceneViewState._sceneW,
      height: _PlazaSceneViewState._sceneH,
      child: Stack(
        children: [
          // 暖色径向背景（中心稍亮，营造蜂巢中央光）
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    _PlazaSceneViewState._bgBottom,
                    _PlazaSceneViewState._bgMid,
                    _PlazaSceneViewState._bgTop,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // 远景：六角蜂巢纹理（淡化 + 远视差感）
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: CustomPaint(painter: _BackgroundHivePainter()),
            ),
          ),
          // 标题：GoBuzz · HIVE
          Positioned(
            top: _PlazaSceneViewState._pad,
            left: 0,
            right: 0,
            child: const Center(child: _HiveSign()),
          ),
          // 25 个蜂室：先放中心"我"，再放其余 24 格
          ..._buildHexes(cells),
        ],
      ),
    );
  }

  // 把附近用户按"从中心向外"螺旋形映射到 24 个非中心蜂室，
  // 这样越靠近中心的好友越显眼，构图更有层次。
  List<UserWithDistance?> _buildCellLayout(List<UserWithDistance> source) {
    // 螺旋顺序：围绕中心 [2,2]，从近到远排列所有 24 个非中心格坐标。
    // 必须恰好覆盖 5×5 网格中除 [2,2](我) 之外的每一格，否则 _buildHexes
    // 按 (r,c) 遍历时 cellIdx 会超出 cells 长度导致 RangeError。
    const ringOrder = <List<int>>[
      // 第一圈：紧邻 6 格
      [1, 2], [2, 3], [3, 2], [2, 1], [1, 1], [3, 3],
      // 第二圈：外围 12 格（无重复）
      [0, 2], [1, 3], [2, 4], [3, 4], [4, 2], [4, 1],
      [3, 0], [2, 0], [1, 0], [0, 1], [0, 3], [4, 3],
      // 四角 4 格
      [0, 0], [0, 4], [4, 0], [4, 4],
    ];

    // 去重保证每格唯一
    final seen = <String>{};
    final unique = <List<int>>[];
    for (final rc in ringOrder) {
      final k = '${rc[0]}_${rc[1]}';
      if (seen.add(k)) unique.add(rc);
    }

    // 关键修复：结果数组长度必须等于非中心格总数 (_rows*_cols-1 = 24)
    // _buildHexes 会按网格逐一 cells[cellIdx++]
    const totalNonCenter = _PlazaSceneViewState._rows * _PlazaSceneViewState._cols - 1;
    final result = List<UserWithDistance?>.filled(totalNonCenter, null);

    for (var i = 0; i < unique.length && i < source.length; i++) {
      result[i] = source[i];
    }
    return result;
  }

  // 蜂巢 + 铭牌分两层渲染：先铺满所有蜂室（会有正常的六边形嵌套重叠），
  // 再统一把所有名字铭牌叠加在最上层——这样任何一格的铭牌都不会被
  // "下一行"蜂室盖住（此前 bug：铭牌和蜂室混在同一层按行序绘制，
  // 后绘制的下一行蜂室会覆盖上一行悬垛在外的铭牌，导致文字重叠花屏）。
  List<Widget> _buildHexes(List<UserWithDistance?> cells) {
    final hexWidgets = <Widget>[];
    final labelWidgets = <Widget>[];
    var cellIdx = 0;
    for (int r = 0; r < _PlazaSceneViewState._rows; r++) {
      for (int c = 0; c < _PlazaSceneViewState._cols; c++) {
        final isMe = r == _PlazaSceneViewState._meRow &&
            c == _PlazaSceneViewState._meCol;
        final dx = c * _PlazaSceneViewState._hStep +
            (r.isOdd ? _PlazaSceneViewState._hOffset : 0);
        final dy = r * _PlazaSceneViewState._vStep;
        final left = _PlazaSceneViewState._pad + dx;
        final top = _PlazaSceneViewState._pad + 110 + dy; // 110 = 顶部 HiveSign 高度

        final UserProfile? user = isMe ? me : cells[cellIdx]?.user;
        final onTap = isMe
            ? () {}
            : () {
                final u = cells[cellIdx];
                if (u != null) onTapUser(u);
              };
        if (!isMe) cellIdx++;

        hexWidgets.add(Positioned(
          left: left,
          top: top,
          child: _HexCell(
            user: user,
            isMe: isMe,
            isCenter: isMe,
            onTap: onTap,
          ),
        ));

        if (user != null) {
          labelWidgets.add(Positioned(
            left: left,
            top: top + _PlazaSceneViewState._hexH - 10,
            width: _PlazaSceneViewState._hexW,
            child: Center(
              child: _HexLabel(user: user, isMe: isMe),
            ),
          ));
        }
      }
    }
    return [...hexWidgets, ...labelWidgets];
  }
}

/// 单个六边形蜂室：统一蜂蜜金配色 + 中心头像 + 在线呼吸光。
/// 设计要点（重构说明）：
/// - 不再用用户标签色整格填充（避免蓝/红/黄/绿花色拼图，视觉杂乱）；
///   蜂室填充统一为蜂蜜金渐变（在线）或暗蜂蜡色（离线/空）。
/// - 标签色只作为头像下方一个小圆点指示，克制地保留个性化信息。
/// - 名字铭牌不再放在这里绘制，由外层 [_Honeycomb] 统一叠加在最上层，
///   避免被相邻蜂室遮挡。
class _HexCell extends StatelessWidget {
  final UserProfile? user;
  final bool isMe;
  final bool isCenter;
  final VoidCallback onTap;

  const _HexCell({
    required this.user,
    required this.isMe,
    required this.isCenter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final empty = user == null;
    final tag = user != null && user!.tags.isNotEmpty ? user!.tags.first : null;
    final accent = tag?.color ?? _PlazaSceneViewState._honey;
    final online = user?.online ?? false;
    final size = _PlazaSceneViewState._size;
    final active = !empty && (online || isCenter);

    return GestureDetector(
      onTap: empty ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: _PlazaSceneViewState._hexW,
        height: _PlazaSceneViewState._hexH,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 呼吸辉光（仅在线 / 中心显示），统一蜂蜜金色调
            if (active)
              _BreathingGlow(
                isCenter: isCenter,
              ),
            // 六边形蜂室本身：统一蜂蜜金渐变
            CustomPaint(
              size: Size(_PlazaSceneViewState._hexW, _PlazaSceneViewState._hexH),
              painter: _HexPainter(
                size: size,
                fillColor: active
                    ? (isCenter
                        ? _PlazaSceneViewState._honey
                        : _PlazaSceneViewState._honeyDeep.withValues(alpha: 0.55))
                    : _PlazaSceneViewState._combEmpty,
                borderColor: empty
                    ? Colors.white.withValues(alpha: 0.06)
                    : (active
                        ? _PlazaSceneViewState._honeyBright
                        : Colors.white.withValues(alpha: 0.14)),
                borderWidth: isCenter ? 2.4 : 1.4,
                glow: active,
                isMe: isMe,
              ),
            ),
            // 中心：头像 + 标签色小圆点（个性化指示，不再整格染色）
            if (user != null)
              Padding(
                padding: EdgeInsets.all(size * 0.30),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AvatarPlaceholder(
                      seed: user!.avatarSeed,
                      label: user!.nickname,
                      size: size * 0.95,
                      online: user!.online,
                      glow: isMe,
                    ),
                    if (tag != null)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            border: Border.all(
                                color: _PlazaSceneViewState._bgTop,
                                width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else
              // 空蜂室：暗淡占位
              Icon(
                Icons.hexagon_outlined,
                size: size * 0.45,
                color: Colors.white.withValues(alpha: 0.05),
              ),
          ],
        ),
      ),
    );
  }
}

/// 呼吸辉光，统一使用蜂蜜金色调（不再随用户标签色变化，避免花哨）。
class _BreathingGlow extends StatelessWidget {
  final bool isCenter;
  const _BreathingGlow({required this.isCenter});

  @override
  Widget build(BuildContext context) {
    final glow = context.findAncestorStateOfType<_PlazaSceneViewState>()?._glow;
    if (glow == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: glow,
      builder: (context, _) {
        final t = glow.value;
        return Container(
          width: _PlazaSceneViewState._hexW + 12,
          height: _PlazaSceneViewState._hexH + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                (isCenter
                        ? _PlazaSceneViewState._honeyBright
                        : _PlazaSceneViewState._honey)
                    .withValues(alpha: 0.4 * (0.55 + t * 0.45)),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 名字铭牌：统一叠加在最上层渲染，不会被相邻蜂室遮挡。
class _HexLabel extends ConsumerWidget {
  final UserProfile user;
  final bool isMe;
  const _HexLabel({required this.user, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = user.online;
    final label = isMe
        ? 'YOU'
        : user.name(ref.watch(localeProvider).languageCode);
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isMe
            ? _PlazaSceneViewState._honey.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe
              ? _PlazaSceneViewState._honey
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: online ? _PlazaSceneViewState._honey : AppColors.textMuted,
              boxShadow: online
                  ? [
                      BoxShadow(
                          color: _PlazaSceneViewState._honey.withValues(alpha: 0.8),
                          blurRadius: 4),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 尖顶六边形 painter：填充 + 描边 + 可选外发光。
class _HexPainter extends CustomPainter {
  final double size;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final bool glow;
  final bool isMe;

  _HexPainter({
    required this.size,
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.glow,
    required this.isMe,
  });

  Path _pointyTopHex(Offset center) {
    // 6 个顶点：上下各一个 + 左右各两个
    final p = Path();
    for (int i = 0; i < 6; i++) {
      // 起始角 = -90°（顶点朝上），每次 +60°
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final hex = _pointyTopHex(center);

    // 填充
    final fill = Paint()..color = fillColor;
    canvas.drawPath(hex, fill);

    // 内层高光（仅中心"我"蜂室有，强化主蜂室）
    if (isMe) {
      final inner = Paint()
        ..shader = RadialGradient(
          colors: [
            _PlazaSceneViewState._honeyBright.withValues(alpha: 0.55),
            _PlazaSceneViewState._honey.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: size * 0.7));
      canvas.drawPath(hex, inner);
    }

    // 外发光
    if (glow) {
      final glowPaint = Paint()
        ..color = borderColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(hex, glowPaint);
    }

    // 边框
    final stroke = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(hex, stroke);
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.glow != glow ||
      old.isMe != isMe;
}

/// 远景背景蜂巢纹理：浅色描边大六边形铺底，营造蜂巢在雾气中的纵深。
class _BackgroundHivePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _PlazaSceneViewState._honey.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final r = 60.0; // 背景六边形半径
    final dx = r * 1.732;
    final dy = r * 1.5;
    final offX = dx / 2;
    for (int row = -1;; row++) {
      final y = row * dy;
      if (y - r > size.height) break;
      final offset = row.isOdd ? offX : 0.0;
      for (int col = -1;; col++) {
        final x = col * dx + offset;
        if (x - r > size.width) break;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (math.pi / 3) * i - math.pi / 2;
          final px = x + r * math.cos(a);
          final py = y + r * math.sin(a);
          if (i == 0)
            path.moveTo(px, py);
          else
            path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundHivePainter old) => false;
}

/// 蜂巢顶部霓虹招牌。
class _HiveSign extends StatelessWidget {
  const _HiveSign();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _PlazaSceneViewState._honey.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
              color: _PlazaSceneViewState._honey.withValues(alpha: 0.35),
              blurRadius: 24),
          BoxShadow(
              color: _PlazaSceneViewState._honeyDeep.withValues(alpha: 0.25),
              blurRadius: 30),
        ],
        gradient: LinearGradient(
          colors: [
            _PlazaSceneViewState._honey.withValues(alpha: 0.10),
            _PlazaSceneViewState._honeyDeep.withValues(alpha: 0.10),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hexagon,
              color: _PlazaSceneViewState._honey, size: 20),
          const SizedBox(width: 10),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => const LinearGradient(
              colors: [_PlazaSceneViewState._honey, _PlazaSceneViewState._honeyDeep],
            ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
            child: Text(
              'GoBuzz · HIVE',
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
        border: Border.all(color: _PlazaSceneViewState._honey.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _PlazaSceneViewState._honey,
              boxShadow: [
                BoxShadow(
                    color: _PlazaSceneViewState._honey.withValues(alpha: 0.8),
                    blurRadius: 6),
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
