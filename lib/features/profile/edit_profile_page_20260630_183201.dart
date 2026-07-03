import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/preset_avatars.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

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
    _nickname = TextEditingController(text: me.nickname);
    _bio = TextEditingController(text: me.bio);
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
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    Hero(
                      tag: 'avatar_me',
                      child: AvatarPlaceholder(seed: me.avatarSeed, label: _nickname.text, size: 90, glow: true),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(gradient: AppColors.pinkPurple, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(ref.tr('tap_change_avatar'), style: AppTextStyles.caption)),
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

  void _pickAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ref.tr('choose_avatar'), style: AppTextStyles.h2),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final path in PresetAvatars.all)
                    GestureDetector(
                      onTap: () {
                        ref.read(currentUserProvider.notifier).updateAvatar(path);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: AvatarPlaceholder(seed: path, label: '', size: 64),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, {int lines = 1}) {
    return TextField(
      controller: c,
      maxLines: lines,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.bg2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }
}
