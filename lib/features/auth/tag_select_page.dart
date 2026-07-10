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

  /// Packed honeycomb offsets around the center cell, in tile-size units
  /// (from the Figma frame: ±105 x, ±57/±117 y on a 125 tile).
  static const _offsets = [
    Offset(0, -0.936),
    Offset(-0.845, -0.46),
    Offset(0.845, -0.46),
    Offset(-0.845, 0.48),
    Offset(0.845, 0.48),
    Offset(0, 0.936),
  ];

  @override
  Widget build(BuildContext context) {
    final width = maxSize.width;
    final height = maxSize.height;
    final center = Offset(width / 2, height / 2);
    final tileSize =
        math.min(math.min(width / 2.75, height / 2.95), 132.0);

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: AppColors.neonPink.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipPath(
            clipper: const HexagonClipper(),
            child: Container(
              color: AppColors.hexFill,
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (b) => AppColors.hexIcon
                                .createShader(
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
                  Positioned(
                    right: 16,
                    top: 12,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: selected ? 1 : 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 13, color: AppColors.neonYellow),
                      ),
                    ),
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
  final String label;

  const _CenterCounter({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HexagonClipper(),
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
