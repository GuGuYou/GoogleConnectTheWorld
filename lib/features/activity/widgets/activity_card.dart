import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/widgets/hexagon.dart';
import '../../../shared/widgets/ip_tag_chip.dart';

/// Event list card per the Figma comp: info column on the left, orbit-ring
/// art with a hexagon icon on the right.
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: AppColors.cardSurface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: 0,
              bottom: 0,
              child: Image.asset(
                'assets/images/decorations/fig_orbit_rings.png',
                width: 150,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              right: 34,
              top: 21,
              child: ClipPath(
                clipper: const HexagonClipper(),
                child: Container(
                  width: 81,
                  height: 81,
                  color: AppColors.hexFill,
                  child: Center(
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IpTagChip(tag: activity.tag, small: true),
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
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 170,
                    child: Text(
                      activity.title(lang),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _row(Icons.schedule,
                      DateFormat('MM/dd HH:mm').format(activity.time)),
                  const SizedBox(height: 3),
                  _row(Icons.location_on_outlined, activity.location(lang)),
                  const SizedBox(height: 3),
                  _row(Icons.group_outlined,
                      '${activity.participants}/${activity.maxParticipants}'),
                ],
              ),
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
