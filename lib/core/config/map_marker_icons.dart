import 'package:flutter/material.dart';

/// 地图标记图标配置。
///
/// 修改 [activity]、[wallMessage]、[nearbyUser] 即可切换地图上的图标。
/// 下方 [presets] 列出常用备选，复制 codePoint 对应的图标名到上方即可。
///
/// ## 可选图标库（在 pubspec.yaml 添加依赖后替换 IconData 来源）
///
/// | 库 | pub 包名 | 风格 | 地图适用性 |
/// |---|---|---|---|
/// | Material Icons | 内置 `Icons.*` | Google 标准 | ★★★★★ 零依赖，已接入 |
/// | Phosphor | `phosphor_flutter` | 6 种粗细，现代圆润 | ★★★★★ 推荐扩展 |
/// | Font Awesome | `font_awesome_flutter` | 经典品牌/通用 | ★★★★ |
/// | Lucide | `lucide_icons` | 线条简洁 | ★★★★ |
/// | Remix Icon | `remixicon` | 中性全面 | ★★★★ |
/// | Cupertino | 内置 `CupertinoIcons.*` | iOS 风格 | ★★★ |
///
/// 换库示例（Phosphor）：
/// ```dart
/// import 'package:phosphor_flutter/phosphor_flutter.dart';
/// static final activity = PhosphorIcons.calendarStar(PhosphorIconsStyle.fill);
/// ```
class MapMarkerIcons {
  MapMarkerIcons._();

  // ---- 当前选用（改这里）----
  // 保存后热重载即可；若仍不变请 Hot Restart（Ctrl+Shift+F5）
  static const IconData activity = Icons.local_activity;
  static const IconData wallMessage = Icons.event_note;
  static const IconData nearbyUser = Icons.emoji_people;

  /// 活动 Pin 主色：琥珀橙（暖调，在蜂蜜金底图上醒目且与主题一致）。
  static const Color activityColor = Color(0xFFFF8F1F);

  /// 留言板默认色：蜂蜜金（介于用户薄荷青与活动琥珀橙之间，对应品牌渐变中段）。
  static const Color wallDefaultColor = Color(0xFFFFD84A);

  /// 活动 Pin 备选
  static const activityPresets = <(String, IconData)>[
    ('local_activity', Icons.local_activity),
    ('event', Icons.event),
    ('celebration', Icons.celebration),
    ('festival', Icons.festival),
    ('pin_drop', Icons.pin_drop),
    ('place', Icons.place),
    ('star', Icons.star),
    ('sports_esports', Icons.sports_esports),
  ];

  /// 留言墙 Pin 备选（六边形，与活动/用户一致）
  static const wallPresets = <(String, IconData)>[
    ('chat_bubble_rounded', Icons.chat_bubble_rounded),
    ('forum', Icons.forum),
    ('message', Icons.message),
    ('sticky_note_2', Icons.sticky_note_2),
    ('campaign', Icons.campaign),
    ('record_voice_over', Icons.record_voice_over),
    ('maps_ugc', Icons.maps_ugc),
  ];

  /// 附近用户光点备选（若从 Circle 改为 Marker 时使用）
  static const nearbyUserPresets = <(String, IconData)>[
    ('brightness_1', Icons.brightness_1),
    ('person_pin_circle', Icons.person_pin_circle),
    ('radio_button_checked', Icons.radio_button_checked),
    ('fiber_manual_record', Icons.fiber_manual_record),
    ('blur_on', Icons.blur_on),
    ('adjust', Icons.adjust),
  ];
}
