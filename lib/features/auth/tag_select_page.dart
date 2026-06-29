import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class TagSelectPage extends ConsumerStatefulWidget {
  const TagSelectPage({super.key});

  @override
  ConsumerState<TagSelectPage> createState() => _TagSelectPageState();
}

class _TagSelectPageState extends ConsumerState<TagSelectPage> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final allTags = MockDataSource.instance.tags;
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
                    for (final cat in kTagCategories)
                      if (byCat[cat.key] != null) ...[
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
                            for (final t in byCat[cat.key]!)
                              IpTagChip(
                                tag: t,
                                selected: _selected.contains(t.id),
                                onTap: () => setState(() {
                                  _selected.contains(t.id)
                                      ? _selected.remove(t.id)
                                      : _selected.add(t.id);
                                }),
                              ),
                          ],
                        ),
                      ],
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
                              ref.read(currentUserProvider.notifier).updateTags(tags);
                              ref.read(authProvider.notifier).login();
                              context.go('/discover');
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
