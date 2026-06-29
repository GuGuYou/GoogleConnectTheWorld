# 兴趣社交 App · 技术选型清单

> **版本**: v0.1 (原型期)
> **负责人**: 许科恒 / seanzjxiao（肖子骏）
> **最后更新**: 2026-06-27
> **目标平台**: iOS 12+ / Android 6.0+

---

## 1. 选型总览

### 1.1 技术栈分层

| 层级 | 选型 | 版本 | 用途 |
| --- | --- | --- | --- |
| **框架** | Flutter | 3.24+ (Dart 3.5+) | 跨平台 UI 框架 |
| **状态管理** | Riverpod | 2.5+ | 轻量响应式状态管理 |
| **路由** | go_router | 14.x | 声明式路由 |
| **国际化** | flutter_localizations + intl | latest | 中英双语 |
| **地图** | flutter_map | 7.x | OSM 离线瓦片地图 |
| **动效** | lottie + flutter_animate | latest | 启动动画 / 微交互 |
| **网络（预留）** | dio | 5.x | HTTP 客户端（远期） |
| **本地存储** | shared_preferences | 2.x | 语言/主题/Token |
| **代码生成** | build_runner + freezed + riverpod_generator | latest | 不可变模型 |
| **图片** | cached_network_image | 3.x | 图片缓存（远期） |
| **图标** | lucide_icons | latest | 统一图标库 |
| **字体** | Rajdhani + Noto Sans SC | — | 赛博标题 + 中文正文 |

### 1.2 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  Pages ── Watch ──> Riverpod Providers                  │
│  Widgets ── Consume ──> Notifier State                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                        │
│  Entities (Freezed) + UseCases (Optional)                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                         │
│  Repositories ──> DataSources (Mock | Remote 远期)      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                        Core Layer                        │
│  Theme / Router / L10n / Constants / Utils              │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 框架：Flutter 3.24+

### 2.1 选型理由
- ✅ **跨平台**：iOS + Android 一套代码 95% 复用，降低维护成本
- ✅ **LBS 后台常驻**：可使用 `flutter_background_service` / `workmanager` 实现
- ✅ **性能**：Skia 渲染 + 自绘 UI，列表滑动 60fps 稳定
- ✅ **生态**：pub.dev 第三方包丰富（地图/IM/支付/推送 都有官方推荐）
- ✅ **设计还原度高**：自绘 UI + Lottie 动效，完美实现赛博霓虹风格

### 2.2 替代方案对比
| 方案 | 优点 | 缺点 | 结论 |
| --- | --- | --- | --- |
| **Flutter** | 跨平台、UI 自绘、生态丰富 | 包体积略大 | ✅ 选用 |
| React Native | JS 生态、Hot Reload 快 | UI 还原度差、LBS 后台常驻难 | ❌ |
| 原生 iOS+Android | 性能最佳、LBS/IM 成熟 | 双倍开发成本、设计一致性差 | ❌ |
| UniApp x | 国内生态、Vue 友好 | 性能与动效能力弱于 Flutter | ❌ |

### 2.3 风险
- 包体积：Flutter debug 包 ~25MB，release 优化后 ~12MB，可接受
- iOS 审核：Flutter 应用过审无障碍问题（已用 `Semantics` 包裹关键控件）

---

## 3. 状态管理：Riverpod 2.5+

### 3.1 选型理由
- ✅ **编译时安全**：`riverpod_generator` 提供静态分析，比 Provider 少出错
- ✅ **无 BuildContext 依赖**：可在任何地方读取状态，便于测试
- ✅ **可组合**：`Provider.family` / `Notifier` 灵活组合派生状态
- ✅ **类型安全**：泛型推断完善，无需手动声明类型

### 3.2 替代方案对比
| 方案 | 优点 | 缺点 | 结论 |
| --- | --- | --- | --- |
| **Riverpod** | 编译安全、组合性强 | 学习曲线略陡 | ✅ 选用 |
| Provider | 简单易学 | 运行时类型不安全 | ❌ |
| Bloc | 模式清晰、可测试 | 样板代码多、对小型项目偏重 | ❌ |
| GetX | 路由/状态/DI 一体 | 侵入性强、设计模式杂 | ❌ |

### 3.3 使用规范
- 全局状态：`NotifierProvider`（如 Locale、Auth、当前用户）
- 派生状态：`Provider`（如"按距离排序的用户列表"）
- 局部状态：`StatefulWidget` + `setState`
- 不使用 `ConsumerWidget` 的 `ref.watch` 之外的方式修改状态

---

## 4. 路由：go_router 14.x

### 4.1 选型理由
- ✅ **官方推荐**：Flutter 团队主推的路由方案
- ✅ **声明式**：URL 风格路由，DeepLink 友好
- ✅ **ShellRoute 支持**：完美适配底部 4 Tab 嵌套结构
- ✅ **类型安全**：路径参数支持泛型解析

### 4.2 路由表设计
```
/                                # 启动
/onboarding                      # 引导
/login                           # 登录
/register                        # 注册
/tag-select                      # 兴趣标签选择
/discover                        # Tab 1 - 发现 Feed
/nearby                          # Tab 2 - 附近
  ├─ /nearby/list                #   列表视图
  └─ /nearby/map                 #   地图视图
/activity                        # Tab 3 - 活动
  ├─ /activity/create            #   发布
  └─ /activity/:id               #   详情
/profile                         # Tab 4 - 我的
  ├─ /profile/edit
  └─ /profile/settings
/chat                            # 会话列表
/chat/:id                        # 单聊
/user/:id                        # 用户资料
```

### 4.3 替代方案对比
- `AutoRoute`：功能强但代码生成复杂
- 手写 `Navigator 2.0`：灵活但样板多、易出错

---

## 5. 国际化：flutter_localizations + intl

### 5.1 选型理由
- ✅ **官方方案**：Flutter 团队维护
- ✅ **arb 文件**：结构化文案管理，便于翻译协作
- ✅ **代码生成**：`flutter gen-l10n` 自动生成 AppLocalizations 类
- ✅ **类型安全**：编译期检查 key 是否存在

### 5.2 文件结构
```
lib/
└── l10n/
    ├── app_zh.arb        # 中文文案
    ├── app_en.arb        # 英文文案
    └── app_localizations.dart  # 自动生成
l10n.yaml                  # 生成配置
```

### 5.3 切换实现
```dart
// localeProvider 监听 SharedPreferences
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.watch(sharedPrefsProvider).getString('locale') ?? 'zh';
    return Locale(saved);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    await ref.read(sharedPrefsProvider).setString('locale', code);
  }
}
```

---

## 6. 地图：flutter_map 7.x + OpenStreetMap

### 6.1 选型理由
- ✅ **零成本**：OSM 瓦片免费，无需 API Key
- ✅ **纯前端**：所有数据 mock，无需后端
- ✅ **性能**：Web Mercator 投影，支持 50+ pin 流畅渲染
- ✅ **可定制**：Marker 颜色/大小/动画完全自定义

### 6.2 替代方案对比
| 方案 | 优点 | 缺点 | 结论 |
| --- | --- | --- | --- |
| **flutter_map (OSM)** | 零成本、完全 mock | 瓦片加载稍慢（本期可接受） | ✅ 选用 |
| 高德/百度 Flutter SDK | 国内数据准 | 需要 Key、实名认证、隐私合规 | 远期 |
| Google Maps | 数据最全 | 国内访问难、收费 | ❌ |

### 6.3 实现要点
- 中心点：深圳南山区（22.5429, 113.9414）
- 缩放级别：zoom = 14（街区级）
- 用户 Marker：发光圆点 + 颜色按兴趣分类
- 活动 Marker：菱形 pin + 霓虹描边
- 点击 Marker：弹底部抽屉卡片

---

## 7. 动效：lottie + flutter_animate

### 7.1 lottie
- **用途**：启动页连接动画、匹配成功粒子爆炸、空状态插画
- **资源**：从 lottiefiles.com 下载赛博风 JSON（< 200KB / 个）
- **备选**：若找不到合适资源，用纯 Flutter 自绘

### 7.2 flutter_animate
- **用途**：按钮点击脉冲、卡片入场、标签 Chip 渐显
- **优势**：链式 API 简洁，零代码生成
```dart
NeonButton()
  .animate(onPlay: (c) => c.repeat())
  .scaleXY(end: 1.05, duration: 800.ms)
  .then()
  .scaleXY(end: 1.0, duration: 800.ms)
```

---

## 8. 数据模型：freezed

### 8.1 选型理由
- ✅ **不可变**：`copyWith` 安全更新
- ✅ **JSON 序列化**：`json_serializable` 自动生成
- ✅ **模式匹配**：`sealed class` 支持 Dart 3 模式匹配
- ✅ **Union 类型**：`AsyncValue` 等场景天然适配

### 8.2 核心模型
```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String nickname,
    required String avatarSeed,
    required String bio,
    required List<IpTag> tags,
    required double lat,
    required double lng,
    @Default('') String city,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

---

## 9. 本地存储：shared_preferences

### 9.1 选型理由
- ✅ **简单**：key-value 存储，API 直观
- ✅ **跨平台**：iOS / Android 行为一致
- ✅ **足够**：本期只需存语言、主题、mock token

### 9.2 远期升级
- 用户数据、聊天记录等复杂数据：迁移到 `drift`（SQLite）或 `hive`（NoSQL）

---

## 10. 字体与图标

### 10.1 字体
- **Rajdhani**（Google Fonts）：赛博感几何无衬线，用于标题/数字
  - 打包：Regular 400、Medium 500、Bold 700
- **Noto Sans SC**（Google Fonts）：中文正文
  - 打包：Regular 400、Medium 500
- **Inter**（Google Fonts，备选）：英文正文

### 10.2 图标
- **lucide_icons**：2000+ 现代线性图标，风格统一
- 自绘 SVG：IP 标签专属图标（仅在 8 个核心标签上自绘）

---

## 11. 工具链

| 工具 | 版本 | 用途 |
| --- | --- | --- |
| Dart | 3.5+ | 语言 |
| Flutter SDK | 3.24+ | 框架 |
| Android Studio / VS Code | latest | IDE |
| build_runner | 2.4+ | 代码生成 |
| flutter_lints | 4.x | Lint 规则 |
| very_good_analysis | 6.x | 严格 Lint（可选） |

---

## 12. 完整 `pubspec.yaml` 依赖清单

```yaml
name: g_interest_social
description: LBS + IP 标签兴趣社交 App 原型
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # 路由
  go_router: ^14.2.7

  # 国际化
  intl: ^0.19.0

  # 地图
  flutter_map: ^7.0.2
  latlong2: ^0.9.1

  # 动效
  lottie: ^3.1.2
  flutter_animate: ^4.5.0

  # UI
  cupertino_icons: ^1.0.8
  lucide_icons: ^0.4.2
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1

  # 数据
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # 工具
  shared_preferences: ^2.3.2

  # 卡片滑动
  flutter_card_swiper: ^7.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.3
  custom_lint: ^0.6.7
  riverpod_lint: ^2.3.13

flutter:
  uses-material-design: true
  generate: true  # 启用 gen-l10n

  assets:
    - assets/images/
    - assets/lottie/
    - assets/data/

  fonts:
    - family: Rajdhani
      fonts:
        - asset: assets/fonts/Rajdhani-Regular.ttf
          weight: 400
        - asset: assets/fonts/Rajdhani-Medium.ttf
          weight: 500
        - asset: assets/fonts/Rajdhani-Bold.ttf
          weight: 700
    - family: NotoSansSC
      fonts:
        - asset: assets/fonts/NotoSansSC-Regular.otf
          weight: 400
        - asset: assets/fonts/NotoSansSC-Medium.otf
          weight: 500
```

---

## 13. 性能预算

| 指标 | 预算 | 优化手段 |
| --- | --- | --- |
| 首屏启动 | < 2.5s | Lottie 预加载、首屏数据 mock 同步 |
| 列表滑动 | ≥ 55 FPS | `ListView.builder` + `const` 组件 |
| 帧耗时 (jank) | < 5% | 避免在 build 中做距离计算（用 `select`） |
| 包大小 (release) | < 20MB | Tree-shaking、字体子集化 |
| 内存峰值 | < 200MB | 图片 lazy load + 缓存上限 |

---

## 14. 安全与隐私

### 14.1 本期（MVP 原型）
- 登录态：本地 mock token，不加密
- 位置：mock 坐标，不获取真实定位
- 图片：仅 mock 占位图，无真实上传

### 14.2 远期规划
- 接入真实定位前必须：iOS `NSLocationWhenInUseUsageDescription`、Android `ACCESS_FINE_LOCATION` 权限申请文案
- 位置模糊化（返回 500m 精度而非精确坐标）
- HTTPS + Token 鉴权 + 接口签名
- 用户协议与隐私政策弹窗（合规上架要求）

---

## 15. 测试策略

| 层级 | 工具 | 范围 | 本期目标 |
| --- | --- | --- | --- |
| 单元测试 | flutter_test | 工具函数、Repository | 核心 utils 100% |
| Widget 测试 | flutter_test | 公共组件 | 关键组件（NeonButton 等） |
| 集成测试 | integration_test | 关键流程 | 启动 → 注册 → 主页 |
| Golden 测试 | flutter_test | UI 截图回归 | 暂不引入 |
| 手动测试 | - | 演示流程 | 全流程过 1 遍 |

---

## 16. CI / CD（远期，本期不做）

- GitHub Actions：lint + test + build
- Fastlane：自动打包上传到蒲公英 / Firebase App Distribution
- 灰度发布：5% → 20% → 50% → 100%

---

## 17. 替代方案全景对比

| 维度 | 选用 | 备选 A | 备选 B |
| --- | --- | --- | --- |
| 框架 | Flutter | React Native | 原生 |
| 状态管理 | Riverpod | Bloc | Provider |
| 路由 | go_router | AutoRoute | 手写 Navigator 2.0 |
| 地图 | flutter_map (OSM) | 高德 SDK | Google Maps |
| 国际化 | flutter_localizations | easy_localization | 手写 |
| 动效 | lottie + flutter_animate | rive | hero（内置） |
| 模型 | freezed | equatable + 手写 | json_serializable 裸用 |
| 存储 | shared_preferences | hive | sqflite |
| 卡片滑动 | flutter_card_swiper | appinio_swiper | 手写 |

---

## 18. 实施注意事项

1. **所有文案必须同时补齐 zh/en 两个 arb 文件**——切语言时缺 key 会显示 key 字符串
2. **新 IP 标签需要同步更新 mock 数据**——保证演示时数据多样
3. **Lottie 资源**控制在 200KB 以内，超出使用雪碧图
4. **录屏前关闭开发者选项的过渡动画**（0.5x → 关闭）
5. **mock 数据种子化**——保证每次启动用户列表稳定，方便演示

---

## 19. 关联文档

- `product_prd.md` 产品 PRD
- 演示视频脚本（在演示视频制作阶段产出）
