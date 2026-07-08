import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 地图气泡筛选类型
enum MapFilterTab { nearby, activity, wall }

/// 地图顶部三tab气泡筛选栏：周边 / 活动 / 留言板
///
/// 用于地图模式顶部的同好筛选，控制地图标记显示类型。
/// 依赖地图分支合并后的 Google Maps Widget 接入。
class MapFilterBar extends ConsumerWidget {
  final MapFilterTab selected;
  final ValueChanged<MapFilterTab> onChanged;

  const MapFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterTab(
            label: ref.tr('map_toggle_nearby_user'),
            icon: Icons.people_alt_outlined,
            isSelected: selected == MapFilterTab.nearby,
            onTap: () => onChanged(MapFilterTab.nearby),
          ),
          _FilterTab(
            label: ref.tr('map_toggle_activity'),
            icon: Icons.local_activity_outlined,
            isSelected: selected == MapFilterTab.activity,
            onTap: () => onChanged(MapFilterTab.activity),
          ),
          _FilterTab(
            label: ref.tr('map_toggle_wall'),
            icon: Icons.forum_outlined,
            isSelected: selected == MapFilterTab.wall,
            onTap: () => onChanged(MapFilterTab.wall),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.neonCyan, AppColors.neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
