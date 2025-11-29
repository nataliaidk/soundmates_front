import 'package:flutter/material.dart';
import '../../../theme/app_design_system.dart';

/// Empty state widget displayed when there are no potential matches.
/// Shows either a loading indicator or a "no matches" message with a filter button.
class SwipingEmptyState extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onFilterTap;

  const SwipingEmptyState({
    super.key,
    required this.isLoading,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundFilterStart,
              AppColors.surfaceCardPurple,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.surfaceWhite),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundFilterStart,
            AppColors.surfaceCardPurple,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 80,
                color: AppColors.textWhite70,
              ),
              const SizedBox(height: 24),
              const Text(
                'No Potential Matches',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Try adjusting your preferences to discover more artists and bands',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textWhite70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onFilterTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceWhite,
                  foregroundColor: AppColors.textPurpleDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.3),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune, size: 20),
                    SizedBox(width: 12),
                    Text(
                      'Open Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
