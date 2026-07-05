## 1. 数据模型与配置

- [ ] 1.1 新增 `lib/shared/models/wall_message.dart`（id/spotId/lat/lng/authorId/avatarSeed/tags/content/createdAt）
- [ ] 1.2 新增 `lib/shared/models/wall_spot.dart`（id/lat/lng/primaryTag/messageCount/tags）
- [ ] 1.3 在 `MapConfig` 新增 `wallVisibleRadiusKm = 2.0`，复用既有 `wallClusterRadiusMeters = 100`

## 2. Mock 数据与 Provider

- [ ] 2.1 在 `mock_data_source.dart` 预置 8–12 个留言板 spot 与 20+ 条历史留言（坐标散布 0.5–1.8km，覆盖多标签）
- [ ] 2.2 实现留言点 100m 就近聚合逻辑，生成 `WallSpot` 列表
- [ ] 2.3 在 `repositories.dart` 新增 `wallSpotsProvider`（全量 spots）
- [ ] 2.4 新增 `wallTagFilterProvider`（`StateProvider<IpTag?>`）与 `visibleWallSpotsProvider`（2km + 标签过滤）
- [ ] 2.5 新增 `wallMessagesForSpotProvider`（按 spotId 查询留言）与 `postWallMessage` 写入方法

## 3. 留言板弹层 UI

- [ ] 3.1 新增 `lib/features/wall/wall_spot_sheet.dart` 底部 sheet 容器（`GlassCard`）
- [ ] 3.2 实现 `WallMessageTile`：仅展示头像 + 兴趣标签 chips + 留言正文
- [ ] 3.3 实现留言输入区与提交按钮，提交后刷新列表
- [ ] 3.4 实现空状态文案（鼓励成为第一个留言者）

## 4. 地图集成（nearby_map）

- [ ] 4.1 在 `nearby_map_view.dart` 将 `visibleWallSpotsProvider` 转为彩色 Marker（按标签着色）
- [ ] 4.2 点击 Marker 调用 `showWallSpotSheet` 打开弹层
- [ ] 4.3 在地图下方添加用户兴趣标签筛选条（`IpTagChip`，选中高亮，再次点击取消）
- [ ] 4.4 确认标签筛选仅影响留言板 Marker，不改变同好光点与活动 pin

## 5. 文案与验收

- [ ] 5.1 在 `app_text.dart` 补充留言板相关 i18n key（空状态、输入提示等）
- [ ] 5.2 手测全链路：地图模式 → 见 2km 内彩色留言板 → 标签筛选 → 点开弹层 → 发留言 → 列表刷新
- [ ] 5.3 运行 `flutter analyze` 确保无新增告警
