import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final VoidCallback onRegistered;
  const RegisterScreen({super.key, required this.api, required this.tokens, required this.onRegistered});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  String _status = '';

  Future<void> _register() async {
    final emailErr = validateEmail(_email.text);
    if (emailErr != null) return setState(() => _status = emailErr);
    final passErr = validatePassword(_pass.text);
    if (passErr != null) return setState(() => _status = passErr);

    setState(() => _status = 'Registering...');
    final resp = await widget.api.register(RegisterDto(email: _email.text.trim(), password: _pass.text));
    final stored = await widget.tokens.readAccessToken();
    final headers = resp.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    setState(() => _status = 'Register: ${resp.statusCode} ; stored token: ${stored ?? '(none)'}\nbody: ${resp.body}\nheaders:\n$headers');
    if (resp.statusCode == 200) {
      
      final loginResp = await widget.api.login(LoginDto(email: _email.text.trim(), password: _pass.text));
      final stored2 = await widget.tokens.readAccessToken();
      final headers2 = loginResp.headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      setState(() => _status = 'Login: ${loginResp.statusCode} ; stored token: ${stored2 ?? '(none)'}\nbody: ${loginResp.body}\nheaders:\n$headers2');
      widget.onRegistered();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: _register, child: const Text('Register'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Masz konto? Zaloguj się'))),
          ]),
          const SizedBox(height: 12),
          Text(_status),
        ]),
      ),
    );
  }
}
