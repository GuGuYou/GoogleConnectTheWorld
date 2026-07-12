import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/avatar/widgets/virtual_avatar_view.dart';
import '../../shared/data/repositories.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/gold_glow.dart';
import '../../shared/widgets/gradient_text.dart';
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
    final displayName = me.name(ref.watch(localeProvider).languageCode);

    return NeonBackground(
      child: Stack(
        children: [
          // Frame 25 spec: scattered gold star dots + sparkles instead of
          // the old constellation art.
          const _Spark(right: 90, top: 66, size: 3, alpha: 0.35),
          const _Spark(right: 46, top: 120, size: 4, alpha: 0.8),
          const _Spark(right: 120, top: 200, size: 3, alpha: 0.9),
          const _Spark(left: 120, top: 130, size: 3, alpha: 0.3),
          const Positioned(
            right: 64,
            top: 88,
            child: Icon(Icons.auto_awesome, size: 13, color: Color(0xFFFDD570)),
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
                // Hero — avatar framed by the spec's double #FFC201 hairline
                // rings (inner crisp ring + faint outer ring).
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFC201)
                                    .withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFC201)
                                    .withValues(alpha: 0.85),
                                width: 0.6,
                              ),
                            ),
                            child: me.virtualAvatar != null
                                ? VirtualAvatarView(
                                    avatar: me.virtualAvatar!,
                                    size: 96,
                                    online: true)
                                : AvatarPlaceholder(
                                    seed: me.avatarSeed,
                                    label: displayName,
                                    size: 96,
                                    online: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GradientText(displayName, style: AppTextStyles.h1),
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
                // 数据卡（Frame 25 金色描边面板）
                _GoldPanel(
                  overlayCenter: const Alignment(0.55, -1.0),
                  overlayOpacity: 0.16,
                  child: Padding(
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
                ),
                const SizedBox(height: 14),
                // 功能入口
                _GoldPanel(
                  overlayCenter: const Alignment(0, -1.05),
                  overlayOpacity: 0.09,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      children: _withDividers([
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
                      ]),
                    ),
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

  /// 行间插入 Frame 25 规格的 #564013 1px 分隔线。
  List<Widget> _withDividers(List<Widget> entries) {
    final out = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      out.add(entries[i]);
      if (i != entries.length - 1) {
        out.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: const Color(0xFF564013).withValues(alpha: 0.55),
        ));
      }
    }
    return out;
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style: AppTextStyles.number
                  .copyWith(fontSize: 20, color: AppColors.neonYellow)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF422D0C),
    );
  }
}

/// Frame 25 gold-chrome panel: translucent surface, 1px gradient border
/// with a top sheen, and a soft #FFC000 radial wash.
class _GoldPanel extends StatelessWidget {
  final Widget child;
  final Alignment overlayCenter;
  final double overlayOpacity;

  const _GoldPanel({
    required this.child,
    required this.overlayCenter,
    required this.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const GoldCardBorderPainter(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: AppColors.cardSurface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: overlayCenter,
                    radius: 1.1,
                    colors: [
                      const Color(0xFFFFC000)
                          .withValues(alpha: overlayOpacity),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Gold sparkle dot decoration (Frame 25 scattered stars).
class _Spark extends StatelessWidget {
  final double? left;
  final double? right;
  final double top;
  final double size;
  final double alpha;

  const _Spark({
    this.left,
    this.right,
    required this.top,
    required this.size,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5CA4B).withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5CA4B).withValues(alpha: alpha * 0.8),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hexagonal icon tile per the Frame 25 spec: dimmed outlined hexagon
/// (32x36.5, 30% fill/stroke) holding a #FFD48F→#FF7017 gradient icon.
/// Used for the settings button and entry leading icons.
class _HexIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _HexIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlowHexagon(
        width: 32,
        height: 36.5,
        strokeWidth: 0.5,
        fillOpacity: 0.3,
        strokeOpacity: 0.35,
        glowOpacity: 0.22,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (b) => const LinearGradient(
            colors: [Color(0xFFFFD48F), Color(0xFFFF7017)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
          child: Icon(icon, size: 17),
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
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _HexIconButton(icon: icon),
            const SizedBox(width: 14),
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
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFD98A), Color(0xFFE0951F)]),
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
