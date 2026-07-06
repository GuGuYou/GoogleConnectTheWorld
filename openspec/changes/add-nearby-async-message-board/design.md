## Context

当前 `nearby_map_view.dart` 已接入 Google Maps、真实 GPS（`currentLocationProvider`）与降级路径，地图上展示同好光点（Circle）与活动 pin（Marker），但无留言板相关 UI 或数据层。既有 `MapConfig.wallClusterRadiusMeters = 100` 常量已预留留言点聚合半径，但 `wall_message` 模型与 provider 尚未落地到当前代码库。

约束：
- 功能**仅限** `nearby_map` 地图模式，不改动列表滑动模式。
- Demo 阶段全 Mock，无需真实后端。
- 留言条目匿名化：仅头像 + 兴趣标签 + 正文，不展示昵称。
- 可见范围固定 2km（产品明确要求，区别于同好雷达的可调半径 P1）。

## Goals / Non-Goals

**Goals:**
- 在地图上以小图标展示 2km 内留言板，按标签着色。
- 点击图标弹出底部 sheet，展示历史留言（头像 + 标签 + 正文），支持追加文字留言。
- 地图下方展示用户兴趣标签条，点击筛选留言板标记。
- Mock 数据 + Riverpod provider，无后端可演示。

**Non-Goals:**
- 不做语音留言（P1，后续迭代）。
- 不做独立留言墙全屏页面或路由（弹层即可）。
- 不改动同好光点/活动 pin 的筛选逻辑。
- 不做留言实时推送或后端同步。

## Decisions

- **数据模型 `WallMessage`**：字段 `id, spotId, lat, lng, authorId, avatarSeed, tags, content, createdAt`。`spotId` 由坐标聚合生成（100m 内同一 spot），便于按地点查询。
- **数据模型 `WallSpot`**：聚合后的留言板，字段 `id, lat, lng, primaryTag, messageCount, tags`（去重标签集合）。`primaryTag` 用于标记着色。
- **2km 可见半径**：在 `MapConfig` 新增 `wallVisibleRadiusKm = 2.0`，`wallSpotsProvider` 用 `haversineKm` 过滤。
- **标记着色规则**：优先取与当前用户重合的第一个 tag 的 `color`；无重合则用 `primaryTag.color`。使用 `BitmapDescriptor.defaultMarkerWithHue` 映射到 HSV hue，或后续替换为自定义彩色小图标 asset。
- **标签筛选 state**：新增 `wallTagFilterProvider`（`StateProvider<IpTag?>`），`null` 表示全部。`visibleWallSpotsProvider` 组合 `currentLocationProvider` + `wallTagFilterProvider` 输出过滤后的 spots。
- **弹层组件**：`lib/features/wall/wall_spot_sheet.dart`，内含 `WallMessageTile`（头像 + 标签 chips + 正文）与底部输入框 + 提交按钮。复用 `GlassCard`、`IpTagChip`、`VirtualAvatarView`/`AvatarPlaceholder`。
- **地图集成**：在 `nearby_map_view.dart` 的 `markers` 集合中追加留言板 Marker；地图下方 `Column` 增加 `Wrap` 标签筛选条（复用 `IpTagChip`，选中态高亮边框）。
- **Mock 数据**：在 `mock_data_source.dart` 预置 8–12 个留言板 spot、每 spot 2–4 条留言，坐标散布在 Mock 中心点 0.5–1.8km 范围内，覆盖用户常见标签。
- **发布留言**：`wallMessagesNotifier` 追加到 mock 列表并刷新 provider；新留言携带当前用户 tags 与 avatar。

## Risks / Trade-offs

- [Google Maps Marker 颜色有限] → 先用 `defaultMarkerWithHue` 近似标签色，美术资源到位后换自定义 icon。
- [100m 聚合 vs 用户感知"地点"] → 100m 内视为同一留言板，Demo 可接受；产品已确认默认值。
- [2km 硬编码] → 写入 `MapConfig` 常量，后续可调而不改业务逻辑。
- [筛选仅影响留言板，用户可能困惑] → 标签条文案/选中态视觉区分，spec 明确不影响同好光点。

## Migration Plan

1. 新增 `wall_message.dart`、`wall_spot.dart` 模型。
2. Mock 数据 + `wallSpotsProvider` / `visibleWallSpotsProvider` / `wallMessagesForSpotProvider` / `wallTagFilterProvider`。
3. 实现 `wall_spot_sheet.dart` 弹层与 `WallMessageTile`。
4. 改造 `nearby_map_view.dart`：追加 markers、标签筛选条、点击回调。
5. 手测：地图模式 → 见彩色留言板图标 → 点标签筛选 → 点开弹层 → 发留言 → 列表刷新。

回滚：留言板 markers 与底部标签条可通过 feature 局部移除，不影响地图主体与同好光点。

## Open Questions

- 留言板小图标的最终视觉（默认 pin vs 自定义 asset）待 7.8 美工介入后替换，当前用彩色 marker 占位。
- 多标签留言板着色：已采用"与用户重合 tag 优先"规则，若产品需"多色渐变"可后续迭代。
