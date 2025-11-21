import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../api/models.dart';
import '../visit_profile_model.dart';

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
  static const Color _primaryDark = Color(0xFF1A1A1A);
  static const Color _accentPurple = Color(0xFF7B51D3);
  static const Color _accentRed = Color(0xFFD32F2F);

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

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Profile Image
        if (profilePicUrl != null)
          Image.network(
            profilePicUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
          )
        else
          Container(color: Colors.grey[800]),

        // 2. Gradient Overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
            ),
          ),
        ),

        // 3. Collapsed Background (fades in)
        if (isCollapsed)
          Container(
            color: _primaryDark,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              data.profile.name ?? 'User',
              style: const TextStyle(
                color: Colors.white,
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
                          color: _accentPurple,
                        ),
                      if (isMatched) const SizedBox(height: 12),

                      // Name and Age
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            data.profile.name ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
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
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                height: 1.2,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // Online Status
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.5),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Location Badge
                      if (data.locationString.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _GlassmorphicLocationBadge(
                          location: data.locationString,
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
                          color: _accentRed,
                          isPrimary: false,
                          onTap: onUnmatch,
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          text: "Message",
                          icon: Icons.chat_bubble_outline,
                          color: _accentPurple,
                          isPrimary: true,
                          onTap: onMessage,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        // 5. Back Button (Always visible, top left)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 8,
          child: _GlassmorphicButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
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

class _GlassmorphicButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassmorphicButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _GlassmorphicBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _GlassmorphicBadge({
    required this.icon,
    required this.text,
    required this.color,
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
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 12),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
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

class _GlassmorphicLocationBadge extends StatelessWidget {
  final String location;

  const _GlassmorphicLocationBadge({required this.location});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.9),
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  const _ActionButton({
    super.key, // Dodaj super.key dla wydajności
    required this.text,
    required this.icon,
    required this.color,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Kontener odpowiada TYLKO za Cień i Kształt zewnętrzny
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
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
        ],
      ),
      // Material odpowiada za Kolor tła i Przycinanie (Clipping)
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(30),
        clipBehavior: Clip.antiAlias, // <--- TO JEST KLUCZOWA POPRAWKA
        child: InkWell(
          onTap: onTap,
          // Ważne: Nie ustawiaj borderRadius w InkWell, jeśli Material już przycina
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPrimary ? 20 : 16,
              vertical: isPrimary ? 12 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: isPrimary ? 20 : 16),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isPrimary ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
