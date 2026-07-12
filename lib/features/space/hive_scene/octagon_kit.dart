import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// ---------------------------------------------------------------------------
/// 黑金蜂巢设计系统 —— 八边形裁剪 + 通用动画基元
///
/// 复刻 `多人共玩界面设计方案` 中反复出现的
/// `clip-path: polygon(30% 0,70% 0,100% 30,100% 70,70% 100,30% 100,0 70,0 30)`
/// 以及 breathe / ripple / eqbar / riseFade / danma / floaty 动效。
/// ---------------------------------------------------------------------------

/// 设计令牌（黑金）。
class GoldTokens {
  GoldTokens._();

  static const Color bg = Color(0xFF0B0906);
  static const Color cardDark = Color(0xFF0E0B07);
  static const Color cardDeep = Color(0xFF120E08);
  static const Color brightGold = Color(0xFFF6DE9C);
  static const Color midGold = Color(0xFFE8B54D);
  static const Color deepGold = Color(0xFFC98F2E);
  static const Color inkOnGold = Color(0xFF1A1206);

  static const LinearGradient goldFill = LinearGradient(
    colors: [brightGold, deepGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldBar = LinearGradient(
    colors: [brightGold, deepGold],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 星尘背景（近黑 + 金色微粒）。
  static BoxDecoration starfield() => const BoxDecoration(color: bg);
}

/// 八边形裁剪器，比例还原设计稿的 30/70 切角。
class OctagonClipper extends CustomClipper<Path> {
  const OctagonClipper();

  @override
  Path getClip(Size size) {
    final w = size.width, h = size.height;
    return Path()
      ..moveTo(0.30 * w, 0)
      ..lineTo(0.70 * w, 0)
      ..lineTo(w, 0.30 * h)
      ..lineTo(w, 0.70 * h)
      ..lineTo(0.70 * w, h)
      ..lineTo(0.30 * w, h)
      ..lineTo(0, 0.70 * h)
      ..lineTo(0, 0.30 * h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 八边形容器：外层金渐变描边 + 内层深底（描边态），或纯金渐变实心。
class OctagonBox extends StatelessWidget {
  final double size;
  final Widget child;

  /// true=实心金填充（活跃）；false=金描边深底（在场）。
  final bool filled;
  final double borderWidth;

  /// 金色发光（用于"正在说话/游戏中"）。
  final bool glow;

  const OctagonBox({
    super.key,
    required this.size,
    required this.child,
    this.filled = true,
    this.borderWidth = 1.5,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final inner = ClipPath(
      clipper: const OctagonClipper(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: filled ? GoldTokens.goldFill : null,
          color: filled ? null : const Color(0x80F6DE9C),
        ),
        alignment: Alignment.center,
        child: filled
            ? child
            : Padding(
                padding: EdgeInsets.all(borderWidth),
                child: ClipPath(
                  clipper: const OctagonClipper(),
                  child: Container(
                    color: GoldTokens.cardDark,
                    alignment: Alignment.center,
                    child: child,
                  ),
                ),
              ),
      ),
    );

    if (!glow) return inner;
    return DecoratedBox(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(color: Color(0x99E8B54D), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: inner,
    );
  }
}

/// 八边形头像（首字），设计稿里座位/人脸格的基础单元。
class OctagonAvatar extends StatelessWidget {
  final String initial;
  final double size;
  final bool active; // 实心金=活跃，描边=在场
  final bool glow;
  final double fontSize;

  const OctagonAvatar({
    super.key,
    required this.initial,
    this.size = 50,
    this.active = true,
    this.glow = false,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return OctagonBox(
      size: size,
      filled: active,
      glow: glow,
      child: Text(
        initial,
        style: AppTextStyles.tt(
          size: fontSize,
          weight: FontWeight.w700,
          color: active ? GoldTokens.inkOnGold : GoldTokens.midGold,
        ),
      ),
    );
  }
}

/// 状态胶囊：实心金底深字（active）/ 透明金字描边。
class StatusPill extends StatelessWidget {
  final String text;
  final bool active;
  const StatusPill({super.key, required this.text, this.active = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: active ? 7 : 6, vertical: active ? 2 : 1),
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [GoldTokens.brightGold, GoldTokens.midGold])
            : null,
        borderRadius: BorderRadius.circular(20),
        border: active
            ? null
            : Border.all(color: const Color(0x66F6DE9C)),
      ),
      child: Text(
        text,
        style: AppTextStyles.tt(
          size: 8.5,
          weight: FontWeight.w700,
          color: active ? GoldTokens.inkOnGold : const Color(0xBFF6DE9C),
        ),
      ),
    );
  }
}

// ===========================================================================
// 动画基元
// ===========================================================================

/// breathe：呼吸缩放（中心节点/等待态）。
class Breathe extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double maxScale;
  const Breathe({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 3500),
    this.maxScale = 1.06,
  });

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: widget.maxScale)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// floaty：上下轻微浮动（专辑封面）。
class Floaty extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration duration;
  const Floaty({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -widget.amplitude * t),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// ripple：向外扩散淡出的金色光圈（当前用户高亮）。
class RippleRing extends StatefulWidget {
  final double size;
  const RippleRing({super.key, this.size = 60});

  @override
  State<RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<RippleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final scale = 0.7 + _c.value * 1.2;
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: (0.6 * (1 - _c.value)).clamp(0.0, 1.0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xCCE8B54D), width: 1.5),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// eqbar：一排音频律动条（各条不同 delay 制造错落感）。
class EqualizerBars extends StatefulWidget {
  final int count;
  final double barWidth;
  final double maxHeight;
  final double gap;
  const EqualizerBars({
    super.key,
    this.count = 12,
    this.barWidth = 4,
    this.maxHeight = 34,
    this.gap = 4,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  late final List<double> _phase = List.generate(
      widget.count, (i) => ((i * 0.37) % 1.0));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.count, (i) {
            final t = (_c.value + _phase[i]) % 1.0;
            // 0.3..1.0 缩放，正弦往复
            final scale = 0.3 + 0.7 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.gap / 2),
              child: Container(
                width: widget.barWidth,
                height: widget.maxHeight * scale,
                decoration: BoxDecoration(
                  gradient: GoldTokens.goldBar,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// riseFade：从下往上浮动淡出的表情。
class RiseFadeEmoji extends StatefulWidget {
  final String emoji;
  final double fontSize;
  final Duration duration;
  final Duration delay;
  const RiseFadeEmoji({
    super.key,
    required this.emoji,
    this.fontSize = 16,
    this.duration = const Duration(milliseconds: 2400),
    this.delay = Duration.zero,
  });

  @override
  State<RiseFadeEmoji> createState() => _RiseFadeEmojiState();
}

class _RiseFadeEmojiState extends State<RiseFadeEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;
          final opacity = t < 0.18
              ? t / 0.18
              : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
          return Transform.translate(
            offset: Offset(0, 14 - 60 * t),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Text(widget.emoji,
                  style: TextStyle(fontSize: widget.fontSize)),
            ),
          );
        },
      ),
    );
  }
}

/// danma：从右向左匀速平移的弹幕胶囊。
class Danmaku extends StatefulWidget {
  final Widget child;
  final double travel; // 平移距离（像素）
  final Duration duration;
  final Duration delay;
  const Danmaku({
    super.key,
    required this.child,
    this.travel = 300,
    this.duration = const Duration(seconds: 8),
    this.delay = Duration.zero,
  });

  @override
  State<Danmaku> createState() => _DanmakuState();
}

class _DanmakuState extends State<Danmaku>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          final opacity =
              t < 0.08 ? t / 0.08 : (t > 0.92 ? (1 - t) / 0.08 : 1.0);
          return Transform.translate(
            offset: Offset(-widget.travel * t, 0),
            child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// 弹幕金色胶囊（实心/描边两态）。
class DanmakuCapsule extends StatelessWidget {
  final String text;
  final bool filled;
  const DanmakuCapsule({super.key, required this.text, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: filled
            ? const LinearGradient(
                colors: [GoldTokens.brightGold, GoldTokens.midGold])
            : null,
        color: filled ? null : const Color(0x990B0906),
        borderRadius: BorderRadius.circular(20),
        border: filled ? null : Border.all(color: const Color(0x8CF6DE9C)),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: AppTextStyles.tt(
          size: 11,
          weight: FontWeight.w700,
          color: filled ? GoldTokens.inkOnGold : GoldTokens.brightGold,
        ),
      ),
    );
  }
}

/// 金色药丸主按钮（设计稿 CTA）。
class GoldPill extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onTap;
  final bool outlined;
  final double height;
  const GoldPill({
    super.key,
    required this.label,
    this.emoji,
    this.onTap,
    this.outlined = false,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: outlined ? null : GoldTokens.goldFill,
          borderRadius: BorderRadius.circular(height / 2),
          border: outlined
              ? Border.all(color: const Color(0x99F6DE9C), width: 1.5)
              : null,
          boxShadow: outlined
              ? null
              : const [
                  BoxShadow(color: Color(0x66E8B54D), blurRadius: 20, offset: Offset(0, 8)),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.tt(
                  size: 14,
                  weight: FontWeight.w700,
                  color: outlined ? GoldTokens.brightGold : GoldTokens.inkOnGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
