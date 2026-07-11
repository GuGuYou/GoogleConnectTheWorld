import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/avatar/widgets/virtual_avatar_view.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/hexagon.dart';
import '../../shared/widgets/neon_background.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(currentUserProvider);
    final myActivities =
        ref.watch(activitiesProvider).where((a) => a.joined).length;
    final friendCount = ref.watch(friendsProvider).length;
    final unread = ref.watch(unreadTotalProvider);
    final bio = ref.watch(myBioProvider);

    return NeonBackground(
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -40,
            child: Opacity(
              opacity: 0.55,
              child: Image.asset(
                'assets/images/decorations/fig_constellation.png',
                width: 225,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _HexIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/profile/settings'),
                    ),
                  ],
                ),
                // Hero
                Center(
                  child: Column(
                    children: [
                      me.virtualAvatar != null
                          ? VirtualAvatarView(
                              avatar: me.virtualAvatar!,
                              size: 96,
                              glow: true,
                              online: true)
                          : AvatarPlaceholder(
                              seed: me.avatarSeed,
                              label: me.nickname,
                              size: 96,
                              glow: true,
                              online: true),
                      const SizedBox(height: 14),
                      GradientText(me.nickname, style: AppTextStyles.h1),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('ID: ${me.id} · ${me.city}',
                              style: AppTextStyles.caption),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 12, color: AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 简介可就地点击编辑
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showBioEditor(context, ref, bio),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  bio,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(top: 3),
                                child: Icon(Icons.edit_outlined,
                                    size: 14, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // 数据卡
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _stat('${me.tags.length}', ref.tr('edit_tags')),
                        _vDivider(),
                        _stat('$myActivities', ref.tr('profile_activities')),
                        _vDivider(),
                        _stat('${me.matchRate(me.tags) > 0 ? 99 : 88}',
                            ref.tr('match_rate')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // 功能入口
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Column(
                    children: [
                      _Entry(
                        icon: Icons.chat_bubble_outline,
                        label: ref.tr('profile_messages'),
                        sublabel: ref.tr('profile_messages_sub'),
                        badge: unread,
                        onTap: () => context.push('/chat'),
                      ),
                      _Entry(
                        icon: Icons.group_outlined,
                        label: ref.tr('profile_friends'),
                        sublabel:
                            '$friendCount · ${ref.tr('profile_friends_sub')}',
                        onTap: () => context.push('/friends'),
                      ),
                      _Entry(
                        icon: Icons.edit_outlined,
                        label: ref.tr('profile_edit'),
                        sublabel: ref.tr('profile_edit_sub'),
                        onTap: () => context.push('/profile/edit'),
                      ),
                      _Entry(
                        icon: Icons.face_retouching_natural,
                        label: ref.tr('avatar_recreate'),
                        sublabel: ref.tr('profile_avatar_sub'),
                        onTap: () =>
                            context.push('/avatar-setup?return=/profile'),
                      ),
                      _Entry(
                        icon: Icons.celebration_outlined,
                        label: ref.tr('profile_activities'),
                        sublabel: ref.tr('profile_activities_sub'),
                        onTap: () => context.push('/activity'),
                      ),
                      _Entry(
                        icon: Icons.settings_outlined,
                        label: ref.tr('profile_settings'),
                        sublabel: ref.tr('profile_settings_sub'),
                        onTap: () => context.push('/profile/settings'),
                      ),
                      _Entry(
                        icon: Icons.info_outline,
                        label: ref.tr('setting_about'),
                        sublabel: ref.tr('profile_about_sub'),
                        onTap: () => context.push('/profile/about'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 就地编辑个性签名（底部弹层，直接写回 currentUserProvider）。
  void _showBioEditor(BuildContext context, WidgetRef ref, String current) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BioEditorSheet(
        initial: current,
        title: ref.tr('edit_bio'),
        hint: ref.tr('profile_bio_hint'),
        saveLabel: ref.tr('save'),
        cancelLabel: ref.tr('cancel'),
        onSave: (text) =>
            ref.read(currentUserProvider.notifier).updateProfile(bio: text),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.number),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.divider,
    );
  }
}

/// Hexagonal icon tile used for the settings button and entry leading icons.
class _HexIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HexIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: const HexagonClipper(),
        child: Container(
          width: 37,
          height: 37,
          color: AppColors.hexFill.withValues(alpha: 0.3),
          child: Icon(icon, size: 18, color: AppColors.neonYellow),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  final int badge;

  const _Entry({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            _HexIconButton(icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.title),
                  const SizedBox(height: 2),
                  Text(sublabel, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                constraints: const BoxConstraints(minWidth: 20),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(
                  gradient: AppColors.pinkPurple,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.ctaText,
                      fontWeight: FontWeight.w800,
                      fontSize: 11),
                ),
              ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// 底部弹层的个性签名编辑器。
class _BioEditorSheet extends StatefulWidget {
  final String initial;
  final String title;
  final String hint;
  final String saveLabel;
  final String cancelLabel;
  final ValueChanged<String> onSave;

  const _BioEditorSheet({
    required this.initial,
    required this.title,
    required this.hint,
    required this.saveLabel,
    required this.cancelLabel,
    required this.onSave,
  });

  @override
  State<_BioEditorSheet> createState() => _BioEditorSheetState();
}

class _BioEditorSheetState extends State<_BioEditorSheet> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(widget.title, style: AppTextStyles.title),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              maxLines: 3,
              maxLength: 60,
              style: AppTextStyles.body.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: AppColors.inputFill,
                counterStyle: AppTextStyles.caption,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.cancelLabel,
                        style: AppTextStyles.button
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.onSave(_c.text.trim());
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.pinkPurple,
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Text(widget.saveLabel,
                          style: AppTextStyles.button
                              .copyWith(color: AppColors.ctaText)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
