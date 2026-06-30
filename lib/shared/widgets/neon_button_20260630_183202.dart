import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// 渐变按钮：渐变填充 + 柔和投影 + 点击缩放（Travel 风圆角胶囊）。
class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool expand;
  final EdgeInsetsGeometry padding;

  /// 是否为次级（描边）样式：透明填充 + 主色文字
  final bool secondary;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.pinkPurple,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
    this.secondary = false,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final fg = (widget.secondary || !enabled) ? AppColors.textSecondary : Colors.white;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: widget.expand ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: widget.secondary || !enabled
                ? const LinearGradient(colors: [AppColors.bg2, AppColors.bg2])
                : widget.gradient,
            borderRadius: BorderRadius.circular(18),
            border: widget.secondary ? Border.all(color: AppColors.divider) : null,
            boxShadow: (enabled && !widget.secondary)
                ? [
                    BoxShadow(
                      color: AppColors.neonPink.withOpacity(0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: AppTextStyles.button.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
