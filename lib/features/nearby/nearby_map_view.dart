import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/map_config.dart';
import '../../core/config/map_marker_icons.dart';
import '../../core/l10n/app_text.dart';
import '../../core/providers/location_provider.dart';
import '../../core/utils/distance.dart';
import '../../core/utils/google_maps_ready.dart';
import '../../core/utils/map_icon_bitmap.dart';
import '../../core/utils/radar_center_marker.dart';
import '../../core/utils/wall_bubble_marker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/models/activity.dart';
import '../../shared/models/wall_spot.dart';
import '../wall/create_wall_spot_sheet.dart';
import '../wall/wall_spot_sheet.dart';
import '../avatar/widgets/virtual_avatar_view.dart';
import '../../shared/widgets/avatar_placeholder.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';

/// 地图容器圆角，与 [ClipRRect] 及底部遮罩保持一致。
const _kMapCornerRadius = 20.0;

/// 底部遮罩高度：覆盖 Google 归属信息，并容纳留言板分类标签。
const _kMapBottomMaskHeight = 80.0;

/// 地图视图：Google Maps + 附近用户光点 + 活动 pin + 异步留言墙（Lobby 系统）。
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
    final wallSpots = ref.watch(visibleWallSpotsProvider);
    final me = ref.watch(currentUserProvider);

    final circles = <Circle>{
      ...RadarCenterMarker.rings(center),
    };

    final maxKm = MapConfig.radarMaxRangeKm;
    final centerLat = center.latitude;
    final centerLng = center.longitude;
    final nearbyInRange = nearby
        .where((n) => isWithinKm(centerLat, centerLng, n.user.lat, n.user.lng, maxKm))
        .take(30)
        .toList();
    final activitiesInRange = activities
        .where((a) => isWithinKm(centerLat, centerLng, a.lat, a.lng, maxKm))
        .take(12)
        .toList();

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
          // 地图区域占满剩余空间（分类标签已移入地图底部遮罩）
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_kMapCornerRadius),
                  child: _DeferredGoogleMap(
                    key: ValueKey(Object.hash(
                      MapMarkerIcons.activity.codePoint,
                      MapMarkerIcons.wallMessage.codePoint,
                      MapMarkerIcons.nearbyUser.codePoint,
                    )),
                    center: center,
                    circles: circles,
                    nearbyUsers: nearbyInRange,
                    activities: activitiesInRange,
                    wallSpots: wallSpots,
                    userTags: me.tags,
                    onUserTap: (n) => _showUserSheet(context, ref, n),
                    onWallSpotTap: (spot) => showWallSpotSheet(context, ref, spot),
                    onCreateBoard: me.tags.isNotEmpty
                        ? () => showCreateWallSpotSheet(context, ref)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserSheet(BuildContext context, WidgetRef ref, UserWithDistance n) {
    // 预留底部导航栏高度 (64) + 系统手势条高度，避免与底部 Tab 重叠
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const navBarHeight = 64.0;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + navBarHeight + bottomInset),
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
              Wrap(spacing: 8, runSpacing: 8, children: [for (final t in n.user.tags.take(4)) IpTagChip(tag: t)]),
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

class _CreateWallSpotButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _CreateWallSpotButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.cyanPurple,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.5),
                blurRadius: 16,
              ),
              BoxShadow(
                color: AppColors.neonYellow.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_location_alt, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                ref.tr('wall_create_btn'),
                style: AppTextStyles.button.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 地图底部遮罩：遮挡 Google 归属信息，并承载留言板分类筛选。
class _MapBottomMask extends ConsumerWidget {
  final List<IpTag> tags;

  const _MapBottomMask({required this.tags});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagFilter = ref.watch(wallTagFilterProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(_kMapCornerRadius),
        bottomRight: Radius.circular(_kMapCornerRadius),
      ),
      child: Container(
        height: _kMapBottomMaskHeight,
        color: AppColors.bg0,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        alignment: Alignment.centerLeft,
        child: tags.isEmpty
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tag in tags)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IpTagChip(
                          tag: tag,
                          large: true,
                          selected: tagFilter == tag,
                          onTap: () {
                            ref.read(wallTagFilterProvider.notifier).update(
                                  (current) => current == tag ? null : tag,
                                );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Web 上等待 Google Maps JS SDK 就绪后再渲染，避免 ROADMAP undefined 崩溃。
class _DeferredGoogleMap extends StatefulWidget {
  final LatLng center;
  final Set<Circle> circles;
  final List<UserWithDistance> nearbyUsers;
  final List<ActivityItem> activities;
  final List<WallSpot> wallSpots;
  final List<IpTag> userTags;
  final void Function(UserWithDistance user) onUserTap;
  final void Function(WallSpot spot) onWallSpotTap;
  final VoidCallback? onCreateBoard;

  const _DeferredGoogleMap({
    super.key,
    required this.center,
    required this.circles,
    required this.nearbyUsers,
    required this.activities,
    required this.wallSpots,
    required this.userTags,
    required this.onUserTap,
    required this.onWallSpotTap,
    this.onCreateBoard,
  });

  @override
  State<_DeferredGoogleMap> createState() => _DeferredGoogleMapState();
}

class _DeferredGoogleMapState extends State<_DeferredGoogleMap> {
  late final Future<bool> _ready = waitForGoogleMapsReady();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _showActivities = true;
  bool _showNearbyUsers = true;
  bool _showWallSpots = true;

  CameraPosition get _homeCamera => CameraPosition(
        target: widget.center,
        zoom: MapConfig.initialZoomForLatitude(widget.center.latitude),
      );

  Future<void> _recenterMap() async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_homeCamera));
  }

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void didUpdateWidget(covariant _DeferredGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallSpots != widget.wallSpots ||
        oldWidget.userTags != widget.userTags ||
        oldWidget.activities != widget.activities ||
        oldWidget.nearbyUsers != widget.nearbyUsers ||
        oldWidget.center != widget.center) {
      _loadMarkers();
    }
  }

  Future<void> _loadMarkers() async {
    // 改 map_marker_icons.dart 后清缓存，避免热重载仍显示旧图标
    MapIconBitmap.clearCache();
    RadarCenterMarker.clearCache();
    WallBubbleMarker.clearCache();

    final markers = <Marker>{};

    final radarIcon = await RadarCenterMarker.icon();
    markers.add(
      Marker(
        markerId: const MarkerId('me_radar'),
        position: widget.center,
        icon: radarIcon,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 10,
      ),
    );

    final activityIcon = await MapIconBitmap.pin(
      icon: MapMarkerIcons.activity,
      color: MapMarkerIcons.activityColor,
    );
    if (_showActivities) {
      for (final a in widget.activities) {
        markers.add(
          Marker(
            markerId: MarkerId('activity_${a.id}'),
            position: LatLng(a.lat, a.lng),
            icon: activityIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () {
              if (!mounted) return;
              context.push('/activity/${a.id}');
            },
          ),
        );
      }
    }

    if (_showNearbyUsers) {
      for (final n in widget.nearbyUsers) {
        final color = n.user.tags.isNotEmpty ? n.user.tags.first.color : AppColors.neonCyan;
        final userIcon = await MapIconBitmap.pin(
          icon: MapMarkerIcons.nearbyUser,
          color: color,
          size: 44,
          iconSize: 22,
        );
        markers.add(
          Marker(
            markerId: MarkerId('user_${n.user.id}'),
            position: LatLng(n.user.lat, n.user.lng),
            icon: userIcon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => widget.onUserTap(n),
          ),
        );
      }
    }

    if (_showWallSpots) {
      for (final spot in widget.wallSpots) {
        final color = spot.displayTag(widget.userTags).color;
        final icon = await WallBubbleMarker.iconFor(color);
        markers.add(
          Marker(
            markerId: MarkerId('wall_${spot.id}'),
            position: LatLng(spot.lat, spot.lng),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            onTap: () => widget.onWallSpotTap(spot),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _ready,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
        }
        if (snap.data != true) {
          return const _MapFallback(messageKey: 'map_load_error');
        }
        return Stack(
          children: [
            GoogleMap(
              style: MapConfig.mapStyle,
              initialCameraPosition: _homeCamera,
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              circles: widget.circles,
              markers: _markers,
            ),
            // 底部遮罩：Google 归属信息 + 留言板分类标签
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MapBottomMask(tags: widget.userTags),
            ),
            // "New Board" 按钮：浮于遮罩上方的地图区域
            if (widget.onCreateBoard != null)
              Positioned(
                right: 14,
                bottom: _kMapBottomMaskHeight + 14,
                child: _CreateWallSpotButton(
                  onPressed: widget.onCreateBoard!,
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RecenterMapButton(onPressed: _recenterMap),
                  const SizedBox(height: 8),
                  _MapLayerToggle(
                    icon: MapMarkerIcons.activity,
                    color: MapMarkerIcons.activityColor,
                    tooltipKey: 'map_toggle_activity',
                    enabled: _showActivities,
                    onChanged: (value) {
                      setState(() => _showActivities = value);
                      _loadMarkers();
                    },
                  ),
                  const SizedBox(height: 6),
                  _MapLayerToggle(
                    icon: MapMarkerIcons.nearbyUser,
                    color: AppColors.neonCyan,
                    tooltipKey: 'map_toggle_nearby_user',
                    enabled: _showNearbyUsers,
                    onChanged: (value) {
                      setState(() => _showNearbyUsers = value);
                      _loadMarkers();
                    },
                  ),
                  const SizedBox(height: 6),
                  _MapLayerToggle(
                    icon: MapMarkerIcons.wallMessage,
                    color: MapMarkerIcons.wallDefaultColor,
                    tooltipKey: 'map_toggle_wall',
                    enabled: _showWallSpots,
                    onChanged: (value) {
                      setState(() => _showWallSpots = value);
                      _loadMarkers();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

BoxDecoration _mapControlDecoration({
  required Color glowColor,
  required bool active,
}) {
  return BoxDecoration(
    color: const Color(0xCC171308),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: active ? glowColor.withValues(alpha: 0.7) : AppColors.glassBorder.withValues(alpha: 0.35),
      width: active ? 1.5 : 1,
    ),
    boxShadow: active
        ? [
            BoxShadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 16),
            BoxShadow(
              color: AppColors.neonYellow.withValues(alpha: 0.14),
              blurRadius: 22,
              offset: const Offset(0, 6),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.neonYellow.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
  );
}

class _MapLayerToggle extends ConsumerWidget {
  final IconData icon;
  final Color color;
  final String tooltipKey;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _MapLayerToggle({
    required this.icon,
    required this.color,
    required this.tooltipKey,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: ref.tr(tooltipKey),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!enabled),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: _mapControlDecoration(glowColor: color, active: enabled),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecenterMapButton extends ConsumerWidget {
  final VoidCallback onPressed;
  const _RecenterMapButton({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: ref.tr('map_recenter'),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: _mapControlDecoration(glowColor: AppColors.neonCyan, active: true),
            child: const Icon(Icons.my_location, size: 22, color: AppColors.neonCyan),
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
        borderRadius: BorderRadius.circular(_kMapCornerRadius),
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


