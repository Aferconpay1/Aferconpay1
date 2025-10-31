// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AferconPayApp());

    // The actual content will depend on the initial state of the app (e.g., loading screen, login screen).
    // For now, we'll just verify that the app builds without crashing.
    expect(find.byType(AferconPayApp), findsOneWidget);
  });
}
