import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  // ── Palette aliases → canonical Figma tokens (AppColors) ───────
  static const darkBg = AppColors.bg0;
  static const warmGlow = Color(0xFF2E1A00);
  static const amberDark = Color(0xFFE47701);
  static const amberGold = AppColors.neonYellow;
  static const creamWhite = AppColors.textPrimary;

  static const onboardingGradient = LinearGradient(
    colors: [amberGold, amberDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      _ObData(
        ref.tr('ob1_title'),
        ref.tr('ob1_desc'),
        ref.tr('ob1_emphasis'),
        _MapIllustration(),
      ),
      _ObData(
        ref.tr('ob2_title'),
        ref.tr('ob2_desc'),
        ref.tr('ob2_emphasis'),
        _NetworkIllustration(),
      ),
      _ObData(
        ref.tr('ob3_title'),
        ref.tr('ob3_desc'),
        ref.tr('ob3_emphasis'),
        _ChatIllustration(),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [warmGlow, darkBg],
            center: Alignment(0.0, -0.4),
            radius: 1.4,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top progress bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      Expanded(
                        child: Container(
                          height: 3,
                          margin: EdgeInsets.only(
                              right: i < pages.length - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            gradient: i <= _index ? onboardingGradient : null,
                            color: i <= _index
                                ? null
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Skip button (subtle) ──
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      ref.tr('skip'),
                      style: AppTextStyles.caption
                          .copyWith(color: creamWhite.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ),

              // ── Illustration area ──
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (c, i) => _ObView(data: pages[i]),
                ),
              ),

              // ── Text + CTA area ──
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with emphasis word
                      _buildTitle(pages[_index]),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        pages[_index].desc,
                        textAlign: TextAlign.left,
                        style: AppTextStyles.tt(
                          size: 15,
                          weight: FontWeight.w500,
                          color: creamWhite.withValues(alpha: 0.62),
                          height: 1.5,
                        ),
                      )
                          .animate(key: ValueKey(_index))
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.15, duration: 350.ms),
                      const Spacer(),

                      // CTA Button
                      _CtaButton(
                        label: _index == pages.length - 1
                            ? ref.tr('ob_start')
                            : ref.tr('next'),
                        onPressed: () {
                          if (_index == pages.length - 1) {
                            context.go('/login');
                          } else {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build rich title with a gold emphasis word (split by '|').
  Widget _buildTitle(_ObData data) {
    final parts = data.title.split('|');
    final base = AppTextStyles.tt(
      size: 33,
      weight: FontWeight.w800,
      color: creamWhite,
      letterSpacing: -0.5,
    );
    if (parts.length == 1) {
      return Text(data.title, style: base);
    }
    return RichText(
      textAlign: TextAlign.left,
      text: TextSpan(
        style: base,
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts[0]),
          if (parts.length > 1)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    onboardingGradient.createShader(bounds),
                child: Text(' ${parts[1]}', style: base.copyWith(color: Colors.white)),
              ),
            ),
        ],
      ),
    )
        .animate(key: ValueKey(data.title))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.12, duration: 350.ms);
  }
}

// ══════════════════════════════════════════════════════════════════
// DATA MODEL
// ══════════════════════════════════════════════════════════════════

class _ObData {
  final String title;
  final String desc;
  final String emphasis;
  final Widget illustration;
  _ObData(this.title, this.desc, this.emphasis, this.illustration);
}

// ══════════════════════════════════════════════════════════════════
// PAGE VIEW — illustration + title rendering
// ══════════════════════════════════════════════════════════════════

class _ObView extends StatelessWidget {
  final _ObData data;
  const _ObView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: data.illustration,
    )
        .animate(key: ValueKey(data.title))
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.08, duration: 400.ms);
  }
}

// ══════════════════════════════════════════════════════════════════
// CTA BUTTON — warm amber gradient
// ══════════════════════════════════════════════════════════════════

class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _CtaButton({required this.label, required this.onPressed});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: _OnboardingPageState.onboardingGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB347).withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 18,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: AppTextStyles.tt(
                  size: 16,
                  weight: FontWeight.w800,
                  color: const Color(0xFF2E1810),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Color(0xFF2E1810)),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ILLUSTRATION 1 — Map / Location scene
// ══════════════════════════════════════════════════════════════════

class _MapIllustration extends StatelessWidget {
  const _MapIllustration();

  @override
  Widget build(BuildContext context) {
    // Real Figma 3D illustration (glossy pin + orbit + chat/person badges).
    return Center(
      child: Image.asset(
        'assets/images/decorations/fig_buzz_orbit.png',
        fit: BoxFit.contain,
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -6, end: 6, duration: 3200.ms),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ILLUSTRATION 2 — Social network / tag match scene
// ══════════════════════════════════════════════════════════════════

class _NetworkIllustration extends StatelessWidget {
  static const _positions = [
    Offset(0, -95), // top
    Offset(82, -45), // top-right
    Offset(92, 42), // bottom-right
    Offset(30, 88), // bottom
    Offset(-62, 58), // bottom-left
    Offset(-88, -22), // top-left
    Offset(-38, -72), // mid-left
    Offset(48, -78), // mid-right
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 290,
        height: 290,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow ring
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFFFCC66).withValues(alpha: 0.12),
                  Colors.transparent,
                ]),
              ),
            ),

            // "buzz" center text
            Container(
              width: 86,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: 0.3),
              ),
              alignment: Alignment.center,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFCC66), Color(0xFFFF9A3C)],
                ).createShader(bounds),
                child: Text(
                  'buzz',
                  style: AppTextStyles.tt(
                    size: 18,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.96, end: 1.04, duration: 1800.ms),

            // Connection lines (drawn behind avatars)
            CustomPaint(
              size: const Size(290, 290),
              painter: _ConnectionLinePainter(),
            ),

            // Interest orbs (glossy 3D bubbles)
            ..._positions.asMap().entries.map((entry) {
              final idx = entry.key;
              final pos = entry.value;
              final delayMs = idx * 120;
              final color = _avatarColors[idx % _avatarColors.length];

              return Positioned(
                left: pos.dx + 145 - 26,
                top: pos.dy + 145 - 26,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.4),
                      colors: [
                        Color.lerp(color, Colors.white, 0.55)!,
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 1),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(
                        begin: 0.85, end: 1.0, duration: (1800 + delayMs).ms)
                    .then(delay: Duration(milliseconds: delayMs)),
              );
            }),

            // Floating sparkles
            ...[
              const Offset(-100, -80),
              const Offset(105, -20),
              const Offset(-90, 70),
              const Offset(95, 85)
            ].map(
              (pos) => Positioned(
                left: pos.dx + 145,
                top: pos.dy + 145,
                child: Icon(Icons.auto_awesome,
                        size: 14,
                        color: const Color(0xFFFFCC66).withValues(alpha: 0.5))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.3, end: 1.0, duration: 1200.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _avatarColors = [
    Color(0xFF4ECDC4),
    Color(0xFF9B59B6),
    Color(0xFFE67E22),
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
    Color(0xFFF39C12),
    Color(0xFF1ABC9C),
    Color(0xFF8E44AD),
  ];
}

// ══════════════════════════════════════════════════════════════════
// ILLUSTRATION 3 — Chat / messaging scene
// ══════════════════════════════════════════════════════════════════

class _ChatIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 260,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Phone frame
            Container(
              width: 145,
              height: 270,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2018),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x00000000),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: Column(
                  children: [
                    // Status bar mock
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.04),
                            Colors.white.withValues(alpha: 0.01)
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 8),
                          Text('GoBuzz',
                              style: AppTextStyles.tt(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    const Divider(height: 0.5, color: Color(0x15FFFFFF)),

                    // Chat bubbles area
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Incoming bubble
                            _chatBubble(
                              isMe: false,
                              name: 'Maya',
                              text: 'Where you at?',
                              color: const Color(0xFF3D2E23),
                            ),
                            const SizedBox(height: 6),
                            // Outgoing bubble
                            _chatBubble(
                              isMe: true,
                              name: 'You',
                              text: 'Almost there! 🚀',
                              color: const Color(0xFFE67E22),
                            ),
                            const SizedBox(height: 6),
                            // Another incoming
                            _chatBubble(
                              isMe: false,
                              name: 'Alex',
                              text: 'See you soon!',
                              color: const Color(0xFF3D2E23),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.98, end: 1.01, duration: 3000.ms),

            // Surrounding avatars
            Positioned(
                left: 0,
                top: 30,
                child: _floatingAvatar('buzz9', size: 34, delay: 0)),
            Positioned(
                right: 0,
                top: 60,
                child: _floatingAvatar('buzz10', size: 30, delay: 400)),
            Positioned(
                left: 5,
                bottom: 60,
                child: _floatingAvatar('buzz11', size: 28, delay: 800)),
            Positioned(
                right: 8,
                bottom: 30,
                child: _floatingAvatar('buzz12', size: 32, delay: 300)),

            // Notification badge
            Positioned(
              right: 20,
              top: 110,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _orb(20, color: const Color(0xFFF0A83A)),
                    const SizedBox(width: 6),
                    Text('Sofia',
                        style: AppTextStyles.tt(
                            size: 10,
                            weight: FontWeight.w700,
                            color: const Color(0xFF333333))),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveX(begin: -4, end: 4, duration: 2200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatBubble(
      {required bool isMe,
      required String name,
      required String text,
      required Color color}) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          _orb(22, color: const Color(0xFFE0A62E)),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 4 : 14),
                bottomRight: Radius.circular(isMe ? 14 : 4),
              ),
            ),
            child: Text(text,
                style: AppTextStyles.tt(
                    size: 10,
                    weight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 5),
          _orb(22, color: const Color(0xFFF0A83A)),
        ],
      ],
    );
  }

  Widget _floatingAvatar(String seed, {double size = 32, int delay = 0}) {
    return _orb(size, color: const Color(0xFF6B4A18))
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: (2200 + delay).ms)
        .then(delay: Duration(milliseconds: delay));
  }

  /// Local glossy avatar orb (replaces broken dicebear SVG network images).
  static Widget _orb(double d, {Color color = const Color(0xFFE0A62E)}) {
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [Color.lerp(color, Colors.white, 0.5)!, color],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// HELPERS & PAINTERS
// ══════════════════════════════════════════════════════════════════

/// Connection line painter between avatar positions
class _ConnectionLinePainter extends CustomPainter {
  static const _positions = [
    Offset(0, -95),
    Offset(82, -45),
    Offset(92, 42),
    Offset(30, 88),
    Offset(-62, 58),
    Offset(-88, -22),
    Offset(-38, -72),
    Offset(48, -78),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFCC66).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final center = Offset(size.width / 2, size.height / 2);

    for (final pos in _positions) {
      final p = pos + const Offset(145, 145);
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx +
              (p.dx - center.dx) * 0.5 +
              (math.Random().nextDouble() - 0.5) * 20,
          center.dy +
              (p.dy - center.dy) * 0.5 +
              (math.Random().nextDouble() - 0.5) * 20,
          p.dx,
          p.dy,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinePainter old) => false;
}
