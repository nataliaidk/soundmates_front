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
import '../../theme/app_design_system.dart';

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
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D1B4E), Color(0xFF150A32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accentPurple),
              ),
            ),
          );
        }

        // 2. Stan Błędu
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2D1B4E), Color(0xFF150A32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }

        // 3. Stan Danych (Sukces)
        final data = snapshot.data!;
        final String userName = data.profile.name ?? 'User';
        final bool isBand = data.profile.isBand ?? false;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 800;
              final bool showWideHeader = constraints.maxWidth > 1100;
              final double borderRadius = isWide ? 36 : 0;
              final EdgeInsets shellPadding = isWide
                  ? const EdgeInsets.symmetric(horizontal: 120, vertical: 20)
                  : EdgeInsets.zero;
              final double availableWidth =
                  (constraints.maxWidth - shellPadding.horizontal)
                      .clamp(0.0, constraints.maxWidth)
                      .toDouble();
              final double availableHeight =
                  (constraints.maxHeight - shellPadding.vertical)
                      .clamp(0.0, constraints.maxHeight)
                      .toDouble();
              // Use fixed width on wide screens instead of percentage-based
              final double cardWidth = isWide ? 440.0 : availableWidth;
              final double cardHeight = isWide
                  ? availableHeight * 0.99
                  : availableHeight;

              final Widget profileContent = Stack(
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
                        color: AppColors.surfaceWhite,
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
                              color: AppColors.surfaceWhite,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Custom Styled Tabs (button style)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _tabController.index = 0,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _tabController.index == 0
                                                  ? AppColors.accentPurple
                                                  : AppColors.backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Details',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _tabController.index == 0
                                                      ? AppColors.surfaceWhite
                                                      : AppColors
                                                            .textPrimaryAlt,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _tabController.index = 1,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _tabController.index == 1
                                                  ? AppColors.accentPurple
                                                  : AppColors.backgroundLight,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Gallery',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _tabController.index == 1
                                                      ? AppColors.surfaceWhite
                                                      : AppColors
                                                            .textPrimaryAlt,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
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
                              Icon(
                                Icons.near_me,
                                color: Colors.white,
                                size: 14,
                              ),
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
                ],
              );

              final Widget phoneShell = Container(
                clipBehavior: borderRadius > 0 ? Clip.antiAlias : Clip.none,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: isWide
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 30),
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: SizedBox.expand(child: profileContent),
              );

              final Widget framedPhone = SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: phoneShell,
              );

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D1B4E), Color(0xFF150A32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Wide header
                    if (isWide)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          bottom: false,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 350),
                            opacity: showWideHeader ? 1 : 0,
                            child: Visibility(
                              visible: showWideHeader,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 72,
                                  vertical: 32,
                                ),
                                child: _buildWideHeader(userName, isBand),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(padding: shellPadding, child: framedPhone),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: const AppBottomNav(
                            current: BottomNavItem.home,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Widget pomocniczy: Wide Header for profile name
  Widget _buildWideHeader(String userName, bool isBand) {
    final theme = Theme.of(context);
    final String profileType = isBand ? 'Band Profile' : 'Artist Profile';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$userName's Profile",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'View full $profileType',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
