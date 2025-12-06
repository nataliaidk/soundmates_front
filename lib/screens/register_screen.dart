import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';
import '../theme/app_design_system.dart';
import '../widgets/animated_logo.dart';

class RegisterScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final VoidCallback onRegistered;
  const RegisterScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.onRegistered,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();
  String _status = '';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    final emailErr = validateEmail(_email.text);
    if (emailErr != null) return setState(() => _status = emailErr);
    final passErr = validatePassword(_pass.text);
    if (passErr != null) return setState(() => _status = passErr);
    if (_pass.text != _confirmPass.text) {
      return setState(() => _status = 'Passwords do not match');
    }

    setState(() => _status = 'Registering...');
    try {
      final resp = await widget.api.register(
        RegisterDto(email: _email.text.trim(), password: _pass.text),
      );

      if (resp.statusCode == 200) {
        final loginResp = await widget.api.login(
          LoginDto(email: _email.text.trim(), password: _pass.text),
        );
        if (loginResp.statusCode == 200) {
          setState(() => _status = 'Success');
          widget.onRegistered();
        } else {
          String msg = 'Registration successful, but login failed.';
          try {
            final body = jsonDecode(loginResp.body);
            if (body is Map && body['message'] != null) {
              msg = body['message'];
            }
          } catch (_) {}
          setState(() => _status = msg);
        }
      } else {
        String msg = 'Registration failed';
        try {
          final body = jsonDecode(resp.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'];
          }
        } catch (_) {}
        setState(() => _status = msg);
      }
    } catch (e) {
      setState(() => _status = 'An error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.surfaceWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      AnimatedLogo(
                        logoPath: dotenv.env['LOGO_PATH'] ?? 'default/path/to/logo.png',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textBlack87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join the whole music scene. In one app.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) => validateEmail(value ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.accentPurpleMid,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentPurpleMid,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.backgroundLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pass,
                          obscureText: _obscurePassword,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) => validatePassword(value ?? ''),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            helperText: 'Min 8 chars: a-z, A-Z, 0-9, special char',
                            helperMaxLines: 2,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppColors.accentPurpleMid,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentPurpleMid,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.backgroundLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPass,
                          obscureText: _obscureConfirm,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm your password';
                            if (value != _pass.text) return 'Passwords do not match';
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: 'Re-enter your password',
                            prefixIcon: const Icon(
                              Icons.lock_reset_outlined,
                              color: AppColors.accentPurpleMid,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textGrey,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.accentPurpleMid,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.backgroundLight,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurpleMid,
                            foregroundColor: AppColors.textWhite,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Register',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 15),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.accentPurpleMid,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Text(
                              _status,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
