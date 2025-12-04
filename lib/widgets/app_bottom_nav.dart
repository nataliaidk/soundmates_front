import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_design_system.dart';

enum BottomNavItem { profile, home, messages }

class AppBottomNav extends StatefulWidget {
  final BottomNavItem current;
  const AppBottomNav({super.key, required this.current});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  // Track which item is being pressed for scale animation
  BottomNavItem? _pressedItem;

  // Gradient for active state (works well on both themes)
  static const LinearGradient _activeGradient = AppGradients.purpleGradient;

  // Use dark color palette for both themes (unified look)
  Color _getBackgroundColor(bool isDark) {
    return AppColors.backgroundDark.withOpacity(0.85);
  }

  Color _getBorderColor(bool isDark) {
    return Colors.white.withOpacity(0.1);
  }

  List<BoxShadow> _getContainerShadows(bool isDark) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 4,
      ),
      BoxShadow(
        color: AppColors.accentPurple.withOpacity(0.15),
        blurRadius: 32,
        spreadRadius: -4,
      ),
    ];
  }

  Color _iconColor(BottomNavItem item, bool isDark) {
    if (item == widget.current) {
      return AppColors.textWhite; // Active icons are always white (on gradient bg)
    }
    return AppColors.textWhite.withOpacity(0.5);
  }

  Widget _buildNavItem(
    BuildContext context, {
    required BottomNavItem item,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool emphasized = false,
  }) {
    final bool selected = item == widget.current;
    final bool isPressed = _pressedItem == item;
    final double size = emphasized ? 56 : 48;
    final double iconSize = emphasized ? 28 : 24;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressedItem = item);
      },
      onTapUp: (_) {
        setState(() => _pressedItem = null);
        HapticFeedback.lightImpact();
        onTap();
      },
      onTapCancel: () {
        setState(() => _pressedItem = null);
      },
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Semantics(
          button: true,
          label: item == BottomNavItem.home
              ? 'Discover'
              : (item == BottomNavItem.profile ? 'Profile' : 'Messages'),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? _activeGradient : null,
              color: selected ? null : Colors.transparent,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.accentPurple.withOpacity(isDark ? 0.4 : 0.3),
                        blurRadius: 12,
                        spreadRadius: isDark ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: _iconColor(item, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding + 16,
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _getBorderColor(isDark),
                  width: 1.5,
                ),
                boxShadow: _getContainerShadows(isDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(
                    context,
                    item: BottomNavItem.profile,
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                    onTap: () {
                      if (widget.current != BottomNavItem.profile) {
                        Navigator.pushReplacementNamed(context, '/profile');
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildNavItem(
                    context,
                    item: BottomNavItem.home,
                    icon: Icons.style_rounded,
                    isDark: isDark,
                    emphasized: true,
                    onTap: () {
                      if (widget.current != BottomNavItem.home) {
                        Navigator.pushReplacementNamed(context, '/discover');
                      }
                    },
                  ),
                  const SizedBox(width: 24),
                  _buildNavItem(
                    context,
                    item: BottomNavItem.messages,
                    icon: Icons.chat_bubble_outline_rounded,
                    isDark: isDark,
                    onTap: () {
                      if (widget.current != BottomNavItem.messages) {
                        Navigator.pushReplacementNamed(context, '/matches');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
