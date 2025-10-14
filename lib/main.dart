import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api/api_client.dart';
import 'api/token_store.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/users_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TokenStore();
    final api = ApiClient(tokenStore: tokens);
    return MaterialApp(
      title: 'Soundmates Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: '/login',
      routes: {
        '/login': (c) => LoginScreen(api: api, tokens: tokens, onLoggedIn: () => Navigator.pushReplacementNamed(c, '/home')),
        '/register': (c) => RegisterScreen(api: api, tokens: tokens, onRegistered: () => Navigator.pushReplacementNamed(c, '/profile')),
        '/home': (c) => HomeScreen(api: api, tokens: tokens),
        '/profile': (c) => ProfileScreen(api: api, tokens: tokens),
        '/messages': (c) => MessagesScreen(api: api, tokens: tokens),
        '/users': (c) => UsersScreen(api: api, tokens: tokens),
      },
    );
  }
}
