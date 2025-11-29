import 'package:flutter/material.dart';
import '../../../theme/app_design_system.dart';

/// Round action button widget used for like/dislike/filter actions.
/// Extracted from users_screen.dart for better code organization.
class RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final bool isElevated;
  final double size;
  final double iconSize;

  const RoundActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor = AppColors.surfaceWhite,
    this.iconColor = AppColors.textPrimaryAlt,
    this.isElevated = false,
    this.size = 56,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isElevated ? 0.25 : 0.15),
              blurRadius: isElevated ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
