## ADDED Requirements

### Requirement: 接入 Google Maps 地图
系统 SHALL 使用 Google Maps 作为附近页的地图底图，并应用温暖/暗色风格的自定义地图样式，替换原有的 OpenStreetMap 瓦片实现。

#### Scenario: 打开附近页显示 Google 地图
- **WHEN** 用户进入"附近"页面
- **THEN** 系统 SHALL 渲染 Google Maps 地图控件，并以当前用户位置为中心

#### Scenario: 应用自定义地图样式
- **WHEN** 地图加载完成
- **THEN** 系统 SHALL 应用项目定义的自定义 map style（保持产品视觉风格），而非默认样式

#### Scenario: 缺少或无效 API Key
- **WHEN** Google Maps API Key 缺失或无效导致地图无法加载
- **THEN** 系统 SHALL 显示可识别的降级占位（静态地图/提示），而非崩溃或白屏

### Requirement: 真实 GPS 定位与降级
系统 SHALL 通过设备定位能力获取用户当前经纬度，并在权限被拒或定位失败时降级到预设中心点。

#### Scenario: 首次请求定位权限
- **WHEN** 用户首次进入附近页
- **THEN** 系统 SHALL 请求定位权限并说明用途

#### Scenario: 授权成功获取位置
- **WHEN** 用户授予定位权限
- **THEN** 系统 SHALL 获取真实经纬度，并将地图中心与"我"的光点定位到该坐标

#### Scenario: 权限被拒或定位失败降级
- **WHEN** 用户拒绝授权或定位获取失败
- **THEN** 系统 SHALL 使用预设 Mock 中心点继续展示地图与同好，并提示定位不可用

### Requirement: 附近同好光点展示
系统 SHALL 在地图上以虚拟形象光点展示附近用户，点击光点可查看该用户资料卡。

#### Scenario: 展示附近用户光点
- **WHEN** 附近页加载且存在附近用户数据
- **THEN** 系统 SHALL 在对应经纬度以虚拟形象光点渲染这些用户

#### Scenario: 点击光点查看资料
- **WHEN** 用户点击某个同好光点
- **THEN** 系统 SHALL 弹出该用户的资料卡（昵称、匹配度、兴趣 Tag 等）

### Requirement: 兴趣 Filter 与半径筛选
系统 SHALL 默认只展示与当前用户有相同兴趣 Tag 的附近用户，并支持按半径筛选可见范围。

#### Scenario: 只显示同好（P0）
- **WHEN** 附近页展示同好光点
- **THEN** 系统 SHALL 仅展示与当前用户至少有一个相同兴趣 Tag 的用户，过滤掉无共同兴趣者

#### Scenario: 调整半径筛选（P1）
- **WHEN** 用户选择半径（如 1km/3km/全城）
- **THEN** 系统 SHALL 仅展示该半径范围内的同好，并同步刷新地图标记
