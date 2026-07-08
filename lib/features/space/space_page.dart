import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../nearby/nearby_map_view.dart';
import 'hive_room_scene.dart';

/// "空间"：广场（虚拟场景）与地图（GPS + 兴趣点）融合的统一容器。
///
/// 场景模式占满全屏（标题/底栏由 [HiveRoomScene] 自己处理）；
/// 地图模式显示真实地理位置与兴趣点。
class SpacePage extends ConsumerStatefulWidget {
  const SpacePage({super.key});

  @override
  ConsumerState<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends ConsumerState<SpacePage> {
  static const _floorTop = Color(0xFF1A0F00);

  bool _sceneMode = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _floorTop,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部切换开关（两个模式共享）
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.neonCyan, AppColors.neonPink],
                    ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                    child: Text(
                      _sceneMode ? 'Hive' : 'Map',
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
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
                    ? HiveRoomScene(
                        key: const ValueKey('hive'),
                        onSwitchToMap: () => setState(() => _sceneMode = false),
                      )
                    : const NearbyMapView(key: ValueKey('map')),
              ),
            ),
          ],
        ),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
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
          gradient: active ? AppColors.cyanPurple : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
