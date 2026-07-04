import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/activity.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class ActivityCreatePage extends ConsumerStatefulWidget {
  const ActivityCreatePage({super.key});

  @override
  ConsumerState<ActivityCreatePage> createState() => _ActivityCreatePageState();
}

class _ActivityCreatePageState extends ConsumerState<ActivityCreatePage> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _desc = TextEditingController();
  IpTag? _tag;
  DateTime _time = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _tag = MockDataSource.instance.tags.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _publish() {
    if (_title.text.trim().isEmpty || _tag == null) {
      context.showNeonSnack(ref.tr('field_title'));
      return;
    }
    final item = ActivityItem(
      id: 'act_new_${DateTime.now().millisecondsSinceEpoch}',
      titleZh: _title.text.trim(),
      titleEn: _title.text.trim(),
      category: _tag!.category,
      tag: _tag!,
      time: _time,
      locationZh: _location.text.trim().isEmpty ? '深圳·南山' : _location.text.trim(),
      locationEn: _location.text.trim().isEmpty ? 'Shenzhen · Nanshan' : _location.text.trim(),
      lat: MockDataSource.centerLat,
      lng: MockDataSource.centerLng,
      hostId: 'me',
      descZh: _desc.text.trim().isEmpty ? '快来报名参加吧！' : _desc.text.trim(),
      descEn: _desc.text.trim().isEmpty ? 'Join us now!' : _desc.text.trim(),
      participants: 1,
      maxParticipants: 20,
      participantAvatarSeeds: const ['me_seed_42'],
      joined: true,
    );
    ref.read(activitiesProvider.notifier).create(item);
    context.pop();
    context.showNeonSnack(ref.tr('publish'));
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final tags = MockDataSource.instance.tags;

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
                    GradientText(ref.tr('create_title'), style: AppTextStyles.h2),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _label(ref.tr('field_title')),
                    _input(_title, ref.tr('field_title')),
                    const SizedBox(height: 16),
                    _label(ref.tr('field_category')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in tags.take(10))
                          IpTagChip(
                            tag: t,
                            selected: _tag?.id == t.id,
                            onTap: () => setState(() => _tag = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label(ref.tr('field_time')),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _time,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                        );
                        if (d != null) setState(() => _time = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.bg2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppColors.neonCyan),
                            const SizedBox(width: 10),
                            Text('${_time.year}-${_time.month}-${_time.day}', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label(ref.tr('field_location')),
                    _input(_location, ref.tr('field_location')),
                    const SizedBox(height: 16),
                    _label(ref.tr('field_desc')),
                    _input(_desc, ref.tr('field_desc'), lines: 4),
                    const SizedBox(height: 24),
                    NeonButton(label: ref.tr('publish'), icon: Icons.send, onPressed: _publish),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t, style: AppTextStyles.bodyStrong),
      );

  Widget _input(TextEditingController c, String hint, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.caption,
        filled: true,
        fillColor: AppColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
