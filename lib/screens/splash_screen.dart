import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../api/token_store.dart';
import '../widgets/loading_screen.dart';

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
    // Use the unified LoadingScreen widget
    return const LoadingScreen();
  }
}
