# GuGu · 兴趣社交 App（高保真原型）

> 基于 **LBS + IP 标签匹配** 的陌生人兴趣社交产品 · Flutter 高保真原型
> 风格：**Cyber Neon 赛博霓虹**（深紫底 + 霓虹粉/青/紫渐变 + 玻璃拟态）
> 数据：全量 **Mock 驱动**，无需后端即可端到端体验

---

## ✨ 已实现功能（6 大核心模块）

| 模块 | 说明 |
| --- | --- |
| 启动 / 引导 / 登录 | 赛博风启动动画 → 3 页引导 → 手机号验证码登录（mock 倒计时）→ 兴趣标签选择 |
| IP 标签体系 | 游戏 / 动漫 / 剧集 / 漫画 / 音乐 五大分类，分类配色 + 发光 Chip |
| 发现 Feed 流 | 兴趣内容卡 + 距离筛选（1/5/10km/全城）+ 占位图网格 |
| 附近同好 | Tinder 风格匹配卡左右滑（含匹配度）+ 地图视图（flutter_map + OSM，暗色赛博滤镜，发光圆点/活动菱形 pin）|
| 标签匹配推荐 | 基于 Jaccard 兴趣重合度计算匹配度，按匹配度 + 距离排序 |
| 1v1 IM 聊天 | 文字 / 图片消息，自己渐变气泡、对方玻璃气泡，对方自动延迟回复 |
| 活动中心 | 热门轮播 + 活动列表 + 详情（参与者头像堆叠）+ 报名 / 签到 + 发布表单（含日期选择）|
| 个人中心 | Hero 资料卡 + 标签墙 + 编辑资料 + 设置 |
| 中英双语 | 一键切换中 / 英，全 App 文案实时刷新并持久化 |

---

## 🛠 技术栈

- **Flutter 3.22+ / Dart 3.4+**
- **Riverpod 2.5** 状态管理
- **go_router 14** 声明式路由 + `StatefulShellRoute` 底部 4 Tab
- **flutter_map 7 + latlong2** 地图（OpenStreetMap 瓦片，零成本）
- **flutter_animate** 微交互动效
- **flutter_card_swiper** 卡片滑动
- **google_fonts**（Rajdhani + Noto Sans SC）
- **shared_preferences** 语言 / 登录态持久化
- 自研 **Map 式 i18n**（无需 gen-l10n 代码生成）+ 纯 Dart 不可变模型（无需 build_runner）

> 设计为「开箱即跑」：**不依赖任何代码生成步骤**，`pub get` 后即可运行。

---

## 🚀 运行方式

```bash
# 1. 安装依赖
flutter pub get

# 2. 运行（连接模拟器或真机）
flutter run

# 3. 打 Debug 包
flutter build apk --debug        # Android
flutter build ios --debug        # iOS（需 macOS）
```

> 首次运行 `google_fonts` 会在线拉取字体；如需离线，可将字体放入 `assets/fonts/` 并在 `pubspec.yaml` 声明。

---

## 📁 目录结构

```
lib/
├── main.dart                  # 入口（ProviderScope + SharedPreferences override）
├── app.dart                   # MaterialApp.router + 主题 + Locale
├── core/                      # 主题 / 路由 / i18n / Provider / 工具
│   ├── theme/                 # 赛博霓虹色板、字体、ThemeData
│   ├── router/app_router.dart # go_router + ShellRoute
│   ├── l10n/app_text.dart     # 中英文案表 + ref.tr() 扩展
│   ├── providers/             # locale / auth Provider
│   └── utils/                 # Haversine 距离、扩展
├── shared/
│   ├── models/                # IpTag / UserProfile / ActivityItem / ChatMessage / FeedPost
│   ├── data/                  # MockDataSource（50 用户 + 20 活动）+ Repositories(Provider)
│   └── widgets/               # NeonButton / GlassCard / IpTagChip / AvatarPlaceholder ...
└── features/                  # 按 feature 组织
    ├── splash / onboarding / auth
    ├── discover / nearby
    ├── chat / activity / profile
```

---

## 🎬 演示

详见 `docs/demo_script.md` 分镜脚本与录制指南。

## 📚 关联文档

- `docs/product_prd.md` 产品需求文档
- `docs/tech_selection.md` 技术选型清单
- `docs/demo_script.md` 演示视频脚本
