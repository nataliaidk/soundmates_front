import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/models.dart';
import '../api/token_store.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const ChangePasswordScreen({super.key, required this.api, required this.tokens});

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
    if (v.trim().length < 6) return 'Minimum 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _status = 'Changing password...'; });
    try {
      final dto = ChangePasswordDto(oldPassword: _oldCtrl.text.trim(), newPassword: _newCtrl.text.trim());
      final resp = await widget.api.changePassword(dto);
      if (!mounted) return;
      if (resp.statusCode == 200) {
        setState(() { _status = 'Password changed successfully'; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
        Navigator.pop(context);
      } else if (resp.statusCode == 400 || resp.statusCode == 401) {
        setState(() { _status = 'Invalid current password'; });
      } else {
        setState(() { _status = 'Change failed: ${resp.statusCode}'; });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _status = 'Network error'; });
    } finally {
      if (mounted) setState(() { _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _oldCtrl,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: _validateOld,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: _validateNew,
              ),
              const SizedBox(height: 20),
              if (_status.isNotEmpty) ...[
                Text(_status, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Change password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
