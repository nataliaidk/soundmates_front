import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import '../api/token_store.dart';
import '../theme/app_design_system.dart';
import '../utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const ChangePasswordScreen({
    super.key,
    required this.api,
    required this.tokens,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _submitting = false;
  String _status = '';

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  String? _validateOld(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter current password';
    return null;
  }

  String? _validateNew(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter new password';
    return validatePassword(v);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _status = 'Changing password...';
    });
    try {
      final dto = ChangePasswordDto(
        oldPassword: _oldCtrl.text.trim(),
        newPassword: _newCtrl.text.trim(),
      );
      final resp = await widget.api.changePassword(dto);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() {
          _status = 'Password changed successfully';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password changed')));
        Navigator.pop(context);
      } else if (resp.statusCode == 400 || resp.statusCode == 401) {
        setState(() {
          _status = 'Invalid current password';
        });
      } else {
        setState(() {
          _status = 'Change failed: ${resp.statusCode}';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Network error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : null,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : null,
        title: Text(
          'Change Password',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : null,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textWhite : null,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _oldCtrl,
                    obscureText: _obscureOld,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.accentPurpleMid,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureOld ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => setState(() => _obscureOld = !_obscureOld),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
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
                    validator: _validateOld,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: _obscureNew,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      helperText: 'Min 8 chars: a-z, A-Z, 0-9, special char',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppColors.accentPurpleMid,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textGrey,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.borderLight),
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
                    validator: _validateNew,
                  ),
                  const SizedBox(height: 32),
                  if (_status.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkAlt : AppColors.backgroundLight,
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
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurpleMid,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Change password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
