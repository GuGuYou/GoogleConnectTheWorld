import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 单例 Provider（在 main 中 override）
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// 语言 Provider：默认跟随系统语言；用户手动选择后持久化并优先生效。
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.read(sharedPrefsProvider);
    final code = prefs.getString(_key);
    if (code != null) return Locale(code);
    return systemLocale();
  }

  // followSystem() 可能把 state 设回相同的 Locale（此时仍需要通知
  // Settings 页刷新"跟随系统"高亮），所以始终通知。
  @override
  bool updateShouldNotify(Locale previous, Locale next) => true;

  /// 系统语言 → 应用支持的语言（zh / en）
  static Locale systemLocale() {
    final sys = ui.PlatformDispatcher.instance.locale;
    return Locale(sys.languageCode == 'zh' ? 'zh' : 'en');
  }

  /// 是否处于跟随系统模式（未手动选择过语言）
  bool get followsSystem =>
      ref.read(sharedPrefsProvider).getString(_key) == null;

  Future<void> setLocale(String code) async {
    state = Locale(code);
    await ref.read(sharedPrefsProvider).setString(_key, code);
  }

  /// 清除手动选择，回到跟随系统。
  Future<void> followSystem() async {
    await ref.read(sharedPrefsProvider).remove(_key);
    state = systemLocale();
  }

  /// 系统语言变化时调用（App 生命周期回调）；仅跟随系统模式下生效。
  void syncWithSystem() {
    if (!followsSystem) return;
    final sys = systemLocale();
    if (sys != state) state = sys;
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'zh' ? 'en' : 'zh';
    await setLocale(next);
  }
}
