import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';
import '../api/token_store.dart';
import '../api/api_client.dart';
import '../api/event_hub_service.dart';
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
      // User is logged in with valid token, check if profile is complete
      final isProfileComplete = await _checkProfileComplete();
      
      if (!mounted) return;
      
      if (isProfileComplete) {
        // Profile is complete, go to discover
        Navigator.pushReplacementNamed(context, '/discover');
      } else {
        // Profile not complete, redirect to profile creation
        Navigator.pushReplacementNamed(context, '/profile/create');
      }
    } else {
      // User not logged in or token expired, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }

    widget.onComplete();
  }

  /// Check if the user's profile creation is complete
  Future<bool> _checkProfileComplete() async {
    try {
      // Create a temporary API client to check profile
      final eventHub = EventHubService(tokenStore: widget.tokens);
      final api = ApiClient(tokenStore: widget.tokens, eventHubService: eventHub);
      
      final resp = await api.getMyProfile();
      
      if (resp.statusCode == 200) {
        final profile = jsonDecode(resp.body);
        
        // Check required fields for profile completion:
        // - name must be set
        // - countryId must be set
        // - cityId must be set
        // - For artists (isBand != true): birthDate and genderId must be set
        
        final name = profile['name']?.toString();
        final countryId = profile['countryId']?.toString() ?? profile['country_id']?.toString();
        final cityId = profile['cityId']?.toString() ?? profile['city_id']?.toString();
        final isBand = profile['isBand'] == true;
        
        // Basic requirements for all profiles
        if (name == null || name.isEmpty) {
          debugPrint('Profile incomplete: name is empty');
          return false;
        }
        if (countryId == null || countryId.isEmpty) {
          debugPrint('Profile incomplete: countryId is empty');
          return false;
        }
        if (cityId == null || cityId.isEmpty) {
          debugPrint('Profile incomplete: cityId is empty');
          return false;
        }
        
        // Additional requirements for artists (non-band profiles)
        if (!isBand) {
          final birthDate = profile['birthDate']?.toString();
          final genderId = profile['genderId']?.toString() ?? profile['gender_id']?.toString();
          
          if (birthDate == null || birthDate.isEmpty) {
            debugPrint('Profile incomplete: birthDate is empty for artist');
            return false;
          }
          if (genderId == null || genderId.isEmpty) {
            debugPrint('Profile incomplete: genderId is empty for artist');
            return false;
          }
        }
        
        debugPrint('Profile is complete');
        return true;
      } else {
        debugPrint('Failed to fetch profile: ${resp.statusCode}');
        // If we can't fetch profile, assume incomplete to be safe
        return false;
      }
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      // On error, assume incomplete to be safe
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the unified LoadingScreen widget
    return const LoadingScreen();
  }
}
