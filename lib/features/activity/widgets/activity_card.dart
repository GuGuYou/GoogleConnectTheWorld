import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/widgets/gold_glow.dart';

/// Event list card per the Frame 4 Figma spec: info column on the left
/// (bordered tag chip, title, meta rows), glowing outlined hexagon icon
/// over a warm radial glow on the right, 1px gradient border.
class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final String lang;
  const ActivityCard({super.key, required this.activity, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/activity/${activity.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 123,
        child: CustomPaint(
          foregroundPainter: const GoldCardBorderPainter(),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: AppColors.cardSurface,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Warm glow behind the hexagon (replaces the old orbit art).
                Positioned(
                  right: 10,
                  top: -20,
                  bottom: -20,
                  width: 160,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFC000).withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Faint gold wash near the top-left of the card.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(-0.55, -1.1),
                        radius: 1.0,
                        colors: [
                          const Color(0xFFFFC000).withValues(alpha: 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Sparkles around the hexagon.
                _spark(right: 32, top: 16, size: 3, alpha: 0.9),
                _spark(right: 118, top: 78, size: 2, alpha: 0.6),
                _spark(right: 44, top: 100, size: 2.5, alpha: 0.7),
                // Glowing outlined hexagon with the category icon.
                Positioned(
                  right: 50,
                  top: 21.5,
                  child: GlowHexagon(
                    width: 70,
                    height: 80,
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFD48F), Color(0xFFFF7017)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                      child: Icon(activity.tag.icon, size: 36),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TagChip(label: activity.tag.name(lang)),
                          const Spacer(),
                          if (activity.joined)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.neonGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('✓',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.ctaText,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 185,
                        child: Text(
                          activity.title(lang),
                          style: AppTextStyles.tt(
                            size: 15.5,
                            weight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _row(Icons.schedule,
                          DateFormat('MM/dd HH:mm').format(activity.time)),
                      const SizedBox(height: 4),
                      _row(Icons.location_on_outlined, activity.location(lang)),
                      const SizedBox(height: 4),
                      _row(Icons.group_outlined,
                          '${activity.participants}/${activity.maxParticipants}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _spark(
      {required double right,
      required double top,
      required double size,
      required double alpha}) {
    return Positioned(
      right: right,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF5CA4B).withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5CA4B).withValues(alpha: alpha * 0.8),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.iconGold),
        const SizedBox(width: 6),
        SizedBox(
          width: 160,
          child: Text(
            text,
            style: AppTextStyles.caption
                .copyWith(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bordered text-only category chip (h18, r9, #110F05 fill, thin gold
/// gradient border, #FDD570 label) per the Figma list-card spec.
class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFD68D1F).withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.tt(
          size: 10.5,
          weight: FontWeight.w600,
          color: AppColors.neonYellow.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
