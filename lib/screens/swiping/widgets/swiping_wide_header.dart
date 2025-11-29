import 'package:flutter/material.dart';
import '../../../theme/app_design_system.dart';

/// Wide header widget displayed on desktop screens.
/// Shows the "Discover" title, match headline, and current location.
class SwipingWideHeader extends StatelessWidget {
  final String headline;
  final String locationLabel;

  const SwipingWideHeader({
    super.key,
    required this.headline,
    required this.locationLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textWhite.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.surfaceWhite.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accentPurpleDark, AppColors.accentBlue],
                  ),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.textWhite,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your location',
                    style: TextStyle(
                      color: AppColors.textWhite.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationLabel,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
