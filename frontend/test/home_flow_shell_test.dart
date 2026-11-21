import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glowai/core/routing/app_router.dart';
import 'package:glowai/core/routing/main_shell.dart';
import 'package:glowai/core/routing/main_shell_scope.dart';
import 'package:glowai/features/face_analysis/models/face_analysis_results_arguments.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_guide_screen.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_processing_screen.dart';
import 'package:glowai/features/face_analysis/screens/face_analysis_results_screen.dart';
import 'package:glowai/shared/widgets/circle_back_button.dart';
import 'package:glowai/features/face_analysis/services/mock_face_analysis_result.dart';
import 'package:glowai/features/home/screens/home_dashboard.dart';
import 'package:glowai/features/home/screens/occasion_selection_page.dart';

/// The Home tab uses its real implementation (Dashboard + flow navigator);
/// the other tabs are stand-ins so no Supabase session is needed.
Map<MainTab, WidgetBuilder> _tabs() => {
  for (final tab in MainTab.values)
    if (tab != MainTab.home)
      tab: (_) => Scaffold(body: Center(child: Text('tab-${tab.name}'))),
};

Finder _barItem(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

int _selectedIndex(WidgetTester tester) => tester
    .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
    .currentIndex;

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.devicePixelRatio = 3.0;
  tester.view.physicalSize = const Size(390, 844) * 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: MainShell(tabBuilders: _tabs()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _showResults(WidgetTester tester) async {
  MainShellController.active!.homeNavigator!.pushNamed(
    AppRouter.faceAnalysisResults,
    arguments: FaceAnalysisResultsArguments(result: mockFaceAnalysisResult),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Face Analysis Results shows the bar and Continue, not overlapping',
    (tester) async {
      await _pumpShell(tester);
      await _showResults(tester);

      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(_selectedIndex(tester), MainTab.home.index);

      final continueBottom = tester.getBottomLeft(find.text('Continue')).dy;
      final barTop = tester.getTopLeft(find.byType(BottomNavigationBar)).dy;
      expect(continueBottom, lessThanOrEqualTo(barTop));
      expect(tester.takeException(), isNull);
    },
  );

  // The Looks gallery itself needs a live Supabase session (saved-looks
  // service), so this test stops at the occasion screen; the gallery is
  // pushed through the same Home navigator.
  testWidgets('Continue still opens occasion selection, with the bar visible', (
    tester,
  ) async {
    await _pumpShell(tester);
    await _showResults(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(OccasionSelectionPage), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(_selectedIndex(tester), MainTab.home.index);
  });

  testWidgets('switching tabs keeps the flow, and coming back shows it again', (
    tester,
  ) async {
    await _pumpShell(tester);
    await _showResults(tester);
    final stateBefore = tester.state(find.byType(FaceAnalysisResultsScreen));

    await tester.tap(_barItem('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('tab-explore'), findsOneWidget);
    expect(_selectedIndex(tester), MainTab.explore.index);

    await tester.tap(_barItem('Home'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    expect(
      identical(
        tester.state(find.byType(FaceAnalysisResultsScreen)),
        stateBefore,
      ),
      isTrue,
    );
    // No stacked bars, no extra routes on the root navigator.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('tapping Home on a flow screen returns to the Dashboard', (
    tester,
  ) async {
    await _pumpShell(tester);
    await _showResults(tester);

    await tester.tap(_barItem('Home'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
    expect(find.byType(HomeDashboard), findsOneWidget);
  });

  testWidgets(
    'system Back closes the flow screen first, then goes back through '
    'tabs',
    (tester) async {
      await _pumpShell(tester);
      await _showResults(tester);
      await tester.tap(_barItem('Profile'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute(); // Profile -> Home (flow intact)
      await tester.pumpAndSettle();
      expect(_selectedIndex(tester), MainTab.home.index);
      expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);

      await tester.binding.handlePopRoute(); // closes Results
      await tester.pumpAndSettle();
      expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
      expect(find.byType(HomeDashboard), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    },
  );

  testWidgets('Analyze My Face opens full screen, without the bar', (
    tester,
  ) async {
    await _pumpShell(tester);

    await tester.tap(find.text('Analyze My Face'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisGuideScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('finishing the analysis hands over to Results with the bar', (
    tester,
  ) async {
    await _pumpShell(tester);

    // Stand-in for the processing screen: a full-screen route above the shell.
    final root = tester.state<NavigatorState>(find.byType(Navigator).first);
    root.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('processing')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('processing'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    MainShellController.active!.openInHomeFlow(
      root,
      AppRouter.faceAnalysisResults,
      arguments: FaceAnalysisResultsArguments(result: mockFaceAnalysisResult),
    );
    await tester.pumpAndSettle();

    expect(find.text('processing'), findsNothing);
    expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(_selectedIndex(tester), MainTab.home.index);
  });

  testWidgets('Results -> Favorites goes straight there, without the flow '
      'screens in between', (tester) async {
    await _pumpShell(tester);
    await _showResults(tester);

    await tester.tap(_barItem('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('tab-favorites'), findsOneWidget);
    expect(_selectedIndex(tester), MainTab.favorites.index);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('the visible Back button on Results returns to the Dashboard, '
      'not the processing screen', (tester) async {
    await _pumpShell(tester);
    await _showResults(tester);

    await tester.tap(find.byType(CircleBackButton));
    await tester.pumpAndSettle();

    expect(find.byType(FaceAnalysisResultsScreen), findsNothing);
    expect(find.byType(HomeDashboard), findsOneWidget);
    expect(find.byType(FaceAnalysisProcessingScreen), findsNothing);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('Back from a screen after Occasion returns to Occasion with the '
      'selection kept', (tester) async {
    await _pumpShell(tester);
    await _showResults(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Casual'));
    await tester.pump();

    // Stand-in for Recommended Looks (the real gallery needs Supabase).
    MainShellController.active!.homeNavigator!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('looks-stand-in')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.binding.handlePopRoute(); // Android Back
    await tester.pumpAndSettle();

    expect(find.text('looks-stand-in'), findsNothing);
    expect(find.byType(OccasionSelectionPage), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    await tester.binding.handlePopRoute(); // Occasion -> Results
    await tester.pumpAndSettle();
    expect(find.byType(FaceAnalysisResultsScreen), findsOneWidget);
  });

  testWidgets('the bar and Continue are visible on a narrow phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(320, 568) * 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: MainShell(tabBuilders: _tabs()),
      ),
    );
    await tester.pumpAndSettle();
    await _showResults(tester);

    final barTop = tester.getTopLeft(find.byType(BottomNavigationBar)).dy;
    expect(find.text('Continue').hitTestable(), findsOneWidget);
    expect(
      tester.getBottomLeft(find.text('Continue')).dy,
      lessThanOrEqualTo(barTop),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the active shell is cleared when the shell goes away', (
    tester,
  ) async {
    await _pumpShell(tester);
    expect(MainShellController.active, isNotNull);

    await tester.pumpWidget(const SizedBox());

    expect(MainShellController.active, isNull);
  });
}
