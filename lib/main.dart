import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api/api_client.dart';
import 'api/event_hub_service.dart';
import 'api/token_store.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile/profile_screen_new.dart' as profile_new;
import 'screens/profile/profile_edit_tags_screen.dart';
import 'screens/profile/profile_add_media_screen.dart';
import 'screens/profile/profile_manage_media_screen.dart';
import 'screens/profile/profile_edit_basic_info_screen.dart';
// import 'screens/messages_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/users_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_of_service_screen.dart';


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
    final eventHub = EventHubService(tokenStore: tokens);
    final api = ApiClient(tokenStore: tokens, eventHubService: eventHub);

    void onAuthSuccess(BuildContext navContext) {
      eventHub.connect();
      Navigator.pushReplacementNamed(navContext, '/users');
    }

    void onRegisterSuccess(BuildContext navContext) {
      eventHub.connect();
      Navigator.pushReplacementNamed(navContext, '/profile/create');
    }

    return MaterialApp(
      title: 'Soundmates Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      initialRoute: '/login',
      routes: {
        '/login': (c) => LoginScreen(api: api, tokens: tokens, onLoggedIn: () => onAuthSuccess(c)),
        '/register': (c) => RegisterScreen(api: api, tokens: tokens, onRegistered: () => onRegisterSuccess(c)),
        '/home': (c) => HomeScreen(api: api, tokens: tokens),
        '/profile': (c) => profile_new.ProfileScreen(api: api, tokens: tokens, startInEditMode: false),
        '/profile/create': (c) => profile_new.ProfileScreen(api: api, tokens: tokens, startInEditMode: true, isFromRegistration: true),
        '/profile/edit': (c) => ProfileEditBasicInfoScreen(api: api, tokens: tokens),
        '/profile/edit-tags': (c) => ProfileEditTagsScreen(api: api, tokens: tokens),
        '/profile/add-media': (c) => ProfileAddMediaScreen(api: api, tokens: tokens),
        '/profile/manage-media': (c) => ProfileManageMediaScreen(api: api, tokens: tokens),
        '/matches': (c) => MatchesScreen(api: api, tokens: tokens),
        '/users': (c) => UsersScreen(api: api, tokens: tokens),
        '/filters': (c) => FiltersScreen(api: api, tokens: tokens),
        '/settings': (c) => SettingsScreen(api: api, tokens: tokens),
        '/terms': (c) => const TermsOfServiceScreen(),
      },
    );
  }
}
