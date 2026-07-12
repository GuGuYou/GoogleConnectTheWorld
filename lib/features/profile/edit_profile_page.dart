import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import '../avatar/widgets/virtual_avatar_view.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _nickname;
  late TextEditingController _bio;
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    final me = ref.read(currentUserProvider);
    final lang = ref.read(localeProvider).languageCode;
    _nickname = TextEditingController(text: me.name(lang));
    // 未自定义时用随语言切换的默认签名预填，避免出现空白输入框。
    _bio = TextEditingController(text: ref.read(myBioProvider));
    _selectedTags = me.tags.map((e) => e.id).toSet();
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    final allTags = MockDataSource.instance.tags;
    ref.read(currentUserProvider.notifier).updateProfile(
          nickname: _nickname.text.trim(),
          bio: _bio.text.trim(),
        );
    ref.read(currentUserProvider.notifier).updateTags(
          allTags.where((t) => _selectedTags.contains(t.id)).toList(),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final tags = MockDataSource.instance.tags;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.tr('profile_edit')),
        actions: [
          TextButton(onPressed: _save, child: Text(ref.tr('save'), style: const TextStyle(color: AppColors.neonCyan))),
        ],
      ),
      body: NeonBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: me.virtualAvatar != null
                  ? VirtualAvatarView(
                      avatar: me.virtualAvatar!, size: 90, glow: true)
                  : AvatarPlaceholder(
                      seed: me.avatarSeed,
                      label: _nickname.text,
                      size: 90,
                      glow: true),
            ),
            const SizedBox(height: 24),
            _label(ref.tr('edit_nickname')),
            _input(_nickname),
            const SizedBox(height: 16),
            _label(ref.tr('edit_bio')),
            _input(_bio, lines: 3),
            const SizedBox(height: 16),
            _label(ref.tr('edit_tags')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in tags)
                  IpTagChip(
                    tag: t,
                    selected: _selectedTags.contains(t.id),
                    onTap: () => setState(() {
                      _selectedTags.contains(t.id) ? _selectedTags.remove(t.id) : _selectedTags.add(t.id);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            NeonButton(label: ref.tr('save'), icon: Icons.check, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: AppTextStyles.bodyStrong),
      );

  Widget _input(TextEditingController c, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      style: AppTextStyles.body.copyWith(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
