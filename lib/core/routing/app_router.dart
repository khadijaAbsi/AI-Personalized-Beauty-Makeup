import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/face_analysis/models/selected_photo.dart';
import '../../features/face_analysis/screens/add_portrait_screen.dart';
import '../../features/face_analysis/screens/face_analysis_guide_screen.dart';
import '../../features/face_analysis/screens/face_analysis_processing_screen.dart';
import '../../features/face_analysis/models/face_analysis_results_arguments.dart';
import '../../features/face_analysis/screens/face_analysis_results_screen.dart';
import '../../features/occasion/screens/choose_occasion_placeholder_screen.dart';
import '../../features/profile/screens/profile_placeholder_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_privacy_screen.dart';

/// Named routes. Add new screens here as they are built.
abstract final class AppRouter {
  // '/' is Flutter's default initial route. Using it for the first screen
  // avoids the screen being stacked twice at startup.
  static const String signup = '/';
  static const String login = '/login';
  static const String faceAnalysisGuide = '/face-analysis-guide';
  static const String addPortrait = '/add-portrait';
  static const String faceAnalysisResults = '/face-analysis-results';
  static const String chooseOccasion = '/choose-occasion';

  /// Pass the validated `SelectedPhoto` as `arguments`.
  static const String faceAnalysisProcessing = '/face-analysis-processing';
  static const String profile = '/profile';
  static const String savedLooks = '/saved-looks';
  static const String favoriteProducts = '/favorite-products';
  static const String settingsPrivacy = '/settings-privacy';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case faceAnalysisGuide:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const FaceAnalysisGuideScreen(),
        );
      case addPortrait:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const AddPortraitScreen(),
        );
           case faceAnalysisProcessing:
       return MaterialPageRoute<void>(
         settings: settings,
         builder: (_) {
           final arguments = settings.arguments;
           // Analysis needs a photo; without one, send the user to pick one.
           if (arguments is! SelectedPhoto) return const AddPortraitScreen();
           return FaceAnalysisProcessingScreen(photo: arguments);
         },
       );
     case faceAnalysisResults:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) {
          final arguments = settings.arguments;
          if (arguments is FaceAnalysisResultsArguments) {
            return FaceAnalysisResultsScreen(
              result: arguments.result,
              photo: arguments.photo,
            );
          }
          // Opened without data: shows a friendly message instead of crashing.
          return const FaceAnalysisResultsScreen(result: null);
        },
      );
    case chooseOccasion:
      return MaterialPageRoute<void>(
        settings: settings,
        // Your teammate's real screen replaces ONLY this builder.
        builder: (_) => const ChooseOccasionPlaceholderScreen(),
      );
      case profile:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ProfileScreen(),
      );
    case savedLooks:
      return MaterialPageRoute<void>(
        settings: settings,
        // Temporary: replace this builder when the real screen exists.
        builder: (_) => const ProfilePlaceholderScreen(
          title: 'Saved looks',
          message: 'Your saved looks will appear here once this screen is built.',
        ),
      );
    case favoriteProducts:
      return MaterialPageRoute<void>(
        settings: settings,
        // Temporary: replace this builder when the real screen exists.
        builder: (_) => const ProfilePlaceholderScreen(
          title: 'Favorite products',
          message:
              'Your favorite products will appear here once this screen is built.',
        ),
      );
    case settingsPrivacy:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SettingsPrivacyScreen(),
      );
      case signup:
      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const SignupScreen(),
        );
    }
  }
}
