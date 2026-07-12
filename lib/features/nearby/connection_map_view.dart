import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../avatar/widgets/virtual_avatar_view.dart';

/// 「Connection Map」— 以中心用户为圆心的关系图，无地图底图。
/// 视觉：中央头像 + 6 个外围头像 + 虚线连接 + 中点匹配度标签。
class ConnectionMapView extends ConsumerWidget {
  const ConnectionMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearby = ref.watch(nearbyUsersProvider);
    final me = ref.watch(currentUserProvider);

    // 取前 6 个（已按匹配度+距离排序）
    final users = nearby.take(6).toList();

    return Container(
      color: AppColors.bg0,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── 顶部标题区 ──
            _Header(count: users.length),
            // ── 关系图 ──
            Expanded(
              child: users.isEmpty
                  ? const _EmptyState()
                  : LayoutBuilder(
                      builder: (context, c) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: _RelationshipGraph(
                            size: math.min(c.maxWidth, c.maxHeight),
                            me: me,
                            users: users,
                          ),
                        );
                      },
                    ),
            ),
            // ── 底部统计行 + 横向卡片列表 ──
            if (users.isNotEmpty)
              _BottomSummary(
                count: users.length,
                nearby: nearby.take(6).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 顶部标题区
// ══════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final int count;
  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Near you tonight',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.neonYellow, AppColors.neonGreen],
                  ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text(
                    'Connection map',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 右上角发送/定位按钮
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bg1,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.near_me_outlined,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 关系图：CustomPainter 画虚线 + Positioned 放头像
// ══════════════════════════════════════════════════════════════════

class _RelationshipGraph extends StatefulWidget {
  final double size;
  final UserProfile me;
  final List<UserWithDistance> users;

  const _RelationshipGraph({
    required this.size,
    required this.me,
    required this.users,
  });

  @override
  State<_RelationshipGraph> createState() => _RelationshipGraphState();
}

class _RelationshipGraphState extends State<_RelationshipGraph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size * 0.38;
    final avatarOuter = 64.0; // 头像外直径（含环）

    // 角度分布：从顶部 12 点方向开始，顺时针均分
    final positions = <Offset>[];
    final n = widget.users.length;
    final startAngle = -math.pi / 2; // 12 点
    for (var i = 0; i < n; i++) {
      final a = startAngle + (i * 2 * math.pi / n);
      positions.add(Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      ));
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              // 背景：微弱的同心光圈
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GlowPainter(
                  center: center,
                  animation: _ctrl.value,
                ),
              ),
              // 虚线连接 + 匹配度标签
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ConnectionPainter(
                  center: center,
                  targets: positions,
                  matchRates: widget.users.map((u) => u.matchRate).toList(),
                ),
              ),
              // 中央头像
              Positioned(
                left: center.dx - avatarOuter / 2,
                top: center.dy - avatarOuter / 2,
                child: _CenterAvatar(user: widget.me, size: avatarOuter),
              ),
              // 外围头像
              for (var i = 0; i < positions.length; i++)
                Positioned(
                  left: positions[i].dx - avatarOuter / 2,
                  top: positions[i].dy - avatarOuter / 2,
                  child: _OuterAvatar(
                    user: widget.users[i],
                    size: avatarOuter,
                    index: i,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Painter: 同心光晕背景
// ══════════════════════════════════════════════════════════════════

class _GlowPainter extends CustomPainter {
  final Offset center;
  final double animation;

  _GlowPainter({required this.center, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = 0.5 + 0.5 * math.sin(animation * 2 * math.pi);
    final paint1 = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.neonYellow.withValues(alpha: 0.06 + 0.03 * pulse),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width / 2));
    canvas.drawCircle(center, size.width / 2, paint1);

    // 一圈极淡的虚线圆环
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.glassBorder.withValues(alpha: 0.12);
    canvas.drawCircle(
      center,
      size.width * 0.38,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.animation != animation;
}

// ══════════════════════════════════════════════════════════════════
// Painter: 虚线连接 + 匹配度标签
// ══════════════════════════════════════════════════════════════════

class _ConnectionPainter extends CustomPainter {
  final Offset center;
  final List<Offset> targets;
  final List<int> matchRates;

  _ConnectionPainter({
    required this.center,
    required this.targets,
    required this.matchRates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < targets.length; i++) {
      final t = targets[i];
      // 起点：略偏离圆心（避开头像），终点：略接近目标（避开目标头像）
      final dir = (t - center);
      final len = dir.distance;
      if (len < 1) continue;
      final unit = dir / len;
      final start = center + unit * 40; // 中心头像半径约 32 + 余量
      final end = t - unit * 40; // 外围头像半径约 32 + 余量

      // 虚线
      final dashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.textPrimary.withValues(alpha: 0.45);
      final path = Path()..moveTo(start.dx, start.dy);
      path.lineTo(end.dx, end.dy);
      _drawDashedLine(canvas, path, dashPaint, dashWidth: 4, dashSpace: 4);

      // 中点：匹配度标签
      final mid = (start + end) / 2;
      final rate = matchRates[i];
      _drawMatchBadge(canvas, mid, rate);
    }
  }

  void _drawDashedLine(Canvas canvas, Path path, Paint paint,
      {double dashWidth = 4, double dashSpace = 4}) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  void _drawMatchBadge(Canvas canvas, Offset center, int rate) {
    final label = '$rate%';
    // 估算文本宽度
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 14;
    final h = 20.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(10),
    );
    // 背景：深色胶囊 + 细金色边
    final bg = Paint()..color = AppColors.bg1.withValues(alpha: 0.95);
    canvas.drawRRect(rect, bg);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.glassBorder.withValues(alpha: 0.6);
    canvas.drawRRect(rect, border);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter old) {
    return old.center != center ||
        old.targets != targets ||
        old.matchRates != matchRates;
  }
}

// ══════════════════════════════════════════════════════════════════
// 中央头像（带光晕 + 强调金色环）
// ══════════════════════════════════════════════════════════════════

class _CenterAvatar extends StatelessWidget {
  final UserProfile user;
  final double size;
  const _CenterAvatar({required this.user, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 光晕
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonYellow.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          // 金色环
          Container(
            width: size - 6,
            height: size - 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonYellow, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonYellow.withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            child: ClipOval(
              child: Container(
                margin: const EdgeInsets.all(2),
                color: AppColors.bg2,
                child: user.virtualAvatar != null
                    ? VirtualAvatarView(
                        avatar: user.virtualAvatar!,
                        size: size - 14,
                        glow: true,
                      )
                    : AvatarPlaceholder(
                        seed: user.avatarSeed,
                        label: user.nickname,
                        size: size - 14,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 外围头像（带细金色环 + 年龄徽章 + 名字标签）
// ══════════════════════════════════════════════════════════════════

class _OuterAvatar extends ConsumerWidget {
  final UserWithDistance user;
  final double size;
  final int index;
  const _OuterAvatar({
    required this.user,
    required this.size,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.user.name(ref.watch(localeProvider).languageCode);
    final shortName =
        name.length > 6 ? '${name.substring(0, 6)}…' : name;
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头像 + 年龄徽章
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                // 头像
                Center(
                  child: Container(
                    width: size - 8,
                    height: size - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neonYellow.withValues(alpha: 0.85),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        color: AppColors.bg2,
                        child: user.user.virtualAvatar != null
                            ? VirtualAvatarView(
                                avatar: user.user.virtualAvatar!,
                                size: size - 14,
                              )
                            : AvatarPlaceholder(
                                seed: user.user.avatarSeed,
                                label: name,
                                size: size - 14,
                              ),
                      ),
                    ),
                  ),
                ),
                // 年龄徽章
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.bg0,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${user.user.age}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 名字标签（截断 6 字符）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bg1.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              shortName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 底部统计行 + 横向卡片列表
// ══════════════════════════════════════════════════════════════════

class _BottomSummary extends StatelessWidget {
  final int count;
  final List<UserWithDistance> nearby;
  const _BottomSummary({required this.count, required this.nearby});

  @override
  Widget build(BuildContext context) {
    // 底部导航栏高度 (64) + 系统手势条高度，避免与底部 Tab 重叠
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const navBarHeight = 64.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + navBarHeight + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 统计 + View all
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A2A08), Color(0xFF0A0A0A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.glassBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count people within 3 km',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 横向卡片列表
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: nearby.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final u = nearby[i];
                return _UserCard(user: u);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserWithDistance user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = user.user;
    final name = u.name(ref.watch(localeProvider).languageCode);
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg1.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          u.virtualAvatar != null
              ? VirtualAvatarView(avatar: u.virtualAvatar!, size: 40)
              : AvatarPlaceholder(
                  seed: u.avatarSeed,
                  label: name,
                  size: 40,
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$name, ${u.age}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.distanceKm.toStringAsFixed(1)} km · ${user.matchRate}%',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 空状态
// ══════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hub_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            'No connections yet',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
