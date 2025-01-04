import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set up shared preferences for testing
    SharedPreferences.setMockInitialValues({});
    final settings = await SettingsService.create();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(settings: settings));

    // Verify basic app structure
    expect(find.text('Taxi Job Tracker'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // Verify empty state message
    expect(find.text('No jobs yet'), findsOneWidget);
    expect(find.text('Tap the menu button to get started'), findsOneWidget);
  });
}
