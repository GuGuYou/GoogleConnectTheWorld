import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';

/// 底部 3 Tab 主框架：玻璃拟态导航栏 + 霓虹高亮
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tab: 广场(地图+蜂巢) / 活动 / 我的
    final items = [
      (_NavItem(Icons.hub_outlined, Icons.hub, ref.tr('tab_space'))),
      (_NavItem(Icons.celebration_outlined, Icons.celebration, ref.tr('tab_activity'))),
      (_NavItem(Icons.person_outline, Icons.person, ref.tr('tab_profile'))),
    ];

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bg1.withValues(alpha: 0.92),
          border: const Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: [
            BoxShadow(color: AppColors.neonPurple.withValues(alpha: 0.18), blurRadius: 20),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      active: shell.currentIndex == i,
                      onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  _NavItem(this.icon, this.activeIcon, this.label);
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (b) => (active
                    ? AppColors.pinkPurple
                    : const LinearGradient(
                        colors: [AppColors.textMuted, AppColors.textMuted]))
                .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
            child: Icon(active ? item.activeIcon : item.icon, size: 25),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.neonPink : AppColors.textMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
