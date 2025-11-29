import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_side_nav.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/event_hub_service.dart';
import 'swiping/swiping_data_loader.dart';
import 'swiping/swiping_view_model.dart';
import 'swiping/widgets/swiping_card.dart';
import 'swiping/widgets/swiping_empty_state.dart';
import 'swiping/widgets/swiping_wide_header.dart';
import '../../theme/app_design_system.dart';

class SwipingScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;

  const SwipingScreen({
    super.key,
    required this.api,
    required this.tokens,
    this.eventHubService,
  });

  @override
  State<SwipingScreen> createState() => _SwipingScreenState();
}

class _SwipingScreenState extends State<SwipingScreen>
    with SingleTickerProviderStateMixin {
  late SwipingDataLoader _dataLoader;
  SwipingViewModel? _viewModel;
  bool _isLoading = true;
  String? _error;

  // Keyboard focus and top card control
  final FocusNode _focusNode = FocusNode();
  GlobalKey<DraggableCardState>? _topCardKey;

  late final AnimationController _ambientController;
  late final Animation<double> _ambientDrift;

  @override
  void initState() {
    super.initState();
    _dataLoader = SwipingDataLoader(widget.api);
    _loadData();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat(reverse: true);
    _ambientDrift = CurvedAnimation(
      parent: _ambientController,
      curve: Curves.easeInOut,
    );

    // Ensure the screen captures keyboard focus for arrow key swipes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final viewModel = await _dataLoader.loadData();
      if (mounted) {
        setState(() {
          _viewModel = viewModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLike(String id, int index) async {
    await _dataLoader.like(id);
    if (mounted) {
      setState(() {
        _viewModel = SwipingViewModel(
          users: List.from(_viewModel!.users)..removeAt(index),
          userImages: _viewModel!.userImages,
          totalMatches: _viewModel!.totalMatches,
          tagById: _viewModel!.tagById,
          categoryNames: _viewModel!.categoryNames,
          countryIdToName: _viewModel!.countryIdToName,
          citiesByCountry: _viewModel!.citiesByCountry,
          genderIdToName: _viewModel!.genderIdToName,
          currentUserCountryId: _viewModel!.currentUserCountryId,
          currentUserCityId: _viewModel!.currentUserCityId,
          currentUserCountryName: _viewModel!.currentUserCountryName,
          currentUserCityName: _viewModel!.currentUserCityName,
          showArtists: _viewModel!.showArtists,
          showBands: _viewModel!.showBands,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Like sent!')));
      }
    }
  }

  Future<void> _handleDislike(String id, int index) async {
    await _dataLoader.dislike(id);
    if (mounted) {
      setState(() {
        _viewModel = SwipingViewModel(
          users: List.from(_viewModel!.users)..removeAt(index),
          userImages: _viewModel!.userImages,
          totalMatches: _viewModel!.totalMatches,
          tagById: _viewModel!.tagById,
          categoryNames: _viewModel!.categoryNames,
          countryIdToName: _viewModel!.countryIdToName,
          citiesByCountry: _viewModel!.citiesByCountry,
          genderIdToName: _viewModel!.genderIdToName,
          currentUserCountryId: _viewModel!.currentUserCountryId,
          currentUserCityId: _viewModel!.currentUserCityId,
          currentUserCountryName: _viewModel!.currentUserCountryName,
          currentUserCityName: _viewModel!.currentUserCityName,
          showArtists: _viewModel!.showArtists,
          showBands: _viewModel!.showBands,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dislike sent!')));
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Widget _buildPhoneExperience(bool isWideLayout) {
    if (_isLoading || _viewModel == null) {
      return SwipingEmptyState(
        isLoading: _isLoading,
        onFilterTap: () => Navigator.pushNamed(context, '/filters'),
      );
    }

    final users = _viewModel!.users;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          final key = event.logicalKey;
          if (key == LogicalKeyboardKey.arrowRight) {
            _topCardKey?.currentState?.swipeRight();
          } else if (key == LogicalKeyboardKey.arrowLeft) {
            _topCardKey?.currentState?.swipeLeft();
          }
        }
      },
      child: users.isEmpty
          ? SwipingEmptyState(
              isLoading: false,
              onFilterTap: () => Navigator.pushNamed(context, '/filters'),
            )
          : Stack(
              children: List.generate(users.length, (index) {
                final cardData = users[index];
                final imageUrl = _viewModel!.userImages[cardData.id];
                final top = index == users.length - 1;

                final cardKey = top ? GlobalKey<DraggableCardState>() : null;
                if (top) _topCardKey = cardKey;

                return Positioned.fill(
                  child: DraggableCard(
                    key: cardKey ?? ValueKey(cardData.id),
                    name: cardData.name,
                    description: cardData.description,
                    imageUrl: imageUrl,
                    isBand: cardData.isBand,
                    city: cardData.city,
                    country: cardData.country,
                    gender: cardData.gender,
                    userData: cardData.userData,
                    tagById: _viewModel!.tagById,
                    categoryNames: _viewModel!.categoryNames,
                    onSwipedLeft: () => _handleDislike(cardData.id, index),
                    onSwipedRight: () => _handleLike(cardData.id, index),
                    isDraggable: top,
                    api: widget.api,
                    tokens: widget.tokens,
                    eventHubService: widget.eventHubService,
                    showPrimaryActions: top,
                    isWideLayout: isWideLayout,
                    onPrimaryDislike: () =>
                        _topCardKey?.currentState?.swipeLeft(),
                    onPrimaryFilter: () =>
                        Navigator.pushNamed(context, '/filters'),
                    onPrimaryLike: () =>
                        _topCardKey?.currentState?.swipeRight(),
                  ),
                );
              }),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
          final bool isFramed =
              !isMobile && isLandscape && constraints.maxWidth > basePhoneWidth;

          // Navigation visibility
          final bool showSideNav = isFramed && isLandscape;
          final bool showBottomNav = !isFramed || (isFramed && !isLandscape);
          final bool showWideHeader = isFramed && constraints.maxWidth > 1100;

          final Widget phoneExperience = _buildPhoneExperience(isFramed);

          // Calculate final dimensions
          double availableWidth = constraints.maxWidth;
          double availableHeight = constraints.maxHeight;

          if (showSideNav) {
            availableWidth -= 200;
          }

          // For framed screens: navbar gets its own space (subtract height)
          // For non-framed: navbar floats over card (don't subtract)
          if (showBottomNav && isFramed) {
            availableHeight -= 100;
          }

          final double maxH = availableHeight * 0.95;
          final double hFromW = availableWidth * (16 / 9);
          final double phoneHeight = (hFromW < maxH) ? hFromW : maxH;
          final double phoneWidth = phoneHeight * (9 / 16);

          final Widget framedPhone = isFramed
              ? ConstrainedBox(
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
                          color: AppColors.surfaceWhite,
                          boxShadow: AppShadows.floatingCardShadow,
                        ),
                        child: phoneExperience,
                      ),
                    ),
                  ),
                )
              : SizedBox.expand(child: phoneExperience);

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.backgroundFilterStart,
                  AppColors.backgroundFilterEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Main content area
                Positioned.fill(
                  bottom: (showBottomNav && isFramed) ? 80 : 0,
                  child: Stack(
                    children: [
                      // Ambient gradient background
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _ambientDrift,
                            builder: (context, _) {
                              final Alignment centerOne = Alignment(
                                lerpDouble(-0.4, 0.3, _ambientDrift.value)!,
                                lerpDouble(-0.8, -0.2, _ambientDrift.value)!,
                              );
                              final Alignment centerTwo = Alignment(
                                lerpDouble(0.8, -0.2, _ambientDrift.value)!,
                                lerpDouble(0.6, 0.2, _ambientDrift.value)!,
                              );
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: centerOne,
                                    radius: 1.2,
                                    colors: [
                                      AppColors.accentPurpleLight.withOpacity(
                                        0.25,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: centerTwo,
                                      radius: 1.0,
                                      colors: [
                                        AppColors.accentBlue.withOpacity(0.18),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Wide header
                      if (isFramed && _viewModel != null)
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
                                  child: SwipingWideHeader(
                                    headline: _viewModel!.matchHeadline,
                                    locationLabel:
                                        _viewModel!.currentLocationLabel,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Center content
                      Padding(
                        padding: EdgeInsets.only(
                          top: showWideHeader ? 10 : 0,
                          bottom: showWideHeader ? 10 : 0,
                        ),
                        child: Center(
                          child: showSideNav
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    framedPhone,
                                    const SizedBox(width: 16),
                                    AppSideNav(current: SideNavItem.home),
                                  ],
                                )
                              : framedPhone,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom navigation
                if (showBottomNav)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        child: AppBottomNav(current: BottomNavItem.home),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
