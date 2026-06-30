import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/activity.dart';
import '../../../shared/widgets/ip_tag_chip.dart';

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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.bg1,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(color: const Color(0xFF1B2440).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [activity.tag.color.withOpacity(0.7), AppColors.bg2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(activity.tag.icon, size: 46, color: Colors.white.withOpacity(0.6))),
                  Positioned(top: 10, left: 10, child: IpTagChip(tag: activity.tag, small: true)),
                  if (activity.joined)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.neonGreen, borderRadius: BorderRadius.circular(10)),
                        child: const Text('✓', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title(lang), style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  _row(Icons.schedule, DateFormat('MM/dd HH:mm').format(activity.time)),
                  const SizedBox(height: 4),
                  _row(Icons.location_on_outlined, activity.location(lang)),
                  const SizedBox(height: 4),
                  _row(Icons.group_outlined, '${activity.participants}/${activity.maxParticipants}'),
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
        Icon(icon, size: 14, color: AppColors.neonCyan),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
