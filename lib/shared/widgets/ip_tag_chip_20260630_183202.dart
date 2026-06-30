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
  final VoidCallback? onTap;

  const IpTagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.small = false,
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
          horizontal: small ? 8 : 12,
          vertical: small ? 4 : 7,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.16) : AppColors.bg2,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.35),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tag.icon, size: small ? 12 : 15, color: color),
            SizedBox(width: small ? 4 : 6),
            Text(
              tag.name(lang),
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: small ? 11 : 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
