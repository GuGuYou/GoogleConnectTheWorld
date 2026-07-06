import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
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

  @override
  void initState() {
    super.initState();
    final me = ref.read(currentUserProvider);
    _nickname = TextEditingController(text: me.nickname);
    _bio = TextEditingController(text: me.bio);
  }

  @override
  void dispose() {
    _nickname.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(currentUserProvider.notifier).updateProfile(
          nickname: _nickname.text.trim(),
          bio: _bio.text.trim(),
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);

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
            Center(child: AvatarPlaceholder(seed: me.avatarSeed, label: _nickname.text, size: 90, glow: true)),
            const SizedBox(height: 24),
            _label(ref.tr('edit_nickname')),
            _input(_nickname),
            const SizedBox(height: 16),
            _label(ref.tr('edit_bio')),
            _input(_bio, lines: 3),
            const SizedBox(height: 16),
            _label(ref.tr('edit_tags')),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, color: AppColors.neonCyan),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ref.tr('reselect_tags'),
                      style: AppTextStyles.bodyStrong,
                    ),
                  ),
                  Text('${me.tags.length}', style: AppTextStyles.caption),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
              onTap: () => context.push('/tag-select?return=${Uri.encodeComponent('/profile')}'),
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
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
