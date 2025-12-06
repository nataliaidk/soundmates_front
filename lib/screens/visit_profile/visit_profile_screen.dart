import 'dart:ui'; // Wymagane dla ImageFilter (Blur)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:soundmates/screens/matches_screen.dart';

// Importy zależności projektu
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/event_hub_service.dart';
import '../chat_screen.dart';

// Importy naszej nowej struktury
import 'visit_profile_loader.dart';
import 'visit_profile_model.dart';
import 'widgets/visit_profile_header.dart';
import 'widgets/visit_info_tab.dart';
import 'widgets/visit_media_tab.dart';
import '../../theme/app_design_system.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_side_nav.dart';

class VisitProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final String userId;
  final EventHubService? eventHubService;

  const VisitProfileScreen({
    super.key,
    required this.api,
    required this.tokens,
    required this.userId,
    this.eventHubService,
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
          eventHubService: widget.eventHubService,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              final bool isMobile =
                  defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.android;

              // Calculate base phone dimensions
              final double basePhoneHeight = constraints.maxHeight * 0.95;
              final double basePhoneWidth = basePhoneHeight * (9 / 16);

              // Framed mode
              final bool isLandscape =
                  constraints.maxWidth > constraints.maxHeight;
              final bool isFramed =
                  !isMobile &&
                  isLandscape &&
                  constraints.maxWidth > basePhoneWidth;

              // Navigation visibility - removed for visit profile screen
              final bool showSideNav = false;
              final bool showBottomNav = false;
              final bool showWideHeader =
                  isFramed && constraints.maxWidth > 1100;

              // Calculate final dimensions - use FULL screen for centering
              double availableWidth = constraints.maxWidth;
              double availableHeight = constraints.maxHeight;

              // Don't subtract bottom nav height - we want to center on full screen
              final double maxH = availableHeight * 0.95;
              final double hFromW = availableWidth * (16 / 9);
              final double phoneHeight = (hFromW < maxH) ? hFromW : maxH;
              final double phoneWidth = phoneHeight * (9 / 16);

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
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Unmatch $userName?'),
                                content: const Text(
                                  'Are you sure you want to unmatch? You won\'t be able to text with this user anymore.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      // Close dialog first
                                      Navigator.pop(context);

                                      try {
                                        final response = await widget.api
                                            .unmatch(widget.userId);
                                        if (response.statusCode == 200) {
                                          if (mounted) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MatchesScreen(
                                                      api: widget.api,
                                                      tokens: widget.tokens,
                                                      eventHubService: widget
                                                          .eventHubService,
                                                    ),
                                              ),
                                            );
                                          }
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to unmatch: ${response.statusCode}',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Unmatch'),
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
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.vertical(
                          top: isFramed
                              ? const Radius.circular(32)
                              : Radius.zero,
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
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceWhite,
                              borderRadius: BorderRadius.vertical(
                                top: isFramed
                                    ? const Radius.circular(32)
                                    : Radius.zero,
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
                                                  : (isDark
                                                        ? AppColors
                                                              .surfaceDarkGrey
                                                        : AppColors
                                                              .backgroundLight),
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
                                                      : (isDark
                                                            ? AppColors
                                                                  .textWhite70
                                                            : AppColors
                                                                  .textPrimaryAlt),
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
                                                  : (isDark
                                                        ? AppColors
                                                              .surfaceDarkGrey
                                                        : AppColors
                                                              .backgroundLight),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Media',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      _tabController.index == 1
                                                      ? AppColors.surfaceWhite
                                                      : (isDark
                                                            ? AppColors
                                                                  .textWhite70
                                                            : AppColors
                                                                  .textPrimaryAlt),
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
                                VisitInfoTab(
                                  data: data,
                                  api: widget.api,
                                  userId: widget.userId,
                                ),
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

                  // 2. BAND/ARTIST Badge (Top right corner)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        isBand ? 'BAND' : 'ARTIST',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );

              final Widget framedPhone = isFramed
                  ? Center(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: phoneHeight,
                            maxWidth: phoneWidth,
                          ),
                          child: AspectRatio(
                            aspectRatio: 9 / 16,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(36),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 60,
                                      offset: const Offset(0, 30),
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: profileContent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox.expand(child: profileContent);

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
                    if (showWideHeader)
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

                    // Main Content with Navigation - use Stack for absolute centering
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                // Centered phone card
                                Center(child: framedPhone),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Mobile Bottom Nav Overlay
                    if (showBottomNav && !isFramed)
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AppBottomNav(current: BottomNavItem.home),
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
                'Is this your Soundmate?',
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
