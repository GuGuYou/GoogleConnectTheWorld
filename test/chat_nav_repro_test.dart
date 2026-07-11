// Regression: the full messages flow must navigate and render without
// layout crashes — Profile "Messages" -> chat list -> conversation -> send.
// (A ListTile trailing with `alignment:` once blew the whole list up.)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gobuzz/core/providers/locale_provider.dart';
import 'package:gobuzz/features/chat/chat_list_page.dart';
import 'package:gobuzz/features/chat/chat_page.dart';
import 'package:gobuzz/features/profile/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('profile -> messages -> conversation -> send', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
            path: '/profile',
            builder: (c, s) => const Scaffold(body: ProfilePage())),
        GoRoute(path: '/chat', builder: (c, s) => const ChatListPage()),
        GoRoute(
            path: '/chat/:id',
            builder: (c, s) =>
                ChatPage(conversationId: s.pathParameters['id']!)),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Profile -> Messages (scroll into view first: the wide test font pushes
    // the entries card below the fold).
    final messages = find.text('Messages');
    expect(messages, findsOneWidget);
    await tester.ensureVisible(messages);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(messages);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatListPage), findsOneWidget,
        reason: 'tapping Messages must open the chat list');

    // Chat list renders its tiles (no trailing-layout crash) and taps
    // through to the conversation.
    final tile = find.byType(ListTile);
    expect(tile, findsWidgets, reason: 'conversation tiles must render');
    await tester.tap(tile.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatPage), findsOneWidget,
        reason: 'tapping a conversation must open the chat page');

    // Send a message.
    await tester.enterText(find.byType(TextField), 'hello!');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('hello!'), findsWidgets);

    // Let the simulated reply timer fire so no pending timers leak.
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
