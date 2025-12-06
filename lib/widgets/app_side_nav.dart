import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_design_system.dart';

enum SideNavItem { profile, home, messages }

class AppSideNav extends StatefulWidget {
  final SideNavItem current;
  const AppSideNav({super.key, required this.current});

  @override
  State<AppSideNav> createState() => _AppSideNavState();
}

class _AppSideNavState extends State<AppSideNav> {
  // Track which item is being pressed for scale animation
  SideNavItem? _pressedItem;

  // Gradient for active state (same as bottom nav)
  static const LinearGradient _activeGradient = AppGradients.purpleGradient;

  // Use dark color palette (unified look)
  Color _getBackgroundColor() {
    return AppColors.backgroundDark.withOpacity(0.85);
  }

  Color _getBorderColor() {
    return Colors.white.withOpacity(0.1);
  }

  List<BoxShadow> _getContainerShadows() {
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

  Color _iconColor(SideNavItem item) {
    if (item == widget.current) {
      return AppColors.textWhite; // Active icons are always white (on gradient bg)
    }
    return AppColors.textWhite.withOpacity(0.5);
  }

  Widget _buildNavItem(
    BuildContext context, {
    required SideNavItem item,
    required IconData icon,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final bool selected = item == widget.current;
    final bool isPressed = _pressedItem == item;
    final double size = emphasized ? 56 : 48;
    final double iconSize = emphasized ? 28 : 24;

    String tooltip;
    switch (item) {
      case SideNavItem.profile:
        tooltip = 'Your Profile';
        break;
      case SideNavItem.home:
        tooltip = 'Discover';
        break;
      case SideNavItem.messages:
        tooltip = 'Messages';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
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
            label: tooltip,
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
                          color: AppColors.accentPurple.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: _iconColor(item),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      left: false,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _getBorderColor(),
                      width: 1.5,
                    ),
                    boxShadow: _getContainerShadows(),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNavItem(
                        context,
                        item: SideNavItem.profile,
                        icon: Icons.person_outline_rounded,
                        onTap: () {
                          if (widget.current != SideNavItem.profile) {
                            Navigator.pushReplacementNamed(context, '/profile');
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                      _buildNavItem(
                        context,
                        item: SideNavItem.home,
                        icon: Icons.style_rounded,
                        emphasized: true,
                        onTap: () {
                          if (widget.current != SideNavItem.home) {
                            Navigator.pushReplacementNamed(context, '/discover');
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                      _buildNavItem(
                        context,
                        item: SideNavItem.messages,
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () {
                          if (widget.current != SideNavItem.messages) {
                            Navigator.pushReplacementNamed(context, '/matches');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
