import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../theme/app_design_system.dart';

/// Empty state widget displayed when there are no potential matches.
/// Shows either a loading indicator or a "no matches" message with a filter button.
class SwipingEmptyState extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onFilterTap;

  const SwipingEmptyState({
    super.key,
    required this.isLoading,
    required this.onFilterTap,
  });

  @override
  State<SwipingEmptyState> createState() => _SwipingEmptyStateState();
}

class _SwipingEmptyStateState extends State<SwipingEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _showLoading = widget.isLoading;
  }

  @override
  void didUpdateWidget(SwipingEmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When loading completes, start fade out animation
    if (oldWidget.isLoading && !widget.isLoading) {
      // Add a small delay before starting fade to ensure minimum display time
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showLoading = false;
              });
            }
          });
        }
      });
    }
    // If loading starts again, reset
    if (!oldWidget.isLoading && widget.isLoading) {
      _fadeController.reset();
      setState(() {
        _showLoading = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show loading screen with fade out
    if (_showLoading) {
      return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimation),
        child: Container(
          color: isDark ? AppColors.backgroundDark : AppColors.surfaceWhite,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  dotenv.env['LOGO_PATH'] ?? 'lib/assets/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                // Loading text
                Text(
                  'Finding matches...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textWhite70 : AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),
                // Loading indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPurpleMid),
                  ),
                ),
              ],
            ),
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
                onPressed: widget.onFilterTap,
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
                  shadowColor: Colors.black.withValues(alpha: 0.3),
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
