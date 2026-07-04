import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/virtual_avatar_view.dart';

class AvatarSetupPage extends ConsumerWidget {
  final String returnLocation;
  const AvatarSetupPage({super.key, this.returnLocation = '/tag-select'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);
    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              GradientText(ref.tr('avatar_setup_title'), style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(ref.tr('avatar_setup_desc'), style: AppTextStyles.body),
              const SizedBox(height: 28),
              Center(child: VirtualAvatarView(avatar: avatar, size: 132, glow: true)),
              const SizedBox(height: 28),
              _OptionCard(
                icon: Icons.face_3,
                title: ref.tr('avatar_cute_title'),
                desc: ref.tr('avatar_cute_desc'),
                onTap: () {
                  ref.read(avatarDraftProvider.notifier).setStyle(AvatarVisualStyle.cute);
                  context.push('/avatar-customize?return=${Uri.encodeComponent(returnLocation)}');
                },
              ),
              const SizedBox(height: 14),
              _OptionCard(
                icon: Icons.grid_4x4,
                title: ref.tr('avatar_pixel_title'),
                desc: ref.tr('avatar_pixel_desc'),
                onTap: () {
                  ref.read(avatarDraftProvider.notifier).setStyle(AvatarVisualStyle.pixel);
                  context.push('/avatar-customize?return=${Uri.encodeComponent(returnLocation)}');
                },
              ),
              const SizedBox(height: 14),
              _OptionCard(
                icon: Icons.auto_awesome,
                title: ref.tr('avatar_ai_title'),
                desc: ref.tr('avatar_ai_desc'),
                onTap: () => context.push('/avatar-ai?return=${Uri.encodeComponent(returnLocation)}'),
              ),
              const SizedBox(height: 24),
              NeonButton(
                label: ref.tr('avatar_skip_mock'),
                icon: Icons.arrow_forward,
                onPressed: () {
                  ref.read(avatarDraftProvider.notifier).setStyle(AvatarVisualStyle.cute);
                  context.go(returnLocation);
                },
                gradient: AppColors.cyanPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(gradient: AppColors.pinkPurple, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(desc, style: AppTextStyles.caption.copyWith(height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
