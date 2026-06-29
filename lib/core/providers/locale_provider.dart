import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 单例 Provider（在 main 中 override）
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

/// 语言 Provider：一键切换中 / 英并持久化
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.read(sharedPrefsProvider);
    final code = prefs.getString(_key) ?? 'zh';
    return Locale(code);
  }

  Future<void> setLocale(String code) async {
    state = Locale(code);
    await ref.read(sharedPrefsProvider).setString(_key, code);
  }

  Future<void> toggle() async {
    final next = state.languageCode == 'zh' ? 'en' : 'zh';
    await setLocale(next);
  }
}
