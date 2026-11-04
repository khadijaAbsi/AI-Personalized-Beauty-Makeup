import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/features/history/screens/saved_looks_screen.dart';

void main() {
  testWidgets('Saved Looks screen displays its title', (tester) async {
    // A newly registered user should not be shown hardcoded sample looks.
    // The data-loading behavior is covered separately with mocked services.
    await tester.pumpWidget(const MaterialApp(home: SavedLooksScreen()));

    expect(find.text('Saved Looks'), findsOneWidget);
    expect(find.text('Soft Glam'), findsNothing);
    expect(find.text('Everyday Glow'), findsNothing);
  });
}
