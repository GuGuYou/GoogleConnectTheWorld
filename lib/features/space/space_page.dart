import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_text.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/whisper_sheets.dart';
import '../nearby/nearby_map_view.dart';
import '../plaza/plaza_page.dart';

/// "空间"：广场（虚拟场景）与地图（GPS + 兴趣点）融合的统一容器。
///
/// 会议决定：将"广场"与"地图"两个原本割裂的功能合并成一个"空间"概念——
/// 用户可在"场景"模式下探索虚拟场景、遇见正在附近的同好，感受氛围共鸣；
/// 也可切换到"地图"模式查看真实地理位置与兴趣点，两者互为补充、共享同一入口。
class SpacePage extends ConsumerStatefulWidget {
  const SpacePage({super.key});

  @override
  ConsumerState<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends ConsumerState<SpacePage> {
  static const _floorTop = Color(0xFF0A0D1C);
  static const _gridColor = Color(0xFF31E6FF);

  bool _sceneMode = true;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    return Container(
      color: _floorTop,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (b) => const LinearGradient(
                      colors: [_gridColor, AppColors.neonPink],
                    ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                    child: Text(
                      ref.tr('space_title'),
                      style: AppTextStyles.h1.copyWith(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  _SpaceToggle(
                    sceneMode: _sceneMode,
                    sceneLabel: ref.tr('space_scene'),
                    mapLabel: ref.tr('space_map'),
                    onChanged: (v) => setState(() => _sceneMode = v),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(
                    _sceneMode ? Icons.blur_on : Icons.map_outlined,
                    size: 13,
                    color: _gridColor.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _sceneMode ? ref.tr('space_scene_hint') : ref.tr('space_map_hint'),
                      style: AppTextStyles.caption.copyWith(color: Colors.white54),
                    ),
                  ),
                  if (_sceneMode)
                    GestureDetector(
                      onTap: () => showWhisperFeedSheet(context, ref, lang),
                      child: Row(
                        children: [
                          Icon(Icons.local_florist, size: 14, color: AppColors.neonPink.withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            ref.tr('whisper_title'),
                            style: AppTextStyles.caption.copyWith(color: AppColors.neonPink),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _sceneMode
                  ? const ClipRect(child: PlazaSceneView())
                  : const NearbyMapView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceToggle extends StatelessWidget {
  final bool sceneMode;
  final String sceneLabel;
  final String mapLabel;
  final ValueChanged<bool> onChanged;
  const _SpaceToggle({
    required this.sceneMode,
    required this.sceneLabel,
    required this.mapLabel,
    required this.onChanged,
  });

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
          _seg(Icons.blur_on, sceneLabel, sceneMode, () => onChanged(true)),
          _seg(Icons.map, mapLabel, !sceneMode, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _seg(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppColors.cyanPurple : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: active ? Colors.white : Colors.white38),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : Colors.white38)),
          ],
        ),
      ),
    );
  }
}
