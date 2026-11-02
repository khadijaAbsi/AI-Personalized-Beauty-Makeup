import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../shared/widgets/circle_back_button.dart';
import '../../../shared/widgets/secondary_button.dart';
import '../models/user_profile.dart';
import '../services/mock_profile_service.dart';
import '../services/profile_service.dart';
import '../widgets/profile_analysis_card.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_state_view.dart';
import '../widgets/profile_stat_card.dart';

enum _ProfileStatus { loading, loaded, empty, error }

/// The user's profile. The data comes from a [ProfileService] (a mock for
/// now); the screen only displays it and handles loading, empty and error
/// states. It loads once when opened and never reloads on rebuild.
///
/// Open it with `Navigator.of(context).pushNamed(AppRouter.profile)`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profileService});

  /// Defaults to [MockProfileService]. Pass the real service later.
  final ProfileService? profileService;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _service =
      widget.profileService ?? MockProfileService();

  _ProfileStatus _status = _ProfileStatus.loading;
  UserProfile? _profile;
  String _errorMessage = ProfileException.defaultMessage;

  bool _isLoading = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_isLoading) return; // never two loads at once
    _isLoading = true;
    final requestId = ++_requestId;

    if (_status != _ProfileStatus.loading) {
      setState(() => _status = _ProfileStatus.loading);
    }

    try {
      final profile = await _service.loadProfile();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _profile = profile;
        _status = profile == null ? _ProfileStatus.empty : _ProfileStatus.loaded;
      });
    } on ProfileException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = e.message;
        _status = _ProfileStatus.error;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _errorMessage = ProfileException.defaultMessage;
        _status = _ProfileStatus.error;
      });
    } finally {
      _isLoading = false;
    }
  }

  void _open(String route) => Navigator.of(context).pushNamed(route);

  void _editProfile() =>
      showAppSnackBar(context, 'Profile editing is coming soon.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleBackButton(),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ProfileStatus.loading:
        return const ProfileStateView.loading();
      case _ProfileStatus.empty:
        return const ProfileStateView(
          icon: Icons.person_outline,
          title: 'No profile yet',
          message: "Your profile isn't set up yet. Check back after you've "
              'finished setting up your account.',
        );
      case _ProfileStatus.error:
        return ProfileStateView(
          icon: Icons.cloud_off_outlined,
          title: 'Something went wrong',
          message: _errorMessage,
          actionLabel: 'Retry',
          onAction: _load,
        );
      case _ProfileStatus.loaded:
        return _buildProfile(_profile!);
    }
  }

  Widget _buildProfile(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeader(profile: profile, onEditProfile: _editProfile),
          const SizedBox(height: AppSpacing.md),
          ProfileAnalysisCard(
            analysis: profile.latestFaceAnalysis,
            onAnalyze: () => _open(AppRouter.faceAnalysisGuide),
          ),
          const SizedBox(height: AppSpacing.md),
          // IntrinsicHeight lets both cards share the taller one's height
          // (a stretched Row can't do that inside a scrolling Column).
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ProfileStatCard(
                    label: 'Saved looks',
                    count: profile.savedLooksCount,
                    onTap: () => _open(AppRouter.savedLooks),
                  ),
                ),
                const SizedBox(width: AppSpacing.md - AppSpacing.xs),
                Expanded(
                  child: ProfileStatCard(
                    label: 'Favorite products',
                    count: profile.favoriteProductsCount,
                    onTap: () => _open(AppRouter.favoriteProducts),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: 'Settings & Privacy',
            onPressed: () => _open(AppRouter.settingsPrivacy),
          ),
        ],
      ),
    );
  }
}
