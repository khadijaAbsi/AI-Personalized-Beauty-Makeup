import 'package:flutter/material.dart';

// Authentication UI
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/auth_gate.dart';

// Face analysis
import '../../features/face_analysis/models/selected_photo.dart';
import '../../features/face_analysis/models/face_analysis_results_arguments.dart';
import '../../features/face_analysis/screens/add_portrait_screen.dart';
import '../../features/face_analysis/screens/face_analysis_guide_screen.dart';
import '../../features/face_analysis/screens/face_analysis_processing_screen.dart';
import '../../features/face_analysis/screens/face_analysis_results_screen.dart';

// Home and occasion selection
import '../../features/home/screens/how_glowai_works_screen.dart';
import '../../features/home/screens/occasion_selection_page.dart';

// Makeup recommendations
import '../../features/looks/screens/recommended_looks_gallery.dart';

// Products
import '../../features/products/screens/recommended_products_page.dart';

// History and favorites
import '../../features/my_looks/screens/my_looks_screen.dart';

// Profile and settings

// Persistent bottom-navigation shell
import 'main_shell.dart';
import 'main_shell_scope.dart';

/// Centralized named routing for GlowAI.
///
/// Authentication is handled by Supabase (see `AuthGate`).
///
/// Home, Explore, Saved Looks, Favorites and Profile are the five tabs of the
/// persistent [MainShell]; their route names open the shell on that tab.
abstract final class AppRouter {
  // Authentication
  static const String signup = '/';
  static const String login = '/login';
  static const String authGate = '/auth';

  // Main tabs (all of these open the persistent bottom-navigation shell)
  static const String home = '/home';
  static const String explore = '/explore';
  // savedLooks, favoriteProducts and profile are declared below; they are
  // tabs of the same shell.

  // Home extras
  static const String howItWorks = '/how-it-works';

  // Face analysis
  static const String faceAnalysisGuide = '/face-analysis-guide';
  static const String addPortrait = '/add-portrait';
  static const String faceAnalysisProcessing = '/face-analysis-processing';
  static const String faceAnalysisResults = '/face-analysis-results';

  // Occasion and recommendations
  static const String chooseOccasion = '/choose-occasion';
  static const String recommendedLooks = '/recommended-looks';
  static const String recommendedProducts = '/recommended-products';

  // Profile
  static const String profile = '/profile';

  // History and favorites
  static const String savedLooks = '/saved-looks';
  static const String favoriteProducts = '/favorite-products';
  static const String myLooks = '/my-looks';

  /// The named route that opens the shell on [tab].
  static String routeForTab(MainTab tab) {
    switch (tab) {
      case MainTab.home:
        return home;
      case MainTab.explore:
        return explore;
      case MainTab.savedLooks:
        return savedLooks;
      case MainTab.favorites:
        return favoriteProducts;
      case MainTab.profile:
        return profile;
    }
  }

  /// Leaves any full-screen flow and shows the main shell on [tab].
  ///
  /// Clears the stack so there is exactly one shell and one bar. Use it from
  /// screens that are not tabs themselves (for example the final try-on
  /// results). Inside the shell, use the controller from [MainShellScope]
  /// instead, which switches tabs without touching the Navigator.
  static Future<void> goToTab(BuildContext context, MainTab tab) {
    return Navigator.of(context)
        .pushNamedAndRemoveUntil(routeForTab(tab), (route) => false);
  }

  /// Generates the appropriate screen for each named route.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ---------------------------------
      // AUTHENTICATION
      // ---------------------------------

      case signup:
        return _page(settings, const SignupScreen());

      case login:
        return _page(settings, const LoginScreen());

      case authGate:
        return _page(settings, const AuthGate());

      // ---------------------------------
      // HOME DASHBOARD
      // ---------------------------------

      case home:
        return _page(settings, const MainShell(initialTab: MainTab.home));

      case howItWorks:
        return _page(settings, const HowGlowAiWorksScreen());

      // ---------------------------------
      // FACE ANALYSIS
      // ---------------------------------

      case faceAnalysisGuide:
        return _page(settings, const FaceAnalysisGuideScreen());

      case addPortrait:
        return _page(settings, const AddPortraitScreen());

      case faceAnalysisProcessing:
        final arguments = settings.arguments;

        // Processing requires a validated photo.
        if (arguments is! SelectedPhoto) {
          return _page(settings, const AddPortraitScreen());
        }

        return _page(settings, FaceAnalysisProcessingScreen(photo: arguments));

      case faceAnalysisResults:
        final arguments = settings.arguments;

        if (arguments is FaceAnalysisResultsArguments) {
          return _page(
            settings,
            FaceAnalysisResultsScreen(
              result: arguments.result,
              photo: arguments.photo,
            ),
          );
        }

        // Prevent crashes if opened without result data.
        return _page(settings, const FaceAnalysisResultsScreen(result: null));

      // ---------------------------------
      // OCCASION SELECTION
      // ---------------------------------

      case chooseOccasion:
        final arguments = settings.arguments;

        // Dashboard may pass a selected occasion as a String.
        if (arguments is String) {
          return _page(
            settings,
            OccasionSelectionPage(initialOccasion: arguments),
          );
        }

        // Face Analysis Results passes the analysis data.
        if (arguments is FaceAnalysisResultsArguments) {
          return _page(settings, const OccasionSelectionPage());
        }

        // Opened without arguments.
        return _page(settings, const OccasionSelectionPage());

      // ---------------------------------
      // MAKEUP RECOMMENDATIONS
      // ---------------------------------

      case recommendedLooks:
        final arguments = settings.arguments;

        // Recommended looks require an occasion.
        if (arguments is String && arguments.isNotEmpty) {
          return _page(settings, RecommendedLooksGallery(occasion: arguments));
        }

        // No occasion supplied:
        // let the user select one first.
        return _page(settings, const OccasionSelectionPage());

      // Standalone product list (pushed, with its own Back button).
      // The Explore tab shows the same page inside the shell.
      case recommendedProducts:
        return _page(settings, const RecommendedProductsPage());

      case explore:
        return _page(settings, const MainShell(initialTab: MainTab.explore));

      // ---------------------------------
      // PROFILE AND SETTINGS
      // ---------------------------------

      case profile:
        return _page(settings, const MainShell(initialTab: MainTab.profile));

      // ---------------------------------
      // HISTORY AND FAVORITES
      // ---------------------------------

      case savedLooks:
        return _page(settings, const MainShell(initialTab: MainTab.savedLooks));

      case favoriteProducts:
        return _page(settings, const MainShell(initialTab: MainTab.favorites));

      case myLooks:
        return _page(settings, const MyLooksScreen());

      // ---------------------------------
      // UNKNOWN ROUTE
      // ---------------------------------

      default:
        return _page(settings, const MainShell(initialTab: MainTab.home));
    }
  }

  /// Reusable helper for creating Material routes.
  static MaterialPageRoute<void> _page(RouteSettings settings, Widget screen) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
  }
}
