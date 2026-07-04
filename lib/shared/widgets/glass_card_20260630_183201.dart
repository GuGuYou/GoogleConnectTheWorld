import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 卡片：白色面板 + 柔和投影 + 细描边（Travel 风，圆角更大、更通透）。
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double blur; // 兼容旧调用，亮色主题下不再使用模糊

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.borderColor,
    this.onTap,
    this.blur = 12,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.glassBorder;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2440).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: border, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
