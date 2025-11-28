import 'package:flutter/material.dart';

enum BottomNavItem { profile, home, messages }

class AppBottomNav extends StatelessWidget {
  final BottomNavItem current;
  const AppBottomNav({super.key, required this.current});

  Color _iconColor(BottomNavItem item) {
    return item == current ? const Color(0xFF5B3CF0) : const Color(0xFF8E7CC9);
  }

  Widget _button(
    BuildContext context, {
    required BottomNavItem item,
    required IconData icon,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final bool selected = item == current;
    final double size = emphasized ? 64 : 52;
    final double iconSize = emphasized ? 30 : 26;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Use brand purple with low alpha for selected background circle
        color: selected ? const Color(0x225B3CF0) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        tooltip: item == BottomNavItem.home
            ? 'Discover'
            : (item == BottomNavItem.profile ? 'Profile' : 'Messages'),
        iconSize: iconSize,
        splashRadius: size / 2,
        icon: Icon(icon, color: _iconColor(item)),
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 90,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _button(
                  context,
                  item: BottomNavItem.profile,
                  icon: Icons.person_outline,
                  onTap: () {
                    if (current != BottomNavItem.profile) {
                      Navigator.pushReplacementNamed(context, '/profile');
                    }
                  },
                ),
                const SizedBox(width: 22),
                _button(
                  context,
                  item: BottomNavItem.messages,
                  icon: Icons.chat_bubble_outline,
                  onTap: () {
                    if (current != BottomNavItem.messages) {
                      Navigator.pushReplacementNamed(context, '/matches');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
