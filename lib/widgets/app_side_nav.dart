import 'package:flutter/material.dart';

enum SideNavItem { profile, home, messages }

class AppSideNav extends StatelessWidget {
  final SideNavItem current;
  const AppSideNav({super.key, required this.current});

  Color _iconColor(SideNavItem item) {
    return item == current ? const Color(0xFF5B3CF0) : const Color(0xFF8E7CC9);
  }

  Color _backgroundColor(SideNavItem item) {
    return item == current
        ? const Color(0xFF5B3CF0).withOpacity(0.12)
        : Colors.transparent;
  }

  Widget _navButton(
    BuildContext context, {
    required SideNavItem item,
    required IconData icon,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final double size = emphasized ? 56 : 48;
    final double iconSize = emphasized ? 28 : 24;

    return Tooltip(
      message: item == SideNavItem.home
          ? 'Discover'
          : (item == SideNavItem.profile ? 'Profile' : 'Messages'),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _backgroundColor(item),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _iconColor(item), size: iconSize),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999), // Pill shape
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _navButton(
                    context,
                    item: SideNavItem.profile,
                    icon: Icons.person_outline,
                    onTap: () {
                      if (current != SideNavItem.profile) {
                        Navigator.pushReplacementNamed(context, '/profile');
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  _navButton(
                    context,
                    item: SideNavItem.home,
                    icon: Icons.style_outlined,
                    emphasized: true,
                    onTap: () {
                      if (current != SideNavItem.home) {
                        Navigator.pushReplacementNamed(context, '/discover');
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  _navButton(
                    context,
                    item: SideNavItem.messages,
                    icon: Icons.chat_bubble_outline,
                    onTap: () {
                      if (current != SideNavItem.messages) {
                        Navigator.pushReplacementNamed(context, '/matches');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
