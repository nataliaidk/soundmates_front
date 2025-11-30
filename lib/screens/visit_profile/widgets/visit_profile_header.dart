import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../api/models.dart';
import '../visit_profile_model.dart';
import '../../../theme/app_design_system.dart';

class VisitProfileHeader extends StatelessWidget {
  final VisitProfileViewModel data;
  final bool isMatched;
  final VoidCallback onUnmatch;
  final VoidCallback onMessage;

  const VisitProfileHeader({
    super.key,
    required this.data,
    required this.isMatched,
    required this.onUnmatch,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _VisitProfileHeaderDelegate(
        data: data,
        isMatched: isMatched,
        onUnmatch: onUnmatch,
        onMessage: onMessage,
      ),
    );
  }
}

class _VisitProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VisitProfileViewModel data;
  final bool isMatched;
  final VoidCallback onUnmatch;
  final VoidCallback onMessage;

  static const double _maxExtent = 500.0;
  static const double _minExtent =
      kToolbarHeight + 20; // Extra space for status bar

  _VisitProfileHeaderDelegate({
    required this.data,
    required this.isMatched,
    required this.onUnmatch,
    required this.onMessage,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final profilePicUrl = data.profileImageUrl;
    final progress = shrinkOffset / _maxExtent;
    final fadeOpacity = (1.0 - (progress * 1.5)).clamp(0.0, 1.0);
    final isCollapsed = shrinkOffset > _maxExtent - _minExtent - 20;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Profile Image
        if (profilePicUrl != null)
          Image.network(
            profilePicUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: isDark ? AppColors.surfaceDarkGrey : Colors.grey[800],
            ),
          )
        else
          Container(
            color: isDark ? AppColors.surfaceDarkGrey : Colors.grey[800],
          ),

        // 2. Gradient Overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Colors.black.withAlpha(0),
                      Colors.black.withAlpha(25),
                      Colors.black.withAlpha(128),
                      Colors.black.withAlpha(216),
                      Colors.black.withAlpha(242),
                    ]
                  : [
                      Colors.black.withAlpha(0),
                      Colors.black.withAlpha(25),
                      Colors.black.withAlpha(128),
                      Colors.black.withAlpha(216),
                      Colors.black.withAlpha(242),
                    ],
              stops: [0.0, 0.3, 0.6, 0.85, 1.0],
            ),
          ),
        ),

        // 3. Collapsed Background (fades in)
        if (isCollapsed)
          Container(
            color: isDark ? AppColors.surfaceDark : AppColors.backgroundDark,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              data.profile.name ?? 'User',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // 4. Content (User Info & Buttons) - Fades out on scroll
        if (fadeOpacity > 0)
          Opacity(
            opacity: fadeOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // User Info (Bottom Left)
                Positioned(
                  left: 20,
                  right: 130,
                  bottom: 30,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Matched Badge
                      if (isMatched)
                        _GlassmorphicBadge(
                          icon: Icons.auto_awesome,
                          text: "Matched",
                          color: AppColors.accentPurple,
                          isDark: isDark,
                        ),
                      if (isMatched) const SizedBox(height: 12),

                      // Name and Age
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            data.profile.name ?? 'Unknown',
                            style: TextStyle(
                              color: AppColors.textWhite.withAlpha(242),
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha(128),
                                  blurRadius: 12,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (data.profile is OtherUserProfileArtistDto) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${(data.profile as OtherUserProfileArtistDto).calculatedAge ?? ''}',
                              style: TextStyle(
                                color: AppColors.textWhite.withAlpha(242),
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.3,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(128),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                        ],
                      ),

                      // Location Text
                      if (data.locationString.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          data.locationString.toUpperCase(),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textWhite.withAlpha(242)
                                : AppColors.textWhite.withAlpha(242),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(128),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Buttons (Bottom Right)
                if (isMatched)
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          text: "Unmatch",
                          icon: Icons.close,
                          color: AppColors.accentRed,
                          isPrimary: false,
                          onTap: onUnmatch,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          text: "Message",
                          icon: Icons.chat_bubble_outline,
                          color: AppColors.accentPurple,
                          isPrimary: true,
                          onTap: onMessage,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  double get maxExtent => _maxExtent;

  @override
  double get minExtent => _minExtent;

  @override
  bool shouldRebuild(covariant _VisitProfileHeaderDelegate oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isMatched != isMatched ||
        oldDelegate.onUnmatch != onUnmatch ||
        oldDelegate.onMessage != onMessage;
  }
}

// --- Helper Widgets ---

class _GlassmorphicBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _GlassmorphicBadge({
    required this.icon,
    required this.text,
    required this.color,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? color.withAlpha(77) : color.withAlpha(77),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDark ? color.withAlpha(128) : color.withAlpha(128),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? color.withAlpha(77) : color.withAlpha(77),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isDark ? AppColors.textWhite : Colors.white,
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.onTap,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? (isDark ? color.withAlpha(204) : color)
            : (isDark ? AppColors.surfaceDark.withAlpha(128) : Colors.white),
        foregroundColor: isPrimary
            ? (isDark ? AppColors.textWhite : Colors.white)
            : (isDark ? AppColors.textWhite : color),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isPrimary
              ? BorderSide.none
              : BorderSide(
                  color: isDark ? color.withAlpha(128) : color,
                  width: 1.5,
                ),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      onPressed: onTap,
    );
  }
}
