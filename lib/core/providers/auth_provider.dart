import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_provider.dart';

/// 登录态 mock：本地保存一个假 token
final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  static const _key = 'mock_token';

  @override
  bool build() {
    final prefs = ref.read(sharedPrefsProvider);
    return prefs.getString(_key)?.isNotEmpty ?? false;
  }

  Future<void> login() async {
    await ref.read(sharedPrefsProvider).setString(_key, 'mock_token_demo');
    state = true;
  }

  Future<void> logout() async {
    await ref.read(sharedPrefsProvider).remove(_key);
    state = false;
  }
}
