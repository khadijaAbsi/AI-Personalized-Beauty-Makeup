import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Saved Looks screen displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SavedLooksScreen()));

    expect(find.text('Saved Looks'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Soft Glam'), findsOneWidget);
    expect(find.text('Everyday Glow'), findsOneWidget);
  });
}
