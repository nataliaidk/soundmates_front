import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_design_system.dart';
import 'animated_logo.dart';

/// A unified loading screen widget that can be used throughout the app
/// for all loading moments (initial load, navigation, data fetching, etc.)
///
/// Usage:
/// ```dart
/// // Full screen loading
/// LoadingScreen()
///
/// // With custom message
/// LoadingScreen(message: 'Loading your matches...')
///
/// // Compact version (no tagline)
/// LoadingScreen(compact: true)
/// ```
class LoadingScreen extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;

  /// If true, shows a more compact version without tagline
  final bool compact;

  /// Custom logo size (default: 160 for normal, 120 for compact)
  final double? logoSize;

  const LoadingScreen({
    super.key,
    this.message,
    this.compact = false,
    this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveLogoSize = logoSize ?? (compact ? 120.0 : 160.0);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!compact) const Spacer(flex: 2),

                // Logo
                AnimatedLogo(
                  logoPath: dotenv.env['LOGO_PATH'] ?? 'lib/assets/logo.png',
                  size: effectiveLogoSize,
                ),

                const SizedBox(height: 16),

                // App name
                Text(
                  'SOUNDMATES',
                  style: TextStyle(
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: isDark ? Colors.white : AppColors.textBlack87,
                  ),
                ),

                // Tagline (only in non-compact mode)
                if (!compact) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'The whole music scene. In one app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],

                if (!compact) const Spacer(flex: 2),
                if (compact) const SizedBox(height: 32),

                // Loading indicator
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentPurpleMid,
                    ),
                  ),
                ),

                // Optional message
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textGrey : AppColors.textBlack87,
                    ),
                  ),
                ],

                if (!compact) const SizedBox(height: 48),
                if (compact) const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A smaller loading indicator widget that can be embedded in other screens
/// Use this when you need a loading state within a part of the screen
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? AppColors.accentPurpleMid;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textGrey : AppColors.textBlack87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

