## Context

现有 Flutter 原型（`g_interest_social`）为 Mock 驱动，附近页 `lib/features/nearby/nearby_map_view.dart` 使用 `flutter_map` + OSM 瓦片，配 `ColorFiltered` 做暗色赛博滤镜；定位写死为 `MockDataSource.centerLat/centerLng`，无真实 GPS。数据层为 `mock_data_source.dart` + `repositories.dart`（Riverpod provider，如 `nearbyUsersProvider`、`activitiesProvider`）。已有 `ChatMessage`（1v1 IM）但无基于地点的异步留言。

约束：

- 大赛要求必须接入 Google Map；7.5 需跑通，否则静态地图+假定位降级。
- 目标平台以 Web（移动端适配）为主，Demo 阶段全 Mock，无需真实多人/后端。
- 视觉需保持产品既有风格（暖色/治愈方向），地图需自定义样式。
- 时间紧（7.5 原型 / 7.8 全链路），P0 优先，P1 可砍。

## Goals / Non-Goals

**Goals:**

- 用 `google_maps_flutter` 替换 nearby 的地图实现，接入真实 GPS（`geolocator`）并保留降级路径。
- 地图上以光点展示同 Tag 附近用户，支持兴趣 Filter（P0）与半径筛选（P1）。
- 新增基于地点的异步留言墙：发布文字（P0）/语音（P1）、按地点半径查看历史留言、地图留言点联动、Mock 数据。
- 保证无后端可端到端演示。

**Non-Goals:**

- 不做真实后端/多人实时同步（留言"同步"指跨时间异步可见，非实时推送）。
- 不做实时聊天室、好友系统、私信、精确到米的距离。
- 不做复杂匹配算法（沿用既有 Jaccard 匹配度）。
- 本次不强制清理 `flutter_map`/`latlong2`（若他处仍引用，留待后续）。



## Decisions

- **地图库选** `google_maps_flutter`**（官方）而非继续** `flutter_map`：满足大赛"接入 Google Map"硬性要求。代价：Web 需引入 Maps JS SDK 与 API Key，各平台配置更重。备选 `flutter_map` + Google 瓦片被否（违反使用条款且不算"接入"）。
- **定位用** `geolocator`：跨平台（含 Web）获取坐标与权限流程成熟。封装到 `lib/core/services/location_service.dart`，对外暴露 `Future<LatLng?> current()`，失败返回 null → 上层降级到 Mock 中心点。
- **坐标类型统一**：`google_maps_flutter` 用自带 `LatLng`；逐步弃用 `latlong2` 的 `LatLng`（nearby 内改用 gmap 的类型），避免两套 LatLng 混用歧义。
- **暗色/风格化地图**：用 Google Maps 自定义 style JSON（`setMapStyle`）实现风格，替代原 `ColorFiltered` 方案。
- **留言数据模型**：新增 `lib/shared/models/wall_message.dart`，字段含 `id, lat, lng, authorId, avatarSeed, tags, type(text/voice), content, createdAt`。留言点按坐标聚合（就近半径内视为同一地点）；提供 `wallMessagesProvider` 与"按坐标半径查询"方法。
- **Filter 复用现有匹配逻辑**：同好过滤沿用现有 Tag 重合判断（`nearbyUsersProvider` 层过滤），半径筛选用现有 `core/utils/distance.dart`。
- **API Key 管理**：Key 写入各平台原生配置（Android manifest / iOS Info.plist / Web index.html），并用 `--dart-define` 或占位文档说明，避免硬编码进业务代码；README/交付文档记录获取步骤。
- **分模块目录**：留言墙独立为 `lib/features/wall/`（页面 + widgets），与 nearby 通过 provider 联动，降低耦合。



## Risks / Trade-offs

- [Google Map 接入/Web 配置耗时，7.5 跑不通] → 先用静态地图图片 + Mock 假定位降级演示，Key 与平台配置并行推进。
- [`google_maps_flutter` Web 支持与移动端存在 API 差异] → 优先保证一个主平台（Web）跑通，控件差异用条件封装隔离。
- [GPS 定位不准/权限被拒] → Demo 可接受误差；统一降级到 Mock 中心点，功能不阻断。
- [语音留言录制/播放跨平台复杂] → 语音为 P1，来不及直接砍为纯文字留言。
- [两套 LatLng 混用导致编译/逻辑错误] → nearby 与 wall 统一使用 gmap `LatLng`，util 做必要转换。
- [API Key 泄露/超额] → Key 加平台与来源限制，Demo 用受限 Key，文档提示不要提交真实 Key 到仓库。



## Migration Plan

1. 加依赖 `google_maps_flutter`、`geolocator`；配置各平台 API Key。
2. 新增 `location_service.dart`，接入定位与降级；先在附近页替换中心点为真实坐标。
3. 用 `GoogleMap` 控件替换 `FlutterMap`，迁移"我/同好/活动"标记，套用自定义 style。
4. 接入兴趣 Filter（P0）与半径筛选（P1）。
5. 新增 `wall_message.dart` 模型 + Mock 数据 + provider；搭建 `features/wall` 页面（发布/列表/空状态）。
6. 地图叠加留言点标记并联动留言视图；补语音留言（P1，视时间）。
7. 回归验收：注册→设 Tag→看地图→看到同好→留言 全链路跑通。

回滚策略：地图替换以分支/开关推进；若 Google Map 阻塞，附近页可临时切回静态地图降级组件，留言墙功能不依赖 Google Map 亦可独立演示。

## Open Questions

- Google Maps API Key 由谁申请、是否有配额/计费账号？（影响 7.5 跑通）  
你先留下api接口，我现在去申请
- Web 为唯一主交付平台，还是需同时保证 Android/iOS 运行？  
需要保证Android 和 iOS运行
- 语音留言是否纳入 Demo 演示（决定 P1 取舍与录音库选型）？  
你自己决定，可以使用保守一些的方法
- 留言点"就近聚合"的半径阈值取值（如 50m/100m）需产品确认。  
先使用100m作为默认值

