import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';

class AuthScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final VoidCallback onLoggedIn;
  const AuthScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.onLoggedIn,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _status = '';

  Future<void> _login() async {
    setState(() => _status = 'Logging in...');
    final resp = await widget.api.login(
      LoginDto(email: _email.text.trim(), password: _pass.text),
    );
    await widget.api.saveTokensFromResponseBody(resp.body);
    setState(() => _status = 'Login: ${resp.statusCode}');
    if (resp.statusCode == 200) widget.onLoggedIn();
  }

  Future<void> _register() async {
    setState(() => _status = 'Registering...');
    final resp = await widget.api.register(
      RegisterDto(email: _email.text.trim(), password: _pass.text),
    );
    await widget.api.saveTokensFromResponseBody(resp.body);
    setState(() => _status = 'Register: ${resp.statusCode}');
    if (resp.statusCode == 200) widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _pass,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
