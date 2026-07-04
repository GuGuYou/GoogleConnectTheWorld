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
import '../../shared/models/landmark.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

/// 地图视图：附近用户发光圆点 + 活动菱形 pin
class NearbyMapView extends ConsumerWidget {
  const NearbyMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final nearby = ref.watch(nearbyUsersProvider);
    final activities = ref.watch(activitiesProvider);
    final landmarks = ref.watch(landmarksProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: ClipRRect(
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
                  // 轻度去饱和 + 提亮，营造柔和淡雅的浅色地图
                  0.72, 0.20, 0.08, 0, 18,
                  0.08, 0.74, 0.18, 0, 18,
                  0.08, 0.20, 0.72, 0, 18,
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
            // 同好地标（漫展/谷子店/桌游吧/二次元咖啡）
            MarkerLayer(
              markers: [
                for (final lm in landmarks)
                  Marker(
                    point: LatLng(lm.lat, lm.lng),
                    width: 32,
                    height: 32,
                    child: GestureDetector(
                      onTap: () => _showLandmarkSheet(context, ref, lm, lang),
                      child: _LandmarkPin(type: lm.type, hasEvent: lm.hasEvent),
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
          ],
        ),
      ),
    );
  }

  void _showLandmarkSheet(BuildContext context, WidgetRef ref, dynamic lm, String lang) {
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lm.type.color.withOpacity(0.2),
                      border: Border.all(color: lm.type.color),
                    ),
                    child: Icon(lm.type.icon, color: lm.type.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lm.name(lang), style: AppTextStyles.title),
                        Text('${lm.type.label(lang)} · ${lm.distanceKm.toStringAsFixed(1)}km', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (lm.hasEvent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.neonPink, borderRadius: BorderRadius.circular(10)),
                      child: Text(lang == 'en' ? 'Event' : '有活动', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_alt, size: 16, color: AppColors.neonCyan),
                  const SizedBox(width: 6),
                  Text('${lm.fansHere} ${lang == 'en' ? 'fans nearby visited' : '位同好来过'}', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: NeonButton(
                      label: lm.visited ? (lang == 'en' ? 'Visited' : '已去过') : (lang == 'en' ? 'Been Here' : '我去过'),
                      icon: lm.visited ? Icons.check : Icons.place,
                      secondary: lm.visited,
                      gradient: AppColors.cyanPurple,
                      onPressed: () {
                        ref.read(landmarksProvider.notifier).toggleVisited(lm.id);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                  AvatarPlaceholder(seed: n.user.avatarSeed, label: n.user.nickname, size: 56, online: n.user.online),
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

class _LandmarkPin extends StatelessWidget {
  final LandmarkType type;
  final bool hasEvent;
  const _LandmarkPin({required this.type, required this.hasEvent});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg1,
        shape: BoxShape.circle,
        border: Border.all(color: type.color, width: 2),
        boxShadow: [BoxShadow(color: type.color.withValues(alpha: hasEvent ? 0.9 : 0.5), blurRadius: hasEvent ? 16 : 8)],
      ),
      child: Icon(type.icon, size: 16, color: type.color),
    );
  }
}
