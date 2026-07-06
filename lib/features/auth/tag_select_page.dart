import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class TagSelectPage extends ConsumerStatefulWidget {
  final String returnLocation;
  const TagSelectPage({super.key, this.returnLocation = '/space'});

  @override
  ConsumerState<TagSelectPage> createState() => _TagSelectPageState();
}

class _TagSelectPageState extends ConsumerState<TagSelectPage> {
  final Set<String> _selected = {};
  final Map<String, IpTag> _customTags = {};
  final Map<String, TextEditingController> _customInputs = {};
  final _globalInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final cat in kTagCategories) {
      _customInputs[cat.key] = TextEditingController();
    }
    if (widget.returnLocation == '/profile') {
      final presetIds = MockDataSource.instance.tags.map((tag) => tag.id).toSet();
      for (final tag in ref.read(currentUserProvider).tags) {
        _selected.add(tag.id);
        if (!presetIds.contains(tag.id)) {
          _customTags[tag.id] = tag;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _customInputs.values) {
      controller.dispose();
    }
    _globalInput.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
    });
  }

  void _addCustomTag(String category, TextEditingController controller, {bool global = false}) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    final id = 'custom_${category}_${value.hashCode.abs()}';
    final tag = IpTag(
      id: id,
      nameZh: value,
      nameEn: value,
      category: category,
      icon: global ? Icons.tag : Icons.add_circle_outline,
    );
    setState(() {
      _customTags[id] = tag;
      _selected.add(id);
      controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final allTags = [...MockDataSource.instance.tags, ..._customTags.values];
    final byCat = <String, List<IpTag>>{};
    for (final t in allTags) {
      byCat.putIfAbsent(t.category, () => []).add(t);
    }
    final enough = _selected.length >= 3;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GradientText(ref.tr('tag_select_title'), style: AppTextStyles.h1),
                    const SizedBox(height: 8),
                    Text(ref.tr('tag_select_desc'), style: AppTextStyles.body),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    for (final cat in kTagCategories) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 10),
                        child: Row(
                          children: [
                            Container(width: 4, height: 16, color: cat.color),
                            const SizedBox(width: 8),
                            Text(cat.name(lang), style: AppTextStyles.title),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final t in byCat[cat.key] ?? const <IpTag>[])
                            IpTagChip(
                              tag: t,
                              selected: _selected.contains(t.id),
                              onTap: () => _toggle(t.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _CustomTagInput(
                        controller: _customInputs[cat.key]!,
                        hint: ref.tr('custom_tag_category_hint'),
                        onAdd: () => _addCustomTag(cat.key, _customInputs[cat.key]!),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(ref.tr('custom_tag_global_title'), style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Text(ref.tr('custom_tag_global_desc'), style: AppTextStyles.caption.copyWith(height: 1.5)),
                    const SizedBox(height: 10),
                    _CustomTagInput(
                      controller: _globalInput,
                      hint: ref.tr('custom_tag_global_hint'),
                      onAdd: () => _addCustomTag('custom', _globalInput, global: true),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final t in byCat['custom'] ?? const <IpTag>[])
                          IpTagChip(
                            tag: t,
                            selected: _selected.contains(t.id),
                            onTap: () => _toggle(t.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${ref.tr('tag_selected')}: ${_selected.length}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 10),
                    NeonButton(
                      label: ref.tr('enter_app'),
                      icon: Icons.auto_awesome,
                      onPressed: enough
                          ? () {
                              final tags = allTags.where((t) => _selected.contains(t.id)).toList();
                              final avatar = ref.read(currentUserProvider).virtualAvatar;
                              if (avatar == null) {
                                context.go('/avatar-setup');
                                return;
                              }
                              ref.read(currentUserProvider.notifier).updateTags(tags);
                              ref.read(authProvider.notifier).login();
                              context.go(widget.returnLocation);
                            }
                          : null,
                    ),
                  ],
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
  final String hint;
  final VoidCallback onAdd;

  const _CustomTagInput({
    required this.controller,
    required this.hint,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: AppTextStyles.bodyStrong,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: InputDecoration(hintText: hint),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
