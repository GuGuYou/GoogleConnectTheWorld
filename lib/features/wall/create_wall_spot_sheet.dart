import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/config/map_marker_icons.dart';
import '../../core/l10n/app_text.dart';
import '../../core/providers/location_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/map_pointer_blocker.dart';
import '../../core/utils/wall_cluster.dart';
import '../../shared/data/repositories.dart';
import '../../shared/models/ip_tag.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/ip_tag_chip.dart';
import '../../shared/widgets/neon_button.dart';
import 'wall_spot_sheet.dart';

void showCreateWallSpotSheet(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => const MapPointerBlocker(
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.fromLTRB(20, 72, 20, 108),
        child: _CreateWallSpotSheet(),
      ),
    ),
  );
}

class _CreateWallSpotSheet extends ConsumerStatefulWidget {
  const _CreateWallSpotSheet();

  @override
  ConsumerState<_CreateWallSpotSheet> createState() => _CreateWallSpotSheetState();
}

class _CreateWallSpotSheetState extends ConsumerState<_CreateWallSpotSheet> {
  final Set<String> _selectedTagIds = {};
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleTag(IpTag tag) {
    setState(() {
      if (_selectedTagIds.contains(tag.id)) {
        _selectedTagIds.remove(tag.id);
      } else {
        _selectedTagIds.add(tag.id);
      }
    });
  }

  void _create() {
    final text = _messageController.text.trim();
    if (_selectedTagIds.isEmpty || text.isEmpty) return;

    final fallback = ref.read(mapCenterProvider);
    final loc = ref.read(currentLocationProvider).valueOrNull ?? fallback;
    final me = ref.read(currentUserProvider);
    final selectedTags = me.tags.where((t) => _selectedTagIds.contains(t.id)).toList();

    final existingBefore = findSpotNear(ref.read(boardsProvider), loc.latitude, loc.longitude);
    final spot = ref.read(boardsProvider.notifier).createWallSpot(
          lat: loc.latitude,
          lng: loc.longitude,
          author: me,
          tags: selectedTags,
          content: text,
        );

    if (!mounted) return;
    Navigator.of(context).pop();

    final messenger = ScaffoldMessenger.of(context);
    if (spot == null) {
      // 内容被审核拦截
      messenger.showSnackBar(
        SnackBar(
          content: Text(ref.tr('wall_content_blocked')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (existingBefore != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ref.tr('wall_spot_exists')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(ref.tr('wall_spot_created')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    showWallSpotSheet(context, ref, spot);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider);
    final fallback = ref.watch(mapCenterProvider);
    final LatLng loc = ref.watch(currentLocationProvider).valueOrNull ?? fallback;
    final usingReal = ref.watch(usingRealLocationProvider);
    final hasMessage = _messageController.text.trim().isNotEmpty;
    final canCreate = _selectedTagIds.isNotEmpty && hasMessage;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: GlassCard(
        blur: 20,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref.tr('wall_create_title'), style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(
                        ref.tr('wall_create_subtitle'),
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 18, color: AppColors.neonCyan.withValues(alpha: 0.85)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usingReal ? ref.tr('wall_create_location_real') : ref.tr('wall_create_location_demo'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(ref.tr('wall_create_tags'), style: AppTextStyles.title.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            if (me.tags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  ref.tr('wall_create_no_tags'),
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tag in me.tags)
                    IpTagChip(
                      tag: tag,
                      selected: _selectedTagIds.contains(tag.id),
                      onTap: () => _toggleTag(tag),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Text(ref.tr('wall_create_message'), style: AppTextStyles.title.copyWith(fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 3,
              minLines: 2,
              style: AppTextStyles.body,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: ref.tr('wall_create_message_hint'),
                hintStyle: AppTextStyles.caption,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: ref.tr('wall_create_submit'),
              icon: MapMarkerIcons.wallCreate,
              onPressed: canCreate && me.tags.isNotEmpty ? _create : null,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
