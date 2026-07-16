import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/preset_avatars.dart';
import '../../shared/data/repositories.dart';
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

  /// 从相册选照片，转 data URI 后直接作为头像预览。
  Future<void> _pickPhoto(WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 768,
      maxHeight: 768,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final mime = file.mimeType ?? 'image/jpeg';
    ref
        .read(avatarDraftProvider.notifier)
        .setPhoto('data:$mime;base64,${base64Encode(bytes)}');
  }

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
                              final currentAvatar = ref.read(currentUserProvider).virtualAvatar;
                              final imageUrl = currentAvatar?.generatedImageUrl;
                              final isUserPreset = currentAvatar?.seed.startsWith('preset_avatar:') ?? false;
                              final presetPath = imageUrl != null && imageUrl.startsWith('asset:')
                                  ? imageUrl.substring('asset:'.length)
                                  : null;
                              if (isUserPreset && presetPath != null && PresetAvatars.isPreset(presetPath)) {
                                ref.read(avatarDraftProvider.notifier).applyGenerated(currentAvatar!);
                              } else {
                                ref
                                    .read(avatarDraftProvider.notifier)
                                    .setPresetAvatar('assets/avatars_1/avatar-1.jpg');
                              }
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
                          const SizedBox(height: 14),
                          _OptionCard(
                            icon: Icons.photo_library_outlined,
                            title: ref.tr('avatar_photo_title'),
                            desc: ref.tr('avatar_photo_desc'),
                            onTap: () => _pickPhoto(ref),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),
                          NeonButton(
                            label: ref.tr('avatar_skip_mock'),
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              // 保存当前草稿（默认=预设小男孩；导入照片后=照片）
                              ref
                                  .read(currentUserProvider.notifier)
                                  .updateVirtualAvatar(
                                      ref.read(avatarDraftProvider));
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
