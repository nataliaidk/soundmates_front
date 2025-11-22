import 'dart:ui'; // Wymagane dla ImageFilter (Blur)
import 'dart:convert';
import 'package:flutter/material.dart';

// Importy zależności projektu
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../widgets/app_bottom_nav.dart';
import '../chat_screen.dart';

// Importy naszej nowej struktury
import 'visit_profile_loader.dart';
import 'visit_profile_model.dart';
import 'widgets/visit_profile_header.dart';
import 'widgets/visit_info_tab.dart';
import 'widgets/visit_media_tab.dart';

class VisitProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final String userId;

  const VisitProfileScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.userId,
  });

  @override
  State<VisitProfileScreen> createState() => _VisitProfileScreenState();
}

class _VisitProfileScreenState extends State<VisitProfileScreen>
    with SingleTickerProviderStateMixin {
  // Logika i Stan
  late final VisitProfileLoader _loader;
  late Future<VisitProfileViewModel> _dataFuture;
  late final TabController _tabController;
  bool _isMatched = false;

  // Kolory tła z oryginału
  final Color _softBg = const Color(0xFFF8F9FC);
  final Color _surfaceWhite = Colors.white;
  final Color _accentPurple = const Color(0xFF7B51D3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Inicjalizacja Loadera
    _loader = VisitProfileLoader(widget.api);

    // Rozpoczęcie pobierania danych
    _dataFuture = _loader.loadData(widget.userId);

    // Check if user is in matches list
    _checkIfMatched();
  }

  Future<void> _checkIfMatched() async {
    try {
      final response = await widget.api.getMatches();
      if (response.statusCode == 200) {
        final List<dynamic> matches = jsonDecode(response.body);
        final isMatch = matches.any((match) => match['id'] == widget.userId);
        if (mounted) {
          setState(() {
            _isMatched = isMatch;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            // Match check failed silently
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking match status: $e');
      if (mounted) {
        setState(() {
          // Match check failed silently
        });
      }
    }
  }

  Future<void> _navigateToChat(VisitProfileViewModel data) async {
    // Get user name and image URL from data
    final userName = data.profile.name ?? 'User';
    final userImageUrl = data.profileImageUrl;
    debugPrint('Navigating to chat with user: $userName ($userImageUrl)');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          api: widget.api,
          tokens: widget.tokens,
          userId: widget.userId,
          userName: userName,
          userImageUrl: userImageUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VisitProfileViewModel>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // 1. Stan Ładowania
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: _softBg,
            body: Center(
              child: CircularProgressIndicator(color: _accentPurple),
            ),
          );
        }

        // 2. Stan Błędu
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _softBg,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        // 3. Stan Danych (Sukces)
        final data = snapshot.data!;

        return Scaffold(
          backgroundColor: _surfaceWhite,
          body: Stack(
            children: [
              // Główny widok przewijany z Sticky Headerem
              NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    VisitProfileHeader(
                      data: data,
                      isMatched: _isMatched,
                      onUnmatch: () {
                        // Show dialog that unmatch is not available
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Unmatch'),
                            content: const Text(
                              'Unmatch feature is not available yet.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      onMessage: () => _navigateToChat(data),
                    ),
                  ];
                },
                body: Container(
                  // Zaokrąglenie góry kontenera, aby "wjeżdżał" na zdjęcie
                  decoration: BoxDecoration(
                    color: _surfaceWhite,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  // Lekki margines ujemny w oryginale, tu zerujemy dla czystości,
                  // efekt załatwia sliver
                  child: Column(
                    children: [
                      // Sticky Tab Header Area
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        decoration: BoxDecoration(
                          color: _surfaceWhite,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Custom Styled TabBar
                            Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: _softBg,
                                borderRadius: BorderRadius.circular(23),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                padding: const EdgeInsets.all(4),
                                labelColor: Colors.black,
                                unselectedLabelColor: Colors.grey[500],
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                indicator: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Details'),
                                  Tab(text: 'Gallery'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Scrollable Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            VisitInfoTab(data: data),
                            VisitMediaTab(items: data.galleryItems),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Pływające Elementy UI (Glassmorphism) ---

              // 1. Przycisk Wstecz (Lewy górny róg)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: _buildGlassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
              ),

              // 2. Badge Dystansu (Prawy górny róg)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      color: Colors.black.withOpacity(0.2),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            "2.5 km", // Placeholder z oryginału
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Dolna nawigacja
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNav(current: BottomNavItem.home),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget pomocniczy: Szklany przycisk (Back Button)
  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.black.withOpacity(0.2),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
