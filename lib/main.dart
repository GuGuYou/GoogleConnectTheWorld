import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/map_config.dart';
import 'core/providers/locale_provider.dart';
import 'features/avatar/widgets/layered_avatar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MapConfig.loadApiKey();
  final prefs = await SharedPreferences.getInstance();
  // 预热头像部件位图（地图 marker 需要同步绘制）；不阻塞启动。
  // ignore: unawaited_futures
  AvatarPartCache.preload();
  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const NicheTribeApp(),
    ),
  );
}
