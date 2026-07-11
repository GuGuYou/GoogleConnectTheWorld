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
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/hexagon.dart';
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

  static const _exampleKeys = {
    'game': 'tag_example_game',
    'anime': 'tag_example_anime',
    'drama': 'tag_example_drama',
    'comic': 'tag_example_comic',
    'music': 'tag_example_music',
    'custom': 'tag_example_custom',
  };

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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _HoneycombSelector(
                        tags: honeyTags,
                        examples: [
                          for (final t in honeyTags)
                            _exampleKeys[t.category] == null
                                ? ''
                                : ref.tr(_exampleKeys[t.category]!),
                        ],
                        selected: _selected,
                        lang: lang,
                        onToggle: _toggle,
                        selectedCount: _selected.length,
                        picksLabel: ref.tr('tag_select_your_picks'),
                        maxSize:
                            Size(constraints.maxWidth, constraints.maxHeight),
                      );
                    },
                  ),
                ),
                GradientText(
                  ref.tr('tag_select_title'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display(context).copyWith(fontSize: 32),
                ),
                const SizedBox(height: 6),
                Text(
                  ref.tr('tag_select_subtitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),
                _CustomTagInput(
                  controller: _customController,
                  onAdd: _addCustomTag,
                  label: ref.tr('tag_select_add_own'),
                  hint: ref.tr('tag_select_custom_hint'),
                ),
                const SizedBox(height: 16),
                NeonButton(
                  label: ref.tr('tag_select_continue'),
                  icon: Icons.arrow_forward_rounded,
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
  final List<String> examples;
  final Set<String> selected;
  final String lang;
  final ValueChanged<String> onToggle;
  final int selectedCount;
  final String picksLabel;
  final Size maxSize;

  const _HoneycombSelector({
    required this.tags,
    required this.examples,
    required this.selected,
    required this.lang,
    required this.onToggle,
    required this.selectedCount,
    required this.picksLabel,
    required this.maxSize,
  });

  /// Tight flat-top honeycomb flower: 6 edge-sharing neighbours around the
  /// centre (top, 4 diagonals, bottom), in tile-size units. Distance R√3 =
  /// 0.866·tile so the hexagons touch with no gaps.
  static const _offsets = [
    Offset(0, -0.866), // top
    Offset(-0.75, -0.433), // upper-left
    Offset(0.75, -0.433), // upper-right
    Offset(-0.75, 0.433), // lower-left
    Offset(0.75, 0.433), // lower-right
    Offset(0, 0.866), // bottom
  ];

  @override
  Widget build(BuildContext context) {
    final width = maxSize.width;
    final height = maxSize.height;
    final center = Offset(width / 2, height / 2);
    // 蜂窝簇的几何自然尺寸为 2.5×tile 宽、2.732×tile 高。手机上宽度为
    // 绑定项，故把宽度除数压到接近几何下限(2.32)、上限抬到 184，让六边形
    // 用满可用宽度（略微探入两侧 22px 内边距，Clip.none 不裁剪、不溢出屏幕），
    // 明显放大整簇；height/2.75 作为竖向安全阀，避免压到上方进度条/下方标题。
    final tileSize =
        math.min(math.min(width / 2.32, height / 2.75), 184.0);

    final positions = [
      for (var i = 0; i < tags.length; i++)
        center + _offsets[i % _offsets.length] * tileSize,
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: center.dx - tileSize / 2,
          top: center.dy - tileSize / 2,
          width: tileSize,
          height: tileSize,
          child: _CenterCounter(count: selectedCount, label: picksLabel),
        ),
        for (var i = 0; i < tags.length; i++)
          Positioned(
            left: positions[i].dx - tileSize / 2,
            top: positions[i].dy - tileSize / 2,
            width: tileSize,
            height: tileSize,
            child: _HoneyTagCell(
              tag: tags[i],
              example: examples[i],
              lang: lang,
              selected: selected.contains(tags[i].id),
              onTap: () => onToggle(tags[i].id),
            ),
          ),
        const Positioned(left: 6, top: 24, child: _FlightSpark()),
        const Positioned(
            right: 10, top: 40, child: _FlightSpark(small: true)),
        const Positioned(
            left: 24, bottom: 20, child: _FlightSpark(small: true)),
        const Positioned(right: 20, bottom: 36, child: _FlightSpark()),
      ],
    );
  }
}

class _HoneyTagCell extends StatelessWidget {
  final IpTag tag;
  final String example;
  final String lang;
  final bool selected;
  final VoidCallback onTap;

  const _HoneyTagCell({
    required this.tag,
    required this.example,
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
        scale: selected ? 1.04 : 1,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: const HexagonClipper(pointy: false),
              child: Container(
                color: selected ? const Color(0xFF2A1E08) : AppColors.hexFill,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (b) => AppColors.hexIcon.createShader(
                              Rect.fromLTWH(0, 0, b.width, b.height)),
                          child: Icon(tag.icon, size: 30),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          tag.name(lang),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.neonYellow,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (example.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            example,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              height: 1.25,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Selected: gold hexagon rim + glow (hexagon-shaped, not square).
            if (selected)
              const Positioned.fill(
                child: CustomPaint(painter: _HexBorderPainter()),
              ),
            // Check badge (outside the clip so it sits on the corner).
            Positioned(
              right: 10,
              top: 4,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 160),
                scale: selected ? 1 : 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.neonGreen.withValues(alpha: 0.6),
                          blurRadius: 8),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.ctaText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold hexagon rim + soft glow drawn for a selected honeycomb tile.
class _HexBorderPainter extends CustomPainter {
  const _HexBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = const HexagonClipper(pointy: false).getClip(size);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.neonGreen.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = AppColors.cyanPurple
            .createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CenterCounter extends StatelessWidget {
  final int count;
  final String label;

  const _CenterCounter({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HexagonClipper(pointy: false),
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.cyanPurple),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ctaText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count/6',
                style: AppTextStyles.number.copyWith(
                  color: AppColors.ctaText,
                  fontSize: 22,
                  height: 1.1,
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
  final String label;
  final String hint;

  const _CustomTagInput({
    required this.controller,
    required this.onAdd,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.neonYellow,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            onSubmitted: (_) => onAdd(),
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: AppColors.neonYellow),
                onPressed: onAdd,
              ),
            ),
          ),
        ],
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
              height: 3,
              decoration: BoxDecoration(
                gradient: i == 0
                    ? const LinearGradient(
                        colors: [Color(0xFFFAA500), Color(0xFFE47701)])
                    : null,
                color: i == 0 ? null : const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(33),
              ),
            ),
          ),
          if (i != 2) const SizedBox(width: 8),
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
    final size = small ? 12.0 : 18.0;
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: AppColors.neonCyan.withValues(alpha: 0.9),
    );
  }
}
