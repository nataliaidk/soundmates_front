import 'package:flutter/material.dart';
import '../api/token_store.dart';
import '../theme/app_design_system.dart';
import '../widgets/pulsing_logo_loader.dart';

class SplashScreen extends StatefulWidget {
  final TokenStore tokens;
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.tokens,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Show splash for at least 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if user is logged in
    final token = await widget.tokens.readAccessToken();
    
    if (!mounted) return;
    
    if (token != null && token.isNotEmpty) {
      // User is logged in, go to discover
      Navigator.pushReplacementNamed(context, '/discover');
    } else {
      // User not logged in, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
    
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.backgroundDark,
                    AppColors.backgroundDarkAlt,
                    const Color(0xFF1A1525),
                  ]
                : [
                    Colors.white,
                    AppColors.accentPurpleSoft.withOpacity(0.3),
                    AppColors.accentPurpleLight.withOpacity(0.2),
                  ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulsingLogoLoader(
                size: 160,
              ),
              SizedBox(height: 40),
              Text(
                'SOUNDMATES',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: AppColors.accentPurple,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Find your sound',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
