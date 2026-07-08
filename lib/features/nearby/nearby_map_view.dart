import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection_map_view.dart';
import 'widgets/map_filter_bar.dart';

/// 「空间」- 地图模式的入口。
///
/// 包含地图过滤栏（活动/周边/留言板）和连接关系图。
/// TODO: 地图分支合并后，替换为 Google Maps Widget + 过滤栏 + 气泡标记。
class NearbyMapView extends ConsumerStatefulWidget {
  const NearbyMapView({super.key});

  @override
  ConsumerState<NearbyMapView> createState() => _NearbyMapViewState();
}

class _NearbyMapViewState extends ConsumerState<NearbyMapView> {
  MapFilterTab _filter = MapFilterTab.nearby;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 地图主体（当前为连接关系图；地图分支合并后替换为 Google Maps）
        const ConnectionMapView(),

        // 顶部过滤栏（半透明悬浮）
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(
            child: MapFilterBar(
              selected: _filter,
              onChanged: (tab) => setState(() => _filter = tab),
            ),
          ),
        ),
      ],
    );
  }
}
