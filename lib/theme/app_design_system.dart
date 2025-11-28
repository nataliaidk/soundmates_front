import 'package:flutter/material.dart';

/// Centralized Design System for SoundMates
///
/// This file contains all styling constants used throughout the app:
/// - Colors (backgrounds, accents, text, surfaces, status)
/// - Gradients (purple, chat, profile, audio)
/// - Box Shadows (soft, medium, glow, purple, message bubble)
/// - Text Styles (headings, body, captions)
/// - Border Radius (small, medium, large, circle)
///
/// Usage: Import this file and use static constants instead of hardcoded values.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============ Background Colors ============
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color backgroundDarkAlt = Color(0xFF1A1525);
  static const Color backgroundLight = Color(0xFFF8F9FC);
  static const Color backgroundLightAlt = Color(0xFFF5F6FB);
  static const Color backgroundLightPurple = Color(0xFFF9F4FF);
  static const Color surfaceWhite = Colors.white;

  // ============ Accent Colors ============
  static const Color accentPurple = Color(0xFF7B51D3);
  static const Color accentPurpleLight = Color(0xFF9C6BFF);
  static const Color accentPurpleDark = Color(0xFF7C4DFF);
  static const Color accentPurpleMid = Color(0xFF6B4CE6);
  static const Color accentPurpleSoft = Color(0xFF9D7CE6);
  static const Color accentRed = Color(0xFFD32F2F);

  // ============ Surface Colors ============
  static const Color surfaceDark = Color(0xFF2A2D3E);
  static const Color surfaceDarkAlt = Color(0xFF2A2438);
  static const Color surfaceDarkGrey = Color(0xFF4A4A6A);

  // ============ Text Colors ============
  static const Color textPrimary = Color(0xFF1F2430);
  static const Color textPrimaryAlt = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4C4F72);
  static const Color textPlaceholder = Color(0xFF9EA3B5);
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Colors.white70;
  static const Color textBlack87 = Colors.black87;
  static const Color textGrey = Colors.grey;

  // ============ Status Colors ============
  static const Color statusOnline = Color(0xFF40C057);
  static const Color statusOnlineAlt = Colors.greenAccent;
  static const Color statusSeen = Color(0xFF7C4DFF);

  // ============ Utility Colors ============
  static const Color borderLight = Color(0xFFE0E4F0);
  static const Color borderLightAlt = Color(0xFFE0E7FF);
  static const Color chipBorder = Color(0xFFE0E0E0);
  static const Color dividerLight =
      Colors.grey; // Will use .shade200 dynamically

  // ============ Avatar & Profile ============
  static const Color avatarBackground = Color(0xFFE0E7FF);
}

class AppGradients {
  AppGradients._();

  // ============ Purple Gradients ============
  /// Primary purple gradient for buttons and message bubbles
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF9C6BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Alternative purple gradient for send button
  static const LinearGradient purpleGradientAlt = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFF9C6BFF)],
  );

  // ============ Background Gradients ============
  /// Subtle chat screen background gradient
  static const LinearGradient chatBackgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFEEF1FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Dark purple gradient for terms of service card
  static const LinearGradient darkPurpleGradient = LinearGradient(
    colors: [Color(0xFF463A63), Color(0xFF5B4B78)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Profile header gradient overlay (dark to darker)
  static LinearGradient profileHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.black.withOpacity(0.0),
      Colors.black.withOpacity(0.1),
      Colors.black.withOpacity(0.5),
      Colors.black.withOpacity(0.85),
      Colors.black.withOpacity(0.95),
    ],
    stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
  );

  /// Profile picture border gradient (purple to blue)
  static LinearGradient profilePictureBorderGradient = LinearGradient(
    colors: [Colors.purple.shade300, Colors.blue.shade300],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ Media Gradients ============
  /// Gradient for audio media placeholders
  static LinearGradient audioPlaceholderGradient(Color accentColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accentColor.withOpacity(0.7), accentColor.withOpacity(0.4)],
    );
  }

  /// Video overlay gradient (transparent to dark)
  static LinearGradient videoOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.2)],
  );
}

class AppShadows {
  AppShadows._();

  // ============ Standard Shadows ============
  /// Soft shadow for cards and elevated surfaces
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  /// Soft shadow variant for input fields
  static List<BoxShadow> softShadowAlt = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, -2),
    ),
  ];

  /// Medium shadow for elevated elements
  static List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Shadow for media grid items
  static List<BoxShadow> mediaShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ============ Colored Shadows ============
  /// Purple glow shadow for primary buttons
  static List<BoxShadow> purpleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.accentPurple.withOpacity(0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  /// Purple glow for match screen avatar
  static List<BoxShadow> purpleGlowShadow = [
    BoxShadow(
      color: AppColors.accentPurple.withOpacity(0.3),
      blurRadius: 20,
      spreadRadius: 5,
    ),
  ];

  /// Glow shadow for action buttons (configurable color)
  static List<BoxShadow> glowShadow(Color color, {bool isPrimary = false}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: color.withOpacity(0.4),
        blurRadius: 16,
        spreadRadius: isPrimary ? 2 : 0,
      ),
    ];
  }

  // ============ Message Shadows ============
  /// Shadow for chat message bubbles
  static List<BoxShadow> messageBubbleShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ============ Chip Shadows ============
  /// Shadow for tag chips
  static List<BoxShadow> chipShadow = [
    BoxShadow(
      color: const Color(0xFFE0E0E0).withOpacity(0.5),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Shadow for audio player container
  static List<BoxShadow> audioPlayerShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ============ Glassmorphic Shadows ============
  /// Shadow for glassmorphic badges
  static List<BoxShadow> glassBadgeShadow(Color color) {
    return [
      BoxShadow(
        color: color.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

class AppTextStyles {
  AppTextStyles._();

  // ============ Headings ============
  /// Large heading (32px) - Profile names, main titles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Large heading for dark backgrounds
  static const TextStyle headingLargeDark = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    color: AppColors.textWhite,
    height: 1.2,
  );

  /// Medium heading (24-28px) - Section titles
  static const TextStyle headingMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// Small heading (24px) - Match screen
  static const TextStyle headingSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
    letterSpacing: 1.2,
  );

  /// App bar title (20px)
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  /// App bar title (18px) - Chat screen
  static const TextStyle appBarTitleSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Collapsed header title (18px)
  static const TextStyle collapsedHeaderTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// Section title (18px)
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  // ============ Body Text ============
  /// Large body text (16px) - Main content
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: Colors.grey[800],
    fontWeight: FontWeight.w400,
  );

  /// Medium body text (16px) - List items
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textBlack87,
  );

  /// Message bubble text (15px)
  static const TextStyle messageText = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AppColors.textWhite,
  );

  /// Message bubble text (dark)
  static const TextStyle messageTextDark = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  /// Regular body text (14px)
  static TextStyle bodyRegular = TextStyle(
    fontSize: 14,
    color: Colors.grey.shade600,
  );

  /// Button text (14px) - Primary
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// Button text (13px) - Secondary
  static const TextStyle buttonSecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// Time text (14px) - Match screen
  static TextStyle timeText = TextStyle(
    fontSize: 14,
    color: Colors.white.withOpacity(0.6),
  );

  // ============ Small Text & Captions ============
  /// Chip text (13-14px)
  static const TextStyle chipText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryAlt,
  );

  /// Location badge text (13px)
  static TextStyle locationBadgeText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Colors.white.withOpacity(0.95),
  );

  /// Section label (12px) - Uppercase
  static TextStyle sectionLabel = TextStyle(
    fontSize: 12,
    color: Colors.grey[500],
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  /// Recent match name (12px)
  static const TextStyle recentMatchName = TextStyle(
    fontSize: 12,
    color: Colors.white70,
  );

  /// Online status text (12px)
  static TextStyle onlineStatusText = TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
  );

  /// Time duration text (12px)
  static TextStyle timeDurationText = TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
  );

  /// Badge text (11px)
  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  /// Timestamp text (11px)
  static TextStyle timestampText = TextStyle(
    fontSize: 11,
    color: Colors.grey.shade600,
    letterSpacing: 0.2,
  );

  /// Status text (11px) - Seen/Sent
  static TextStyle statusText = TextStyle(
    fontSize: 11,
    color: Colors.grey.shade600,
  );

  // ============ Large Text ============
  /// Avatar initial text (48px)
  static const TextStyle avatarInitialLarge = TextStyle(
    fontSize: 48,
    color: AppColors.textWhite,
  );

  /// Avatar initial text (24px)
  static const TextStyle avatarInitialMedium = TextStyle(
    fontSize: 24,
    color: AppColors.textWhite,
  );

  /// Avatar initial text (18px)
  static const TextStyle avatarInitialSmall = TextStyle(
    fontSize: 18,
    color: AppColors.textSecondary,
  );

  // ============ Empty State ============
  /// Empty state title (18px)
  static TextStyle emptyStateTitle = TextStyle(
    fontSize: 18,
    color: Colors.grey.shade600,
  );

  /// Empty state description (16px)
  static const TextStyle emptyStateDescription = TextStyle(
    fontSize: 16,
    color: Colors.grey,
  );

  // ============ Audio Player ============
  /// Audio track title (16px)
  static const TextStyle audioTrackTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryAlt,
  );

  // ============ Text Shadows ============
  static const List<Shadow> textShadowDark = [
    Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<Shadow> textShadowLight = [
    Shadow(color: Colors.black54, blurRadius: 8),
  ];
}

class AppBorderRadius {
  AppBorderRadius._();

  // ============ Border Radius Values ============
  /// Small radius (8-12px)
  static const double radiusSmall = 12.0;
  static const double radiusSmallAlt = 8.0;

  /// Medium radius (16-20px)
  static const double radiusMedium = 16.0;
  static const double radiusMediumAlt = 20.0;
  static const double radiusMedium19 = 19.0;
  static const double radiusMedium23 = 23.0;

  /// Large radius (24-32px)
  static const double radiusLarge = 24.0;
  static const double radiusLarge28 = 28.0;
  static const double radiusLarge30 = 30.0;
  static const double radiusLarge32 = 32.0;

  /// Circular radius
  static const double radiusCircle = 999.0;

  // ============ BorderRadius Objects ============
  static const BorderRadius small = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius medium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius large = BorderRadius.all(
    Radius.circular(radiusLarge),
  );

  /// Message bubble radius (with different corners)
  static const BorderRadius messageBubbleSent = BorderRadius.only(
    topLeft: Radius.circular(radiusLarge),
    topRight: Radius.circular(radiusLarge),
    bottomLeft: Radius.circular(radiusLarge),
    bottomRight: Radius.circular(radiusSmallAlt),
  );

  static const BorderRadius messageBubbleReceived = BorderRadius.only(
    topLeft: Radius.circular(radiusLarge),
    topRight: Radius.circular(radiusLarge),
    bottomLeft: Radius.circular(radiusSmallAlt),
    bottomRight: Radius.circular(radiusLarge),
  );

  /// Top-only radius (for containers)
  static const BorderRadius topLarge = BorderRadius.vertical(
    top: Radius.circular(radiusLarge30),
  );

  static const BorderRadius topLarge32 = BorderRadius.vertical(
    top: Radius.circular(radiusLarge32),
  );
}

class AppSpacing {
  AppSpacing._();

  // Common spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// App Theme Configuration
/// Provides complete ThemeData for light and dark modes
class AppTheme {
  AppTheme._();

  // ============ Light Theme ============
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.accentPurple,
      secondary: AppColors.accentPurpleLight,
      surface: AppColors.surfaceWhite,
      error: AppColors.accentRed,
      onPrimary: AppColors.textWhite,
      onSecondary: AppColors.textWhite,
      onSurface: AppColors.textPrimary,
      onError: AppColors.textWhite,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textPrimaryAlt),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryAlt,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: 0.5,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusMedium),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurple,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.radiusMedium),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: const BorderSide(color: AppColors.accentPurple, width: 2),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentPurple;
        }
        return Colors.grey.shade400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentPurpleLight.withOpacity(0.5);
        }
        return Colors.grey.shade300;
      }),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textPlaceholder,
      ),
    ),

    dividerColor: AppColors.borderLight,
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
  );

  // ============ Dark Theme ============
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accentPurpleLight,
      secondary: AppColors.accentPurpleSoft,
      surface: AppColors.surfaceDark,
      error: AppColors.accentRed,
      onPrimary: AppColors.textWhite,
      onSecondary: AppColors.textWhite,
      onSurface: AppColors.textWhite,
      onError: AppColors.textWhite,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textWhite),
      titleTextStyle: TextStyle(
        color: AppColors.textWhite,
        fontWeight: FontWeight.w700,
        fontSize: 20,
        letterSpacing: 0.5,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusMedium),
      ),
      shadowColor: Colors.black.withOpacity(0.3),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPurpleLight,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.radiusMedium),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: BorderSide(color: AppColors.surfaceDarkGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: BorderSide(color: AppColors.surfaceDarkGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.radiusSmall),
        borderSide: const BorderSide(color: AppColors.accentPurpleLight, width: 2),
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentPurpleLight;
        }
        return Colors.grey.shade600;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentPurpleSoft.withOpacity(0.5);
        }
        return Colors.grey.shade700;
      }),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textWhite,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textWhite,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textWhite70,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textPlaceholder,
      ),
    ),

    dividerColor: AppColors.surfaceDarkGrey,
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceDarkGrey,
      thickness: 1,
    ),
  );

  // ============ Helper Methods ============
  
  /// Get scaffold background color based on current theme
  static Color getScaffoldBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
  }

  /// Get app bar background color based on current theme
  static Color getAppBarBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDark
        : Colors.transparent;
  }

  /// Get primary text color based on current theme
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textWhite
        : AppColors.textPrimary;
  }

  /// Get secondary text color based on current theme
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textWhite70
        : AppColors.textSecondary;
  }

  /// Get surface color based on current theme
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDark
        : AppColors.surfaceWhite;
  }

  /// Get card background color based on current theme
  static Color getCardBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDark
        : AppColors.surfaceWhite;
  }

  /// Get divider color based on current theme
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.surfaceDarkGrey
        : AppColors.borderLight;
  }

  /// Check if current theme is dark
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
