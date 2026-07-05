## Why

大赛硬性要求接入 Google Map，而当前原型用的是 `flutter_map` + OpenStreetMap，且定位是写死的 Mock 中心点，未接真实 GPS，不满足交付要求。同时"异步留言墙"（借鉴《死亡搁浅》的跨时空陪伴）是产品三大核心功能之一，目前完全缺失——现有的只是 1v1 实时 IM，方向与"异步陪伴"相反。这两块是我负责的工作，需要在 7.5 第一版原型和 7.8 全链路验收前落地。

## What Changes

- **接入 Google Maps**：用 `google_maps_flutter` 替换 `nearby` 模块里的 `flutter_map`/OSM 瓦片，保留赛博暗色地图风格（自定义 map style JSON）。**BREAKING**：移除 OSM `TileLayer` 渲染路径。
- **真实 GPS 定位**：接入 `geolocator` 获取用户当前经纬度与定位权限流程，权限拒绝/失败时降级到 Mock 中心点（对齐风险预案）。
- **同好雷达可视化**：在地图上以虚拟形象光点展示附近同 Tag 用户，支持半径筛选（如 3km，P1）与兴趣 Filter（只显示相同 Tag，P0），点击光点弹出资料卡。
- **异步留言墙**：用户可在当前地点留下文字/语音（语音为 P1）留言；他人路过同一地点半径内时可查看历史留言，呈现"曾有 X 位同好在此留下这些话"的温暖回忆录体验。
- **地图与留言联动**：地图上新增"留言点"标记，点击查看该点历史留言并可追加留言。
- **Mock 数据补充**：为附近同好、留言点提供 Mock 数据，保证无后端也能端到端演示（对齐 Demo 用 Mock 的定位）。

## Capabilities

### New Capabilities
- `googlemap-radar`: Google Maps 接入、真实 GPS 定位与降级、附近同 Tag 用户光点展示、半径与兴趣筛选、点击查看资料。
- `async-message-wall`: 基于地点的异步留言（发布、按地点/半径查看历史留言、留言与地图联动、Mock 留言数据）。

### Modified Capabilities
<!-- 现有 openspec/specs/ 为空，无既有能力需要修改。 -->

## Impact

- **代码**：`lib/features/nearby/nearby_map_view.dart`（替换地图实现）、新增 `lib/features/wall/`（留言墙页面/组件）、新增 `lib/core/services/location_service.dart`、新增 `lib/shared/models/wall_message.dart`、扩展 `lib/shared/data/mock_data_source.dart` 与 `repositories.dart`。
- **依赖**：新增 `google_maps_flutter`、`geolocator`；移除对 `flutter_map`/`latlong2` 在 nearby 的使用（如无他处依赖可后续清理）。
- **配置**：需配置 Google Maps API Key（Android `AndroidManifest.xml`、iOS `AppDelegate`/`Info.plist`、Web `index.html`），并在文档记录 Key 获取与限制。
- **平台**：Web 版需引入 Google Maps JS SDK；注意 `google_maps_flutter` 各平台差异与 Web 支持情况。
- **风险**：Google Map 接入慢（7.5 需跑通，否则静态地图+假定位降级）；GPS 不准（Demo 可接受误差 + Mock 辅助）；语音留言若来不及降级为纯文字。
