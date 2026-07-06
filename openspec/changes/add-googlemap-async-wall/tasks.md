## 1. 依赖与平台配置（P0，7.5 前跑通）

- [x] 1.1 在 `pubspec.yaml` 添加 `google_maps_flutter`、`geolocator` 依赖并 `flutter pub get`
- [ ] 1.2 申请 Google Maps API Key，确认配额/计费账号（用户进行中，占位符已就位）
- [x] 1.3 配置 Android：`android/app/src/main/AndroidManifest.xml` 加 API Key 与定位权限
- [x] 1.4 配置 iOS：`Info.plist` 加 Key 与 `NSLocationWhenInUseUsageDescription`
- [x] 1.5 配置 Web：`web/index.html` 引入 Google Maps JS SDK + Key
- [x] 1.6 在 README/交付文档记录 Key 获取与"勿提交真实 Key"的说明
- [x] 1.7 验证空白 `GoogleMap` 控件能在主平台（Web）成功加载（无 Key 走降级视图，不白屏；真实 Key 由用户填入后渲染）

## 2. 定位服务与降级（P0）

- [x] 2.1 新增 `lib/core/services/location_service.dart`，封装 `current()` 返回坐标或 null
- [x] 2.2 实现定位权限请求流程（首次说明用途、被拒处理）
- [x] 2.3 实现降级：定位失败/被拒时回退到 `MockDataSource` 中心点并提示
- [x] 2.4 提供 `currentLocationProvider`（Riverpod），供附近页与留言墙复用

## 3. Google Maps 替换附近页（P0）

- [x] 3.1 用 `GoogleMap` 替换 `nearby_map_view.dart` 中的 `FlutterMap`/OSM `TileLayer`
- [x] 3.2 制作并应用自定义暗色/风格化 map style JSON（`kNeonDarkMapStyle`，替代原 `ColorFiltered`）
- [x] 3.3 迁移"我"的位置光点到真实/降级坐标，地图以此为初始中心
- [x] 3.4 迁移附近同好光点（虚拟形象），点击弹出资料卡 sheet
- [x] 3.5 迁移活动 pin 标记
- [x] 3.6 统一坐标类型为 gmap `LatLng`（含 `latlong2`→gmap 迁移，nearby 已不再依赖 latlong2）
- [x] 3.7 处理 Key 缺失/无效时的降级占位（雷达占位视图，不白屏）

## 4. 同好雷达筛选（Filter P0 / 半径 P1）

- [x] 4.1 P0：在 `nearbyUsersProvider` 层过滤，仅保留与当前用户有相同 Tag 的用户（`interestFilterProvider`）
- [x] 4.2 P1：新增半径选择（1km/3km/10km/全城），用 `core/utils/distance.dart` 计算（`nearbyRadiusProvider`）
- [x] 4.3 半径/Filter 变化时刷新地图标记与列表（Riverpod 响应式）

## 5. 异步留言墙 - 数据层（P0）

- [x] 5.1 新增 `lib/shared/models/wall_message.dart`（id/lat/lng/authorId/avatarSeed/tags/type/content/createdAt）
- [x] 5.2 在 `mock_data_source.dart` 预置带坐标/Tag/时间的 Mock 历史留言
- [x] 5.3 在 `repositories.dart` 新增 `wallMessagesProvider` 与"按坐标+半径查询"方法（`wallSpotsProvider`/`currentSpotProvider`）
- [x] 5.4 实现留言点就近聚合（默认 100m，`MapConfig.wallClusterRadiusMeters`）

## 6. 异步留言墙 - 页面（P0）

- [x] 6.1 新增 `lib/features/wall/` 目录与路由（`/wall/compose` 已在 go_router 注册）
- [x] 6.2 发布留言页：文字输入 + 提交，写入当前坐标（定位不可用用降级坐标）
- [x] 6.3 留言列表视图：按时间展示某地点历史留言 + 发布者虚拟形象/Tag（`WallMessageTile`）
- [x] 6.4 展示"曾有 X 位同好在这里留下这些话"汇总信息（`wallSummary`）
- [x] 6.5 空留言点的空状态（鼓励成为第一个留言者）

## 7. 地图与留言联动（P0）

- [x] 7.1 地图叠加留言点标记（可点击，橙色 marker / 雷达黄点）
- [x] 7.2 点击留言点标记打开历史留言视图，并提供追加留言入口（`showWallSpotSheet`）
- [x] 7.3 发布后刷新地图留言点与列表（Riverpod 响应式）

## 8. 亮点/收尾（P1，按时间取舍）

- [x] 8.1 P1：语音留言（保守方案）——保留 `WallMessageType.voice`/`voiceSeconds` 字段位，Demo 阶段只做文字，不强做录制
- [x] 8.2 P1：留言列表排序（spot 内按时间倒序）/ 汇总统计展示
- [ ] 8.3 全链路回归：注册→设 Tag→看地图→看到同好→留言（`flutter analyze` 已过，建议配 Key 后真机/浏览器手测）
- [x] 8.4 准备演示所需 Mock 数据与降级预案（14 条 Mock 留言 + 无 Key 雷达降级）
