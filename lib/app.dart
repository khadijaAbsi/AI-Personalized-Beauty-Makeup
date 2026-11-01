import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class GlowAiApp extends StatelessWidget {
  const GlowAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // initialRoute: AppRouter.signup,
      initialRoute: AppRouter.faceAnalysisGuide,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
