import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../models/ip_tag.dart';

/// IP 标签 Chip：分类配色 + 可发光 + 可选中
class IpTagChip extends ConsumerWidget {
  final IpTag tag;
  final bool selected;
  final bool small;
  final bool large;
  final VoidCallback? onTap;

  const IpTagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.small = false,
    this.large = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    final color = tag.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : (small ? 8 : 12),
          vertical: large ? 12 : (small ? 4 : 7),
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.24)
              : AppColors.chipSurface,
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: color, width: 1.4) : null,
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tag.icon,
                size: large ? 20 : (small ? 12 : 15), color: color),
            SizedBox(width: large ? 8 : (small ? 4 : 6)),
            Text(
              tag.name(lang),
              style: TextStyle(
                color:
                    selected ? AppColors.textPrimary : AppColors.neonYellow,
                fontSize: large ? 16 : (small ? 11 : 13),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
