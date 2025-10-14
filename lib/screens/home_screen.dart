import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';

class HomeScreen extends StatelessWidget {
  final ApiClient api;
  final TokenStore tokens;
  const HomeScreen({super.key, required this.api, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/profile'), child: const Text('Profile')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/messages'), child: const Text('Messages')),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/users'), child: const Text('Users')),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () {
                
                api.logout();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout')),
        ]),
      ),
    );
  }
}
