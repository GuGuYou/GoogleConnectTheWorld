import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/virtual_avatar_view.dart';

class AvatarSetupPage extends ConsumerWidget {
  final String returnLocation;
  const AvatarSetupPage({super.key, this.returnLocation = '/tag-select'});

  String _next(String path) =>
      '$path?return=${Uri.encodeComponent(returnLocation)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarDraftProvider);

    return Scaffold(
      body: NeonBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(ref.tr('avatar_setup_title'),
                              style: AppTextStyles.h1),
                          const SizedBox(height: 8),
                          Text(ref.tr('avatar_setup_desc'),
                              style: AppTextStyles.body),
                          const SizedBox(height: 28),

                          // Framed live avatar preview
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.neonYellow
                                        .withValues(alpha: 0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.glowOrange
                                        .withValues(alpha: 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: VirtualAvatarView(avatar: avatar, size: 136),
                            ),
                          ),
                          const SizedBox(height: 32),

                          _OptionCard(
                            icon: Icons.tune_rounded,
                            title: ref.tr('avatar_cute_title'),
                            desc: ref.tr('avatar_cute_desc'),
                            primary: true,
                            onTap: () {
                              ref
                                  .read(avatarDraftProvider.notifier)
                                  .setStyle(AvatarVisualStyle.cute);
                              context.push(_next('/avatar-customize'));
                            },
                          ),
                          const SizedBox(height: 14),
                          _OptionCard(
                            icon: Icons.auto_awesome,
                            title: ref.tr('avatar_ai_title'),
                            desc: ref.tr('avatar_ai_desc'),
                            onTap: () => context.push(_next('/avatar-ai')),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),
                          NeonButton(
                            label: ref.tr('avatar_skip_mock'),
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              ref
                                  .read(avatarDraftProvider.notifier)
                                  .setStyle(AvatarVisualStyle.cute);
                              context.go(returnLocation);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
  final bool primary;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor:
          primary ? AppColors.neonYellow.withValues(alpha: 0.45) : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
                gradient: AppColors.cyanPurple, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.ctaText, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(desc,
                    style: AppTextStyles.caption.copyWith(height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
