import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool expand;
  final EdgeInsetsGeometry padding;

  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.gradient = AppColors.pinkPurple,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.expand ? double.infinity : null,
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: enabled ? widget.gradient : const LinearGradient(colors: [AppColors.bg2, AppColors.bg2]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: enabled ? const Color(0xFF2F6BD8) : const Color(0xFFD6D6D6),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: AppTextStyles.button),
            ],
          ),
        ),
      ),
    );
  }
}
