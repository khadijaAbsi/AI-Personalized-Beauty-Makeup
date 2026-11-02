import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../models/user_profile.dart';

/// Avatar (with a "Demo" badge for sample data), name, email and Edit profile.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  final UserProfile profile;
  final VoidCallback onEditProfile;

  static const double _avatarSize = 96;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final email = profile.email;

    return Column(
      children: [
        SizedBox.square(
          dimension: _avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _Avatar(url: profile.avatarUrl)),
              if (profile.isMock)
                const Positioned(top: 8, left: 8, child: _DemoBadge()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          profile.name ?? 'Your profile',
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium,
        ),
        if (email != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            profile.isMock ? '$email (sample)' : email,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        TextButton(onPressed: onEditProfile, child: const Text('Edit profile')),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    const placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.blush, AppColors.accent],
        ),
      ),
    );
    final url = this.url;

    return Semantics(
      image: true,
      label: 'Profile picture',
      child: ClipOval(
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Demo',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
      ),
    );
  }
}
