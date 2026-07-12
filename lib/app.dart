import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/locale_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/data/repositories.dart';

class NicheTribeApp extends ConsumerStatefulWidget {
  const NicheTribeApp({super.key});

  @override
  ConsumerState<NicheTribeApp> createState() => _NicheTribeAppState();
}

class _NicheTribeAppState extends ConsumerState<NicheTribeApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 系统语言变化 → 跟随系统模式下即时切换应用语言。
  @override
  void didChangeLocales(List<Locale>? locales) {
    ref.read(localeProvider.notifier).syncWithSystem();
  }

  @override
  Widget build(BuildContext context) {
    // 启动即请求定位并按当前位置生成 mock（用户/留言板/活动），全会话只跑一次。
    ref.watch(mockDataBootstrapProvider);

    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'GoBuzz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
