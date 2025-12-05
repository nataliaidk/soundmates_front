import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../api/token_store.dart';
import '../theme/app_design_system.dart';
import '../widgets/animated_logo.dart';

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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _initialize();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Show splash for at least 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in and token is valid
    final token = await widget.tokens.readAccessToken();

    if (!mounted) return;

    bool isValidToken = false;
    if (token != null && token.isNotEmpty) {
      try {
        // Validate token using JwtDecoder
        isValidToken = !JwtDecoder.isExpired(token);
      } catch (e) {
        // Token is malformed or invalid
        debugPrint('Token validation failed: $e');
        isValidToken = false;
      }
    }

    if (isValidToken) {
      // User is logged in with valid token, go to discover
      Navigator.pushReplacementNamed(context, '/discover');
    } else {
      // User not logged in or token expired, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Match login screen background
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceWhite,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Logo - same as login screen
                  AnimatedLogo(
                    logoPath: dotenv.env['LOGO_PATH'] ?? 'lib/assets/logo.png',
                    size: 200,
                  ),
                  const SizedBox(height: 16),
                  // App name - matching login screen style
                  Text(
                    'SOUNDMATES',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : AppColors.textBlack87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline - matching login screen style
                  const Text(
                    'The whole music scene. In one app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(flex: 2),
                  // Loading indicator at bottom
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentPurpleMid,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
