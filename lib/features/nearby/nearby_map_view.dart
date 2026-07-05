import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/map_config.dart';
import '../../core/l10n/app_text.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../avatar/widgets/virtual_avatar_view.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

/// 地图视图：Google Maps + 附近用户光点 + 活动 pin。
class NearbyMapView extends ConsumerWidget {
  const NearbyMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!MapConfig.hasValidApiKey) {
      return const _MapFallback(messageKey: 'map_key_missing');
    }

    final fallback = ref.watch(mapCenterProvider);
    final LatLng center = ref.watch(currentLocationProvider).valueOrNull ?? fallback;
    final usingReal = ref.watch(usingRealLocationProvider);
    final nearby = ref.watch(nearbyUsersProvider);
    final activities = ref.watch(activitiesProvider);

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('me'),
        center: center,
        radius: 80,
        fillColor: AppColors.neonCyan.withValues(alpha: 0.35),
        strokeColor: AppColors.neonCyan,
        strokeWidth: 2,
      ),
      for (final n in nearby.take(30))
        Circle(
          circleId: CircleId('user_${n.user.id}'),
          center: LatLng(n.user.lat, n.user.lng),
          radius: 60,
          fillColor: n.user.tags.first.color.withValues(alpha: 0.45),
          strokeColor: n.user.tags.first.color,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showUserSheet(context, ref, n),
        ),
    };

    final markers = <Marker>{
      for (final a in activities.take(12))
        Marker(
          markerId: MarkerId('activity_${a.id}'),
          position: LatLng(a.lat, a.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          onTap: () => context.push('/activity/${a.id}'),
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: Column(
        children: [
          if (!usingReal)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                ref.tr('location_fallback_hint'),
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                style: MapConfig.neonDarkMapStyle,
                initialCameraPosition: CameraPosition(target: center, zoom: 13),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                circles: circles,
                markers: markers,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSheet(BuildContext context, WidgetRef ref, UserWithDistance n) {
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

class _MapFallback extends ConsumerWidget {
  final String messageKey;
  const _MapFallback({required this.messageKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: AppColors.bg2,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar, size: 64, color: AppColors.neonCyan.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ref.tr(messageKey),
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
