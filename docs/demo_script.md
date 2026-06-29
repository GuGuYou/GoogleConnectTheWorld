# GuGu · 演示视频脚本（2–3 分钟）

> 版本 v0.1 ｜ 风格：赛博霓虹 ｜ 双语字幕（中文主 + English sub）
> 目标：90 秒讲清「痛点 → 解决方案 → 核心体验」，引导评审/早期用户记住产品

---

## 一、整体信息

| 项 | 内容 |
| --- | --- |
| 时长 | 2:30 – 3:00 |
| 画幅 | 竖屏 9:16（手机录屏）；片头/片尾可用 16:9 海报 |
| 配乐 | Synthwave / Future Bass（BPM 100–120，赛博感） |
| 字幕 | 上方中文、下方英文，霓虹描边 |
| 转场 | 故障(glitch) / 霓虹擦除 / 模糊推进 |

---

## 二、分镜脚本（Storyboard）

### 0:00 – 0:15 ｜ Hook 痛点
- **画面**：海报开场（见 `assets/images` 生成的 hero 图）→ 一个人独自盯着屏幕的剪影动画
- **字幕**：「喜欢的东西很小众，身边却没人懂？」 / *"Love niche stuff, but no one around gets it?"*
- **旁白**：内向、宅、爱好小众，想找同好却无从下手。

### 0:15 – 0:30 ｜ 产品登场
- **画面**：录屏 **启动页**（旋转霓虹圆环）→ **引导页** 3 屏滑动
- **字幕**：「NicheTribe — 找到你的同好部落」 / *"NicheTribe — Find Your Niche Tribe"*
- **要点**：LBS 定位 + IP 标签匹配，一句话说清定位。

### 0:30 – 0:45 ｜ 注册 & 选标签
- **画面**：录屏 **登录页**（输入手机号→获取验证码倒计时）→ **标签选择页**（点选原神/咒术回战/塞尔达…发光选中）
- **字幕**：「贴上你的兴趣标签」 / *"Tag what you love"*

### 0:45 – 1:05 ｜ 发现同好（Feed）
- **画面**：录屏 **发现页**，切换距离筛选 1km/5km，瀑布流卡片逐条上滑
- **字幕**：「附近，正有人和你喜欢同一个 IP」 / *"Nearby, someone shares your fandom"*

### 1:05 – 1:30 ｜ 附近匹配 + 地图（核心高光）
- **画面**：
  1. **附近页-列表**：Tinder 卡片右滑「打招呼」，匹配度 92% 徽标特写
  2. 切到 **地图视图**：暗色赛博地图，发光圆点 + 活动菱形 pin，点击弹出底部资料卡
- **字幕**：「按位置 + 兴趣，精准匹配同好」 / *"Match by location + interest"*
- **节奏**：此段配乐推向高潮，是全片记忆点。

### 1:30 – 1:50 ｜ 1v1 聊天
- **画面**：录屏 **聊天页**，发送一条文字 + 一张图片，对方 1.5s 后自动回复（霓虹气泡）
- **字幕**：「聊起来，从同好到搭子」 / *"Chat up, from fans to friends"*

### 1:50 – 2:15 ｜ 线下活动闭环
- **画面**：录屏 **活动中心**（热门轮播）→ **活动详情**（参与者头像堆叠）→ 点「立即报名」→ 「签到」
- **字幕**：「线上兴趣，落地为线下聚会」 / *"Turn online interest into offline meetups"*

### 2:15 – 2:35 ｜ 中英一键切换（差异化）
- **画面**：进入 **设置页**，点击语言 Segmented 从「中文」切到「English」，全屏文案瞬间英化
- **字幕**：「中英双语，一键切换 — 为出海而生」 / *"Bilingual in one tap — built to go global"*

### 2:35 – 3:00 ｜ 收尾 CTA
- **画面**：回到海报，Logo 霓虹脉冲 + Slogan
- **字幕**：「NicheTribe — 你的同好，就在附近」 / *"Your tribe is just around the corner."*
- **CTA**：「即将上线 · 敬请期待」 / *"Coming soon."*

---

## 三、录制指南（Windows）

1. **环境准备**
   - `flutter run -d <device>` 启动到 Android 模拟器或真机（建议 1080×2400 竖屏）。
   - 关闭开发者选项的「窗口/过渡/动画时长」以保证录屏流畅。
2. **录屏工具**
   - Android 真机：`adb shell screenrecord /sdcard/demo.mp4`，或 Xbox Game Bar（Win+G）。
   - 模拟器：Android Studio 自带 Screen Record，或 OBS 捕获模拟器窗口。
3. **按分镜走查**：先手动演练 1–2 遍，确保每个页面数据已加载（mock 已种子化，列表稳定）。
4. **剪辑**：剪映 / Premiere
   - 套用分镜时间轴，关键操作处加放大/高亮。
   - 加中英双语字幕（上中下英），霓虹描边。
   - 配 Synthwave BGM，在 1:05 地图段落对齐鼓点。
5. **导出**：1080×1920，H.264，≤ 60s 可做精简版用于社媒，完整版 2–3 分钟。

---

## 四、素材清单

| 素材 | 来源 | 状态 |
| --- | --- | --- |
| App 录屏（各页面） | `flutter run` 后录制 | 待录（需 Flutter 环境）|
| 片头/片尾海报 | `assets/images/` AI 生成 hero 图 | ✅ 已生成 |
| BGM | 免版税 Synthwave 库（如 Pixabay Music）| 待选 |
| 字幕文案 | 本脚本中英对照 | ✅ 就绪 |

---

## 五、双语字幕速查表

| 时间 | 中文 | English |
| --- | --- | --- |
| 0:00 | 喜欢的东西很小众，身边却没人懂？ | Love niche stuff, but no one around gets it? |
| 0:15 | NicheTribe — 找到你的同好部落 | NicheTribe — Find Your Niche Tribe |
| 0:30 | 贴上你的兴趣标签 | Tag what you love |
| 0:45 | 附近，正有人和你喜欢同一个 IP | Nearby, someone shares your fandom |
| 1:05 | 按位置 + 兴趣，精准匹配同好 | Match by location + interest |
| 1:30 | 聊起来，从同好到搭子 | Chat up, from fans to friends |
| 1:50 | 线上兴趣，落地为线下聚会 | Turn online interest into offline meetups |
| 2:15 | 中英双语，一键切换 — 为出海而生 | Bilingual in one tap — built to go global |
| 2:35 | 你的同好，就在附近 | Your tribe is just around the corner |
