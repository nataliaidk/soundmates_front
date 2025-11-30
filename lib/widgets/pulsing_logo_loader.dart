import 'package:flutter/material.dart';
import '../theme/app_design_system.dart';

class PulsingLogoLoader extends StatefulWidget {
  final String? message;
  final double size;

  const PulsingLogoLoader({
    super.key,
    this.message,
    this.size = 120,
  });

  @override
  State<PulsingLogoLoader> createState() => _PulsingLogoLoaderState();
}

class _PulsingLogoLoaderState extends State<PulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPurple.withOpacity(0.3 * _opacityAnimation.value),
                          blurRadius: 30 * _scaleAnimation.value,
                          spreadRadius: 10 * _scaleAnimation.value,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'lib/assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          if (widget.message != null)
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppColors.textWhite70 : AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
