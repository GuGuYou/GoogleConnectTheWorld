import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/avatar_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/avatar_generator_repository.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/virtual_avatar.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_background.dart';
import '../../shared/widgets/neon_button.dart';
import 'widgets/virtual_avatar_view.dart';

class AvatarAiGeneratePage extends ConsumerStatefulWidget {
  final String returnLocation;
  const AvatarAiGeneratePage({super.key, this.returnLocation = '/tag-select'});

  @override
  ConsumerState<AvatarAiGeneratePage> createState() => _AvatarAiGeneratePageState();
}

class _AvatarAiGeneratePageState extends ConsumerState<AvatarAiGeneratePage> {
  // 视觉风格已统一为"光遇"式可爱治愈风，不再提供风格二选一。
  static const _style = AvatarVisualStyle.cute;
  XFile? _image;
  bool _loading = false;
  String? _prompt;
  String? _error;

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (image == null) return;
    setState(() {
      _image = image;
      _error = null;
    });
  }

  Future<void> _generate() async {
    final image = _image;
    if (image == null) {
      setState(() => _error = ref.tr('avatar_ai_no_image'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(avatarGeneratorProvider);
      final result = await repo.generate(
        AvatarGenerationRequest(
          style: _style,
          referenceImagePath: image.path,
        ),
      );
      ref.read(avatarDraftProvider.notifier).applyGenerated(result.avatar);
      setState(() {
        _prompt = result.prompt;
        _loading = false;
      });
    } on AvatarGenerationException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = ref.tr('avatar_ai_failed');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(avatarDraftProvider);
    return Scaffold(
      appBar: AppBar(title: Text(ref.tr('avatar_ai_title'))),
      body: NeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: VirtualAvatarView(avatar: avatar.copyWith(style: _style), size: 150, glow: true)),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ref.tr('avatar_ai_upload_title'), style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Text(ref.tr('avatar_ai_hint'), style: AppTextStyles.caption.copyWith(height: 1.5)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _image == null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 42, color: AppColors.neonCyan),
                                    const SizedBox(height: 10),
                                    Text(ref.tr('avatar_ai_pick_image'), style: AppTextStyles.body),
                                  ],
                                ),
                              )
                            : Image.file(File(_image!.path), fit: BoxFit.cover, width: double.infinity),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.neonPink, height: 1.4)),
              ],
              if (_prompt != null) ...[
                const SizedBox(height: 14),
                Text(_prompt!, style: AppTextStyles.caption.copyWith(height: 1.4)),
              ],
              const SizedBox(height: 22),
              NeonButton(
                label: _loading ? ref.tr('avatar_ai_generating') : ref.tr('avatar_ai_generate'),
                icon: Icons.auto_awesome,
                onPressed: _loading ? null : _generate,
              ),
              const SizedBox(height: 12),
              NeonButton(
                label: ref.tr('avatar_save_next'),
                icon: Icons.check,
                gradient: AppColors.cyanPurple,
                onPressed: () {
                  ref.read(currentUserProvider.notifier).updateVirtualAvatar(ref.read(avatarDraftProvider));
                  context.go(widget.returnLocation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
