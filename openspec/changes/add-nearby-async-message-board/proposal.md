## Why

异步留言墙是产品三大核心功能之一（借鉴《死亡搁浅》的跨时空陪伴），但当前 `nearby_map` 仅有同好光点与活动 pin，缺少基于地点的异步留言体验。用户无法在地图上发现"曾有人在此陪伴"的留言点，也无法按兴趣标签筛选附近的留言板，核心产品叙事无法完整演示。

## What Changes

- **地图留言板标记**：在 `nearby_map` 中以小图标展示留言板位置，仅显示距用户当前位置 2km 以内的留言板；图标颜色按留言板关联的兴趣标签着色（与 `IpTag.color` 一致）。
- **留言板弹层**：点击地图上的留言板图标，弹出底部 sheet，展示该地点的历史留言列表；每条留言仅展示发布者头像（虚拟形象或占位）与其兴趣标签，不展示昵称等身份信息。
- **追加留言**：用户可在弹层内输入文字并提交，留言写入当前地点（定位不可用时使用降级坐标）。
- **标签筛选条**：地图下方展示当前用户的兴趣标签（`IpTagChip`），点击某一标签后地图仅显示与该标签关联的留言板；再次点击取消筛选，显示全部 2km 内留言板。
- **Mock 数据**：预置若干带坐标、标签、时间的留言与留言板聚合点，保证无后端可端到端演示。

## Capabilities

### New Capabilities
- `nearby-async-message-board`: 附近地图页的异步留言板——2km 可见范围、标签着色标记、弹层查看/发布留言、地图下方标签筛选、Mock 数据。

### Modified Capabilities
<!-- 现有 openspec/specs/ 为空，无既有能力需要修改。 -->

## Impact

- **代码**：`lib/features/nearby/nearby_map_view.dart`（叠加留言板标记、标签筛选条、弹层入口）；新增 `lib/features/wall/`（留言板弹层组件）；新增 `lib/shared/models/wall_message.dart`；扩展 `lib/shared/data/mock_data_source.dart` 与 `repositories.dart`（留言数据 provider、按距离/标签查询）。
- **配置**：复用既有 `MapConfig.wallClusterRadiusMeters`（100m 聚合）与 `currentLocationProvider`；新增 2km 可见半径常量。
- **依赖**：无新依赖，复用 `google_maps_flutter`、`geolocator`、既有距离工具 `haversineKm`。
- **范围**：功能仅限 `nearby_map` 地图模式，不影响列表滑动模式与其他页面。
