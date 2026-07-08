import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class TagSelectPage extends ConsumerStatefulWidget {
  const TagSelectPage({super.key});

  @override
  ConsumerState<TagSelectPage> createState() => _TagSelectPageState();
}

class _TagSelectPageState extends ConsumerState<TagSelectPage> {
  final Set<String> _selected = {};
  final List<IpTag> _customTags = [];
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  void _addCustomTag() {
    final value = _customController.text.trim();
    if (value.isEmpty) return;
    final id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    final tag = IpTag(
      id: id,
      nameZh: value,
      nameEn: value,
      category: 'custom',
      icon: Icons.auto_awesome,
    );
    setState(() {
      _customTags.add(tag);
      _selected.add(id);
      _customController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final allTags = MockDataSource.instance.tags;
    final honeyTags =
        [...allTags.take(6), ..._customTags.take(2)].take(6).toList();
    final saveTags = [...allTags, ..._customTags];
    final enough = _selected.length >= 3;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            child: Column(
              children: [
                const _ProgressBars(),
                const SizedBox(height: 24),
                Text(
                  ref.tr('tag_select_title'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 34,
                    color: AppColors.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.55),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == 'en'
                      ? 'Choose 3-6 interests, or create your own, to connect with your swarm'
                      : '至少选择3-6个，或者自定义，连接到这群人',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.86)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _HoneycombSelector(
                        tags: honeyTags,
                        selected: _selected,
                        lang: lang,
                        onToggle: _toggle,
                        selectedCount: _selected.length,
                        maxSize:
                            Size(constraints.maxWidth, constraints.maxHeight),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _CustomTagInput(
                  controller: _customController,
                  onAdd: _addCustomTag,
                  hint:
                      lang == 'en' ? 'Add your custom tag...' : '添加你的自定义标签...',
                ),
                const SizedBox(height: 14),
                NeonButton(
                  label: lang == 'en'
                      ? 'Start Your Honeycomb Network'
                      : '开启你的蜂巢网络  >>>',
                  icon: Icons.hive_rounded,
                  onPressed: enough
                      ? () {
                          final tags = saveTags
                              .where((t) => _selected.contains(t.id))
                              .toList();
                          final avatar =
                              ref.read(currentUserProvider).virtualAvatar;
                          if (avatar == null) {
                            context.go('/avatar-setup');
                            return;
                          }
                          ref
                              .read(currentUserProvider.notifier)
                              .updateTags(tags);
                          ref.read(authProvider.notifier).login();
                          context.go('/space');
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoneycombSelector extends StatelessWidget {
  final List<IpTag> tags;
  final Set<String> selected;
  final String lang;
  final ValueChanged<String> onToggle;
  final int selectedCount;
  final Size maxSize;

  const _HoneycombSelector({
    required this.tags,
    required this.selected,
    required this.lang,
    required this.onToggle,
    required this.selectedCount,
    required this.maxSize,
  });

  @override
  Widget build(BuildContext context) {
    final width = maxSize.width;
    final height = maxSize.height;
    final center = Offset(width / 2, height / 2 + 10);
    final radius = math.min(width, height) * 0.31;
    final tileSize = math.min(width * 0.29, 112.0);

    final positions = List.generate(tags.length, (index) {
      final angle = -math.pi / 2 + index * (math.pi * 2 / tags.length);
      return Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
    });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HoneyNetworkPainter(
              center: center,
              points: positions,
              selectedPoints: [
                for (var i = 0; i < tags.length; i++)
                  if (selected.contains(tags[i].id)) positions[i],
              ],
            ),
          ),
        ),
        Positioned(
          left: center.dx - tileSize * 0.48,
          top: center.dy - tileSize * 0.48,
          width: tileSize * 0.96,
          height: tileSize * 0.96,
          child: _CenterCounter(count: selectedCount),
        ),
        for (var i = 0; i < tags.length; i++)
          Positioned(
            left: positions[i].dx - tileSize / 2,
            top: positions[i].dy - tileSize / 2,
            width: tileSize,
            height: tileSize,
            child: _HoneyTagCell(
              tag: tags[i],
              lang: lang,
              selected: selected.contains(tags[i].id),
              onTap: () => onToggle(tags[i].id),
            ),
          ),
        Positioned(
          right: 4,
          top: 20,
          child: _SwarmCallout(lang: lang),
        ),
        const Positioned(left: 20, top: 58, child: _FlightSpark()),
        const Positioned(
            right: 16, bottom: 46, child: _FlightSpark(small: true)),
        const Positioned(
            left: 54, bottom: 32, child: _FlightSpark(small: true)),
      ],
    );
  }
}

class _HoneyTagCell extends StatelessWidget {
  final IpTag tag;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  const _HoneyTagCell({
    required this.tag,
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: selected ? 1.06 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.neonYellow
                    .withValues(alpha: selected ? 0.62 : 0.3),
                blurRadius: selected ? 28 : 16,
                spreadRadius: selected ? 2 : 0,
              ),
            ],
          ),
          child: ClipPath(
            clipper: const _HexagonClipper(),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selected
                      ? const [
                          Color(0xFFFFF2A3),
                          Color(0xFFFFC21A),
                          Color(0xFFFF9B00)
                        ]
                      : const [
                          Color(0xFFFFE16B),
                          Color(0xFFFFBD1C),
                          Color(0xFFD88B00)
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4), width: 1.4),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tag.icon,
                              size: 28, color: const Color(0xFF493000)),
                          const SizedBox(height: 6),
                          Text(
                            '《${tag.name(lang)}》',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyStrong.copyWith(
                              color: const Color(0xFF2B1B00),
                              fontSize: 13,
                              height: 1.05,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      right: 14,
                      top: 14,
                      child: Icon(Icons.check_circle,
                          size: 18, color: Color(0xFF2B1B00)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterCounter extends StatelessWidget {
  final int count;

  const _CenterCounter({required this.count});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _HexagonClipper(),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5C4700), Color(0xFF211902)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.neonYellow, width: 1.4),
          boxShadow: [
            BoxShadow(
                color: AppColors.neonYellow.withValues(alpha: 0.4),
                blurRadius: 18),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('已选择:',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary)),
              Text(
                '$count/6',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTagInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final String hint;

  const _CustomTagInput({
    required this.controller,
    required this.onAdd,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onAdd(),
      style: AppTextStyles.bodyStrong.copyWith(color: const Color(0xFF2B1B00)),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8A6A00)),
          onPressed: onAdd,
        ),
      ),
    );
  }
}

class _SwarmCallout extends StatelessWidget {
  final String lang;

  const _SwarmCallout({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: AppColors.neonYellow.withValues(alpha: 0.35),
              blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang == 'en' ? 'Connect to fans' : '连接到同种人群',
            style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF2B1B00), fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniAvatar(color: Color(0xFF9EF1E5)),
              _MiniAvatar(color: Color(0xFFFFB000)),
              _MiniAvatar(color: Color(0xFFFF8F1F)),
              Icon(Icons.auto_awesome, size: 13, color: Color(0xFF8A6A00)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final Color color;

  const _MiniAvatar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i == 0
                    ? AppColors.neonCyan
                    : AppColors.textPrimary.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i != 2) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FlightSpark extends StatelessWidget {
  final bool small;

  const _FlightSpark({this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 22.0 : 28.0;
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: AppColors.neonYellow.withValues(alpha: 0.85),
      shadows: [
        Shadow(
            color: AppColors.neonYellow.withValues(alpha: 0.8), blurRadius: 16),
      ],
    );
  }
}

class _HoneyNetworkPainter extends CustomPainter {
  final Offset center;
  final List<Offset> points;
  final List<Offset> selectedPoints;

  const _HoneyNetworkPainter({
    required this.center,
    required this.points,
    required this.selectedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.neonYellow.withValues(alpha: 0.38)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final glowPaint = Paint()
      ..color = AppColors.neonYellow.withValues(alpha: 0.18)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    for (final point in points) {
      canvas.drawLine(center, point, glowPaint);
      canvas.drawLine(center, point, linePaint);
    }
    final selectedPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final point in selectedPoints) {
      canvas.drawLine(center, point, selectedPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HoneyNetworkPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedPoints != selectedPoints;
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final point = Offset(center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
