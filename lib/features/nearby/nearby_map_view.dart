import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/mock_data_source.dart';
import '../../shared/data/repositories.dart';
import '../avatar/widgets/virtual_avatar_view.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';
import '../../shared/widgets/whisper_sheets.dart';

/// 地图视图：附近用户发光圆点 + 活动菱形 pin + 异步留言（Whisper）光点
class NearbyMapView extends ConsumerWidget {
  const NearbyMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final nearby = ref.watch(nearbyUsersProvider);
    final activities = ref.watch(activitiesProvider);
    final whispers = ref.watch(whispersProvider);
    final me = ref.watch(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(MockDataSource.centerLat, MockDataSource.centerLng),
                initialZoom: 13,
                minZoom: 10,
                maxZoom: 17,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nichetribe.demo',
                  tileBuilder: (context, widget, tile) => ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      // 反色 + 偏紫，营造暗色赛博地图
                      -0.8, 0, 0, 0, 255,
                      0, -0.8, 0, 0, 255,
                      0, 0, -0.7, 0, 255,
                      0, 0, 0, 1, 0,
                    ]),
                    child: widget,
                  ),
                ),
                // 当前用户
                const MarkerLayer(markers: [
                  Marker(
                    point: LatLng(MockDataSource.centerLat, MockDataSource.centerLng),
                    width: 28,
                    height: 28,
                    child: _MeDot(),
                  ),
                ]),
                // 附近用户
                MarkerLayer(
                  markers: [
                    for (final n in nearby.take(30))
                      Marker(
                        point: LatLng(n.user.lat, n.user.lng),
                        width: 34,
                        height: 34,
                        child: GestureDetector(
                          onTap: () => _showUserSheet(context, ref, n, lang),
                          child: _UserDot(color: n.user.tags.first.color),
                        ),
                      ),
                  ],
                ),
                // 活动 pin
                MarkerLayer(
                  markers: [
                    for (final a in activities.take(12))
                      Marker(
                        point: LatLng(a.lat, a.lng),
                        width: 30,
                        height: 30,
                        child: GestureDetector(
                          onTap: () => context.push('/activity/${a.id}'),
                          child: _ActivityPin(color: a.tag.color),
                        ),
                      ),
                  ],
                ),
                // 异步留言（Whisper）光点
                MarkerLayer(
                  markers: [
                    for (final w in whispers.take(40))
                      Marker(
                        point: LatLng(w.lat, w.lng),
                        width: 26,
                        height: 26,
                        child: GestureDetector(
                          onTap: () => showWhisperDetailSheet(context, ref, w, lang),
                          child: const _WhisperDot(),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // 留言列表 + 发布入口
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _MapRoundButton(
                  icon: Icons.local_florist,
                  onTap: () => showWhisperFeedSheet(context, ref, lang),
                ),
                const SizedBox(height: 10),
                _MapRoundButton(
                  icon: Icons.edit_note_rounded,
                  primary: true,
                  onTap: () => showComposeWhisperSheet(context, ref, me.lat, me.lng),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSheet(BuildContext context, WidgetRef ref, UserWithDistance n, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: GlassCard(
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  n.user.virtualAvatar != null
                      ? VirtualAvatarView(avatar: n.user.virtualAvatar!, size: 56, online: n.user.online)
                      : AvatarPlaceholder(seed: n.user.avatarSeed, label: n.user.nickname, size: 56, online: n.user.online),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.user.nickname, style: AppTextStyles.title),
                        Text('${ref.tr('match_rate')} ${n.matchRate}%', style: AppTextStyles.caption.copyWith(color: AppColors.neonPink)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in n.user.tags.take(4)) IpTagChip(tag: t, small: true)]),
              const SizedBox(height: 16),
              NeonButton(
                label: ref.tr('say_hi'),
                icon: Icons.waving_hand,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/chat/conv_${n.user.id}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.neonCyan,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.8), blurRadius: 18)],
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  final Color color;
  const _UserDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.9),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 12)],
      ),
      child: const Icon(Icons.person, size: 16, color: Colors.white),
    );
  }
}

class _ActivityPin extends StatelessWidget {
  final Color color;
  const _ActivityPin({required this.color});
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785398, // 45°
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 12)],
        ),
        child: Transform.rotate(
          angle: -0.785398,
          child: const Icon(Icons.celebration, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

/// 异步留言光点：柔光治愈风的小光晕，区别于用户圆点 / 活动菱形 pin。
class _WhisperDot extends StatelessWidget {
  const _WhisperDot();
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFFFD9EC); // 光遇风柔粉光晕
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.15)]),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.85), blurRadius: 14, spreadRadius: 1)],
      ),
      child: const Icon(Icons.auto_awesome, size: 13, color: Color(0xFF6B3B5C)),
    );
  }
}

/// 地图右下角圆形悬浮按钮（留言列表 / 发布留言 入口）。
class _MapRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const _MapRoundButton({required this.icon, required this.onTap, this.primary = false});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: primary ? 52 : 42,
        height: primary ? 52 : 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: primary ? AppColors.pinkPurple : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.12),
          boxShadow: primary ? [BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.55), blurRadius: 16)] : null,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
        ),
        child: Icon(icon, color: Colors.white, size: primary ? 24 : 19),
      ),
    );
  }
}
