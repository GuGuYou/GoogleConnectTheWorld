import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:g_interest_social/app.dart';
import 'package:g_interest_social/core/providers/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const NicheTribeApp(),
      ),
    );

    // Verify that the splash screen shows the app name.
    // Use pumpAndSettle to allow animations to finish if needed, 
    // or just pump to see the initial frame.
    await tester.pump();
    
    expect(find.text('GuGu'), findsOneWidget);
  });
}
