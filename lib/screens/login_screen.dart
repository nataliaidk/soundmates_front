import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.api, required this.tokens, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _status = '';

  Future<void> _login() async {
    final emailErr = validateEmail(_email.text);
    if (emailErr != null) return setState(() => _status = emailErr);
    final passErr = validatePassword(_pass.text);
    if (passErr != null) return setState(() => _status = passErr);

    setState(() => _status = 'Logging in...');
  final resp = await widget.api.login(LoginDto(email: _email.text.trim(), password: _pass.text));
  // debug: read stored token and show it along with server response
  final stored = await widget.tokens.readAccessToken();
  final headers = resp.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  setState(() => _status = 'Login: ${resp.statusCode} ; stored token: ${stored ?? '(none)'}\nbody: ${resp.body}\nheaders:\n$headers');
    if (resp.statusCode == 200) widget.onLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(dotenv.env['LOGO_PATH'] ?? 'default/path/to/logo.png'),
                  const SizedBox(height: 16),
                  const Text(
                    'The whole music scene. In one app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pass,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Don’t have an account? Sign Up'),
            ),
            const SizedBox(height: 12),
            if (_status.isNotEmpty)
              Text(
                _status,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
