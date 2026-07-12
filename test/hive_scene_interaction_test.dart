import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobuzz/core/providers/locale_provider.dart';
import 'package:gobuzz/features/space/hive_scene/hive_render_scene.dart';
import 'package:gobuzz/features/space/hive_scene/scene_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scene interactions: each of the four hive regions must report a tap,
/// and the locale provider must follow the system unless overridden.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> prefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  List<SceneRoom> rooms() => SceneRoom.defaultRooms(
        List.filled(6, Offset.zero),
        List.filled(6, Offset.zero),
      );

  testWidgets('tapping the four scene regions fires the right callbacks',
      (tester) async {
    final p = await prefs();
    // Portrait surface so the layout matches a phone.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final tapped = <int>[];
    var globalChat = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(p)],
        child: MaterialApp(
          home: HiveRenderScene(
            rooms: rooms(),
            onRoomTap: tapped.add,
            onGlobalChatTap: () => globalChat++,
          ),
        ),
      ),
    );

    const w = 400.0, h = 800.0; // logical size (Hive.svg honeycomb layout)
    await tester.tapAt(const Offset(0.486 * w, 0.153 * h)); // game
    await tester.tapAt(const Offset(0.279 * w, 0.368 * h)); // movie
    await tester.tapAt(const Offset(0.692 * w, 0.368 * h)); // music
    await tester.tapAt(const Offset(0.5 * w, 0.75 * h)); // local chat panel
    await tester.pump();

    expect(tapped, [0, 1, 3],
        reason: 'game→rooms[0], movie→rooms[1], music→rooms[3]');
    expect(globalChat, 1);
  });

  testWidgets(
      'landscape: room taps are not stolen by the global-chat region',
      (tester) async {
    final p = await prefs();
    // Short & wide surface — the regression found in review: the old
    // rectangle-stack hit areas let the chat rect cover the music octagon.
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final tapped = <int>[];
    var globalChat = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(p)],
        child: MaterialApp(
          home: HiveRenderScene(
            rooms: rooms(),
            onRoomTap: tapped.add,
            onGlobalChatTap: () => globalChat++,
          ),
        ),
      ),
    );

    const w = 800.0, h = 400.0;
    await tester.tapAt(const Offset(0.692 * w, 0.368 * h)); // music center
    await tester.tapAt(const Offset(0.486 * w, 0.153 * h)); // game center
    await tester.pump();

    expect(tapped, [3, 0],
        reason: 'octagon taps must reach their rooms even in landscape');
    expect(globalChat, 0);
  });

  test('locale follows system by default and honors manual override',
      () async {
    final p = await prefs();
    final c = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(p)]);
    addTearDown(c.dispose);

    final system = LocaleNotifier.systemLocale();
    // 未手动选择过 → 跟随系统
    expect(c.read(localeProvider), system);
    expect(c.read(localeProvider.notifier).followsSystem, isTrue);

    // 手动选择 → 覆盖系统并持久化
    await c.read(localeProvider.notifier).setLocale('zh');
    expect(c.read(localeProvider).languageCode, 'zh');
    expect(c.read(localeProvider.notifier).followsSystem, isFalse);
    expect(p.getString('app_locale'), 'zh');

    // 手动模式下系统变化不影响
    c.read(localeProvider.notifier).syncWithSystem();
    expect(c.read(localeProvider).languageCode, 'zh');

    // 回到跟随系统
    await c.read(localeProvider.notifier).followSystem();
    expect(c.read(localeProvider.notifier).followsSystem, isTrue);
    expect(c.read(localeProvider), system);
    expect(p.getString('app_locale'), isNull);
  });
}
