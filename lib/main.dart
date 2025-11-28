import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'api/event_hub_service.dart';
import 'api/token_store.dart';
import 'utils/audio_notifier.dart';
import 'theme/theme_provider.dart';
import 'theme/app_design_system.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile/profile_screen_new.dart' as profile_new;
import 'screens/profile/profile_edit_tags_screen.dart';
import 'screens/profile/profile_add_media_screen.dart';
import 'screens/profile/profile_manage_media_screen.dart';
import 'screens/profile/profile_edit_basic_info_screen.dart';
import 'screens/match_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/swiping_screen.dart';
import 'screens/filters_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/terms_of_service_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TokenStore tokens;
  late final EventHubService eventHub;
  late final ApiClient api;
  late final AudioNotifier audioNotifier;
  void Function(dynamic)? _globalMessageListener;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    tokens = TokenStore();
    eventHub = EventHubService(tokenStore: tokens);
    api = ApiClient(tokenStore: tokens, eventHubService: eventHub);
    audioNotifier = AudioNotifier.instance;
    audioNotifier.preloadAll();
    _hydrateCurrentUserId();

    // Setup callbacks immediately - they will work once SignalR connects
    _setupGlobalRealtimeNotifications();
  }

  @override
  void dispose() {
    if (_globalMessageListener != null) {
      eventHub.removeMessageListener(_globalMessageListener!);
    }
    audioNotifier.dispose();
    super.dispose();
  }

  void _setupGlobalRealtimeNotifications() {
    print("🌍 Setting up global match notifications in initState");

    eventHub.onMatchReceived = (matchData) {
      print("🌍💜 Global MatchReceived callback triggered: $matchData");
      if (!mounted) {
        print("⚠️ Widget not mounted, skipping notification");
        return;
      }
      audioNotifier.playMatchReceived();
      _showGlobalMatchNotification(matchData, isMutual: false);
    };

    eventHub.onMatchCreated = (matchData) {
      print("🌍🔥 Global MatchCreated callback triggered: $matchData");
      if (!mounted) return;
      audioNotifier.playMatchMutual();

      // Extract userId from matchData
      String? userId;
      if (matchData is Map) {
        userId = matchData['existingLikeUserId']?.toString();
      }

      if (userId != null && userId.isNotEmpty) {
        print("🚀 Navigating to MatchScreen for user: $userId");
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MatchScreen(
              api: api,
              tokens: tokens,
              userId: userId!,
              eventHubService: eventHub,
            ),
          ),
        );
      } else {
        print("⚠️ Could not extract userId from matchData for navigation");
        // Fallback to notification if navigation fails? Or just log error.
        // For now, let's try to show notification as fallback if parsing fails,
        // but the primary goal is navigation.
        _showGlobalMatchNotification(matchData, isMutual: true);
      }
    };
    _globalMessageListener = (messageData) {
      _handleIncomingMessage(messageData);
    };

    eventHub.addMessageListener(_globalMessageListener!);
  }

  Future<void> _handleIncomingMessage(dynamic messageData) async {
    if (messageData is! Map) return;

    final senderId = messageData['senderId']?.toString();
    if (senderId == null || senderId.isEmpty) return;

    await _hydrateCurrentUserId();
    if (_currentUserId != null && senderId == _currentUserId) {
      return; // Do not play sound for own messages
    }

    final activeChatUserId = eventHub.activeConversationUserId;
    if (activeChatUserId != null && senderId == activeChatUserId) {
      return; // Suppress if user is already viewing this chat
    }

    await audioNotifier.playMessage();
  }

  Future<void> _hydrateCurrentUserId() async {
    if (_currentUserId != null) return;
    try {
      final token = await tokens.readAccessToken();
      if (token == null || token.isEmpty) return;
      final decoded = JwtDecoder.decode(token);
      _currentUserId = (decoded['sub'] ?? decoded['userId'] ?? decoded['id'])
          ?.toString();
    } catch (e) {
      debugPrint('Failed to decode user id from token: $e');
    }
  }

  void _showGlobalMatchNotification(
    dynamic matchData, {
    required bool isMutual,
  }) {
    print("🎨 _showGlobalMatchNotification called (isMutual: $isMutual)");

    final context = navigatorKey.currentContext;
    if (context == null) {
      print("❌ No navigator context available");
      return;
    }
    print("✅ Navigator context available");

    try {
      String? userId;
      String userName = 'Nowy użytkownik';

      if (matchData is Map) {
        final map = Map<String, dynamic>.from(matchData);
        print("📦 Parsing matchData: $map");
        if (isMutual) {
          userId = map['existingLikeUserId']?.toString();
          userName = map['existingLikeUserName']?.toString() ?? 'Użytkownik';
        } else {
          userId = map['newLikeUserId']?.toString();
          userName = map['newLikeUserName']?.toString() ?? 'Nowy użytkownik';
        }
        print("📝 Parsed: userId=$userId, userName=$userName");
      }

      if (userId == null || userId.isEmpty) {
        print("❌ No userId in notification data");
        return;
      }

      print("🎯 Showing SnackBar for $userName (userId: $userId)");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isMutual ? Icons.celebration : Icons.favorite,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isMutual
                      ? 'To jest match z $userName! 🔥'
                      : '$userName cię polubił! 💜',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isMutual ? Color(0xFFFF6B6B) : Color(0xFF6B4CE6),
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          action: SnackBarAction(
            label: 'ZOBACZ',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchScreen(
                    api: api,
                    tokens: tokens,
                    userId: userId!,
                    eventHubService: eventHub,
                  ),
                ),
              );
            },
          ),
        ),
      );

      print("📱 SnackBar shown successfully");
    } catch (e, stackTrace) {
      print("❌ Error showing global notification: $e");
      print("Stack: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    void onAuthSuccess(BuildContext navContext) {
      print("🔐 User logged in - connecting SignalR");
      eventHub.connect().then((_) {
        print("✅ SignalR connected after login");
        // Callbacks are already set in initState
      });
      _hydrateCurrentUserId();
      Navigator.pushReplacementNamed(navContext, '/discover');
    }

    void onRegisterSuccess(BuildContext navContext) {
      print("🔐 User registered - connecting SignalR");
      eventHub.connect().then((_) {
        print("✅ SignalR connected after registration");
        // Callbacks are already set in initState
      });
      _hydrateCurrentUserId();
      Navigator.pushReplacementNamed(navContext, '/profile/create');
    }

    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Soundmates Demo',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/login',
            routes: {
              '/login': (c) => LoginScreen(
                api: api,
                tokens: tokens,
                onLoggedIn: () => onAuthSuccess(c),
              ),
              '/register': (c) => RegisterScreen(
                api: api,
                tokens: tokens,
                onRegistered: () => onRegisterSuccess(c),
              ),
              '/profile': (c) => profile_new.ProfileScreen(
                api: api,
                tokens: tokens,
                startInEditMode: false,
              ),
              '/profile/create': (c) => profile_new.ProfileScreen(
                api: api,
                tokens: tokens,
                startInEditMode: true,
                isFromRegistration: true,
              ),
              '/profile/edit': (c) =>
                  ProfileEditBasicInfoScreen(api: api, tokens: tokens),
              '/profile/edit-tags': (c) =>
                  ProfileEditTagsScreen(api: api, tokens: tokens),
              '/profile/add-media': (c) =>
                  ProfileAddMediaScreen(api: api, tokens: tokens),
              '/profile/manage-media': (c) =>
                  ProfileManageMediaScreen(api: api, tokens: tokens),
              '/matches': (c) =>
                  MatchesScreen(api: api, tokens: tokens, eventHubService: eventHub),
              '/discover': (c) =>
                  SwipingScreen(api: api, tokens: tokens, eventHubService: eventHub),
              '/filters': (c) => FiltersScreen(api: api, tokens: tokens),
              '/settings': (c) => SettingsScreen(api: api, tokens: tokens),
              '/terms': (c) => const TermsOfServiceScreen(),
            },
          );
        },
      ),
    );
  }
}

