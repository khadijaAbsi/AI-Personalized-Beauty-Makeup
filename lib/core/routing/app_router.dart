import 'package:flutter/material.dart';

// Authentication UI
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';

// Face analysis
import '../../features/face_analysis/models/selected_photo.dart';
import '../../features/face_analysis/models/face_analysis_results_arguments.dart';
import '../../features/face_analysis/screens/add_portrait_screen.dart';
import '../../features/face_analysis/screens/face_analysis_guide_screen.dart';
import '../../features/face_analysis/screens/face_analysis_processing_screen.dart';
import '../../features/face_analysis/screens/face_analysis_results_screen.dart';

// Home and occasion selection
import '../../features/home/screens/home_dashboard.dart';
import '../../features/home/screens/occasion_selection_page.dart';

// Makeup recommendations
import '../../features/looks/screens/recommended_looks_gallery.dart';

// Products
import '../../features/products/screens/recommended_products_page.dart';

// History and favorites
import '../../features/history/screens/saved_looks_screen.dart';
import '../../features/history/screens/favorite_products_page.dart';
import '../../features/my_looks/screens/my_looks_screen.dart';

// Profile and settings
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_privacy_screen.dart';

/// Centralized named routing for GlowAI.
///
/// Authentication is currently mocked.
/// The Dashboard is the temporary starting screen.
///
/// Real authentication and session handling will be
/// integrated later using Supabase.
abstract final class AppRouter {
  // Authentication
  static const String signup = '/';
  static const String login = '/login';

  // Home
  static const String home = '/home';

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
  static const String settingsPrivacy = '/settings-privacy';

  // History and favorites
  static const String savedLooks = '/saved-looks';
  static const String favoriteProducts = '/favorite-products';
  static const String myLooks = '/my-looks';

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

      // ---------------------------------
      // HOME DASHBOARD
      // ---------------------------------

      case home:
        return _page(settings, const HomeDashboard());

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

      case recommendedProducts:
        return _page(settings, const RecommendedProductsPage());

      // ---------------------------------
      // PROFILE AND SETTINGS
      // ---------------------------------

      case profile:
        return _page(settings, const ProfileScreen());

      case settingsPrivacy:
        return _page(settings, const SettingsPrivacyScreen());

      // ---------------------------------
      // HISTORY AND FAVORITES
      // ---------------------------------

      case savedLooks:
        return _page(settings, const SavedLooksScreen());

      case favoriteProducts:
        return _page(settings, const FavoriteProductsPage());

      case myLooks:
        return _page(settings, const MyLooksScreen());

      // ---------------------------------
      // UNKNOWN ROUTE
      // ---------------------------------

      default:
        return _page(settings, const HomeDashboard());
    }
  }

  /// Reusable helper for creating Material routes.
  static MaterialPageRoute<void> _page(RouteSettings settings, Widget screen) {
    return MaterialPageRoute<void>(settings: settings, builder: (_) => screen);
  }
}
