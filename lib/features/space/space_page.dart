import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_text.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/neon_button.dart';
import '../nearby/nearby_map_view.dart';
import 'hive_scene/hive_isometric_page.dart';

/// "空间"：广场（虚拟场景）与地图（GPS + 兴趣点）融合的统一容器。
///
/// 场景模式占满全屏（标题/底栏由 [HiveRoomScene] 自己处理）；
/// 地图模式显示真实地理位置与兴趣点，首次进入先展示 Buzz around 引导。
class SpacePage extends ConsumerStatefulWidget {
  const SpacePage({super.key});

  @override
  ConsumerState<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends ConsumerState<SpacePage> {
  bool _sceneMode = true;
  bool _mapIntroSeen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg0,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部切换开关（两个模式共享）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  GradientText(
                    _sceneMode ? 'Hive' : 'Map',
                    style: AppTextStyles.h1,
                  ),
                  const Spacer(),
                  _SpaceToggle(
                    sceneMode: _sceneMode,
                    onChanged: (v) => setState(() => _sceneMode = v),
                  ),
                ],
              ),
            ),
            // AnimatedSwitcher：场景↔地图切换 ≤500ms
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _sceneMode
                    ? HiveIsometricPage(
                        key: const ValueKey('hive'),
                        onSwitchToMap: () => setState(() => _sceneMode = false),
                      )
                    : _mapIntroSeen
                        ? const NearbyMapView(key: ValueKey('map'))
                        : _BuzzIntro(
                            key: const ValueKey('buzz-intro'),
                            onStart: () =>
                                setState(() => _mapIntroSeen = true),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 首次进入地图模式的引导态（Figma "Buzz around" 帧）。
class _BuzzIntro extends ConsumerWidget {
  final VoidCallback onStart;
  const _BuzzIntro({super.key, required this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/decorations/fig_buzz_orbit.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          GradientText(
            ref.tr('buzz_intro_title'),
            textAlign: TextAlign.center,
            style: AppTextStyles.display(context).copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            ref.tr('buzz_intro_desc'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: ref.tr('buzz_intro_cta'),
            icon: Icons.arrow_forward_rounded,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _SpaceToggle extends StatelessWidget {
  final bool sceneMode;
  final ValueChanged<bool> onChanged;
  const _SpaceToggle({required this.sceneMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.chipSurface,
        borderRadius: BorderRadius.circular(200),
      ),
      child: Row(
        children: [
          _seg('Scene', sceneMode, () => onChanged(true)),
          _seg('Map', !sceneMode, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.neonGreen : null,
          borderRadius: BorderRadius.circular(200),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: active ? AppColors.ctaText : AppColors.textMuted,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
