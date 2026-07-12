import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';

class AvatarCustomizePage extends ConsumerWidget {
  final String returnLocation;
  const AvatarCustomizePage({super.key, this.returnLocation = '/tag-select'});

  static const _avatars = [
    'assets/avatars_1/avatar-1.jpg',
    'assets/avatars_1/avatar-2.jpg',
    'assets/avatars_1/avatar-3.jpg',
    'assets/avatars_1/avatar-4.jpg',
    'assets/avatars_1/avatar-5.jpg',
    'assets/avatars_1/avatar-6.jpg',
    'assets/avatars_1/avatar-7.jpg',
  ];

  int _selectedIndex(VirtualAvatar avatar) {
    final url = avatar.generatedImageUrl;
    if (url == null || !url.startsWith('asset:')) return 0;
    final idx = _avatars.indexOf(url.substring('asset:'.length));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    final selected = _selectedIndex(avatar);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GradientText(
          ref.tr('avatar_customize_title'),
          style: AppTextStyles.h2,
        ),
      ),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Center(
                child: ClipOval(
                  child: Image.asset(
                    _avatars[selected],
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                ref.tr('avatar_preset_desc'),
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _avatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _PresetAvatarTile(
                      asset: _avatars[index],
                      selected: selected == index,
                      onTap: () => ref.read(avatarDraftProvider.notifier).setPresetAvatar(_avatars[index]),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              NeonButton(
                label: ref.tr('avatar_save_next'),
                icon: Icons.check,
                onPressed: () {
                  ref.read(currentUserProvider.notifier).updateVirtualAvatar(ref.read(avatarDraftProvider));
                  context.go(returnLocation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetAvatarTile extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _PresetAvatarTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.neonGreen : AppColors.glassBorder,
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.35), blurRadius: 16)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(asset, fit: BoxFit.cover),
              if (selected)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 18, color: AppColors.ctaText),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
