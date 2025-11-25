import 'dart:convert';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:zpi_test/screens/visit_profile/visit_profile_screen.dart';
import 'package:flutter/services.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_side_nav.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../api/event_hub_service.dart';

const Color _filtersBackgroundStart = Color(0xFF2D1B4E);
const Color _filtersBackgroundEnd = Color(0xFF150A32);

class UsersScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final EventHubService? eventHubService;
  const UsersScreen({super.key, required this.api, required this.tokens, this.eventHubService});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  final Map<String, String?> _userImages = {};
  int _totalMatches = 0;
  String? _currentUserCountryId;
  String? _currentUserCityId;
  String? _currentUserCountryName;
  String? _currentUserCityName;
  bool _showArtists = true;
  bool _showBands = true;
  bool _isLoading = false;
  // Keyboard focus and top card control
  final FocusNode _focusNode = FocusNode();
  GlobalKey<_DraggableCardState>? _topCardKey;
  // Tag dictionaries for grouping like in ProfileScreen
  final Map<String, List<TagDto>> _tagGroups = {}; // categoryId -> [TagDto]
  final Map<String, String> _categoryNames = {}; // categoryId -> categoryName
  final Map<String, TagDto> _tagById = {}; // tagId -> TagDto
  // Location dictionaries for resolving IDs to names
  final Map<String, String> _countryIdToName = {}; // countryId -> countryName
  final Map<String, Map<String, String>> _citiesByCountry =
      {}; // countryId -> {cityId: cityName}
  // Gender dictionary for resolving genderId to name
  final Map<String, String> _genderIdToName = {}; // genderId -> genderName
  late final AnimationController _ambientController;
  late final Animation<double> _ambientDrift;

  @override
  void initState() {
    super.initState();
    _loadTagData();
    _loadCountries();
    _loadGenders();
    _loadPreference();
    _loadCurrentUserProfile();
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

  Future<void> _loadTagData() async {
    try {
      final tagsResp = await widget.api.getTags();
      final categoriesResp = await widget.api.getTagCategories();

      if (tagsResp.statusCode == 200 && categoriesResp.statusCode == 200) {
        var tagsDecoded = jsonDecode(tagsResp.body);
        if (tagsDecoded is String) tagsDecoded = jsonDecode(tagsDecoded);
        var catsDecoded = jsonDecode(categoriesResp.body);
        if (catsDecoded is String) catsDecoded = jsonDecode(catsDecoded);

        final List<TagDto> tags = [];
        if (tagsDecoded is List) {
          for (final e in tagsDecoded) {
            if (e is Map) {
              final t = TagDto.fromJson(Map<String, dynamic>.from(e));
              tags.add(t);
              _tagById[t.id] = t;
            }
          }
        }

        if (catsDecoded is List) {
          for (final e in catsDecoded) {
            if (e is Map) {
              final c = TagCategoryDto.fromJson(Map<String, dynamic>.from(e));
              _categoryNames[c.id] = c.name;
              _tagGroups.putIfAbsent(c.id, () => []);
            }
          }
        }

        for (final t in tags) {
          if (t.tagCategoryId != null &&
              _tagGroups.containsKey(t.tagCategoryId)) {
            _tagGroups[t.tagCategoryId]!.add(t);
          }
        }

        if (mounted) setState(() {});
      }
    } catch (_) {
      // silent fail; UI will fallback to plain tags if needed
    }
  }

  Future<void> _loadGenders() async {
    try {
      final resp = await widget.api.getGenders();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final g = GenderDto.fromJson(Map<String, dynamic>.from(e));
              _genderIdToName[g.id] = g.name;
            }
          }
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _loadCountries() async {
    try {
      final resp = await widget.api.getCountries();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final c = CountryDto.fromJson(Map<String, dynamic>.from(e));
              _countryIdToName[c.id] = c.name;
            }
          }
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _loadPreference() async {
    try {
      final resp = await widget.api.getMatchPreference();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is Map) {
          setState(() {
            _showArtists = decoded['showArtists'] is bool
                ? decoded['showArtists']
                : true;
            _showBands = decoded['showBands'] is bool
                ? decoded['showBands']
                : true;
          });
        }
      }
    } catch (_) {
      // ignore, use defaults
    }
    _list();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final resp = await widget.api.getMyProfile();
      if (resp.statusCode != 200) return;
      var decoded = jsonDecode(resp.body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is Map && mounted) {
        setState(() {
          _currentUserCountryId = decoded['countryId']?.toString();
          _currentUserCityId = decoded['cityId']?.toString();
          _currentUserCountryName =
              decoded['countryName']?.toString() ??
              decoded['country']?.toString();
          _currentUserCityName =
              decoded['cityName']?.toString() ?? decoded['city']?.toString();
        });
      }
    } catch (_) {
      // ignore, header will fallback to placeholder
    }
  }

  Future<void> _list() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _users = [];
      _userImages.clear();
    });

    final List<Map<String, dynamic>> allUsers = [];

    // Fetch artists if enabled
    if (_showArtists) {
      try {
        final resp = await widget.api.getPotentialMatchesArtists(
          limit: 50,
          offset: 0,
        );
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(
              decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
            );
          }
        }
      } catch (_) {}
    }

    // Fetch bands if enabled
    if (_showBands) {
      try {
        final resp = await widget.api.getPotentialMatchesBands(
          limit: 50,
          offset: 0,
        );
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(
              decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
            );
          }
        }
      } catch (_) {}
    }

    setState(() {
      _users = allUsers;
      _totalMatches = allUsers.length;
      _isLoading = false;
    });

    // Preload cities for distinct countries present in the list (best-effort)
    await _preloadCitiesForUsers();

    // Fetch images
    for (final u in _users) {
      final id = u['id']?.toString();
      if (id != null && id.isNotEmpty) _fetchUserImage(id, u);
    }
  }

  Future<void> _preloadCitiesForUsers() async {
    try {
      final Set<String> countryIds = {};
      if (_currentUserCountryId != null && _currentUserCountryId!.isNotEmpty) {
        countryIds.add(_currentUserCountryId!);
      }
      for (final u in _users) {
        final c = (u['countryId'] ?? u['country'])?.toString();
        if (c != null && c.isNotEmpty) countryIds.add(c);
      }
      for (final countryId in countryIds) {
        if (_citiesByCountry.containsKey(countryId)) continue;
        try {
          final resp = await widget.api.getCities(countryId);
          if (resp.statusCode == 200) {
            var decoded = jsonDecode(resp.body);
            if (decoded is String) decoded = jsonDecode(decoded);
            final Map<String, String> map = {};
            if (decoded is List) {
              for (final e in decoded) {
                if (e is Map) {
                  final city = CityDto.fromJson(Map<String, dynamic>.from(e));
                  map[city.id] = city.name;
                }
              }
            }
            _citiesByCountry[countryId] = map;
          }
        } catch (_) {}
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  int get _currentMatchIndex {
    if (_totalMatches == 0) return 0;
    if (_users.isEmpty) return _totalMatches;
    final processed = _totalMatches - _users.length;
    final current = processed + 1;
    if (current < 1) return 1;
    if (current > _totalMatches) return _totalMatches;
    return current;
  }

  String get _matchHeadline {
    if (_totalMatches == 0) {
      return _isLoading
          ? 'Fetching potential matches…'
          : 'No potential matches yet';
    }
    return 'Showing $_currentMatchIndex of $_totalMatches potential matches';
  }

  String get _currentLocationLabel {
    final city = _resolveCityName(
      _currentUserCountryId,
      _currentUserCityId,
      _currentUserCityName,
    );
    final country = _resolveCountryName(
      _currentUserCountryId,
      _currentUserCountryName,
    );
    if (city != null && country != null) return '$city, $country';
    return city ?? country ?? 'Location not set';
  }

  String? _resolveCountryName(String? countryId, String? fallback) {
    if (countryId != null) {
      final resolved = _countryIdToName[countryId];
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String? _resolveCityName(
    String? countryId,
    String? cityId,
    String? fallback,
  ) {
    if (countryId != null && cityId != null) {
      final mapped = _citiesByCountry[countryId]?[cityId];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  Future<void> _fetchUserImage(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Try to use profilePictures from the user data first
      if (userData['profilePictures'] is List &&
          (userData['profilePictures'] as List).isNotEmpty) {
        final pics = userData['profilePictures'] as List;
        final first = pics.first;
        if (first is Map) {
          final url = first['url']?.toString();
          if (url != null && url.isNotEmpty) {
            _userImages[userId] = url;
            if (mounted) setState(() {});
            return;
          }
        }
      }

      // Fallback: fetch from endpoint
      final resp = await widget.api.getProfilePicturesForUser(userId);
      if (resp.statusCode != 200) return;
      var decoded = jsonDecode(resp.body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.firstWhere((e) => e is Map, orElse: () => null);
        if (first is Map) {
          // try common fields
          String? url;
          for (final key in [
            'url',
            'fileUrl',
            'downloadUrl',
            'path',
            'file',
            'fileName',
            'filename',
            'id',
          ]) {
            if (first.containsKey(key) && first[key] != null) {
              final v = first[key].toString();
              if (key == 'id') {
                // construct a probable download URL: base/profile-pictures/{id}
                final base = widget.api.baseUrl;
                url = Uri.parse(base).resolve('profile-pictures/$v').toString();
              } else {
                url = v;
              }
              break;
            }
          }
          _userImages[userId] = url;
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> _like(String id) async {
    final resp = await widget.api.like(SwipeDto(receiverId: id));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Like: ${resp.statusCode}')));
  }

  Future<void> _dislike(String id) async {
    final resp = await widget.api.dislike(SwipeDto(receiverId: id));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Dislike: ${resp.statusCode}')));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Widget _buildPhoneExperience(bool isWideLayout) {
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
      child: Stack(
        children: [
          Positioned.fill(
            child: _users.isEmpty
                ? Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'No potential matches.\nTry adjusting your preferences.',
                          ),
                  )
                : Stack(
                    children: List.generate(_users.length, (index) {
                      final u = _users[index];
                      final id = u['id']?.toString() ?? '';
                      final name = u['name']?.toString() ?? '(no name)';
                      final imageUrl = _userImages[id];
                      final top = index == _users.length - 1;
                      final rawCountryId = (u['countryId'] ?? u['country'])
                          ?.toString();
                      final rawCityId = (u['cityId'] ?? u['city'])?.toString();
                      final countryName = rawCountryId != null
                          ? (_countryIdToName[rawCountryId] ??
                                u['countryName']?.toString())
                          : (u['countryName']?.toString() ??
                                u['country']?.toString());
                      final cityName =
                          (rawCountryId != null && rawCityId != null)
                          ? (_citiesByCountry[rawCountryId] != null
                                ? (_citiesByCountry[rawCountryId]![rawCityId] ??
                                      u['cityName']?.toString())
                                : u['cityName']?.toString())
                          : (u['cityName']?.toString() ??
                                u['city']?.toString());
                      String? gender;
                      final isBand = u['isBand'] is bool
                          ? u['isBand'] as bool
                          : false;
                      if (!isBand) {
                        if (u['gender'] != null) {
                          gender = u['gender'].toString();
                        } else if (u['genderId'] != null) {
                          gender = _genderIdToName[u['genderId'].toString()];
                        }
                      }
                      final cardKey = top
                          ? GlobalKey<_DraggableCardState>()
                          : null;
                      if (top) _topCardKey = cardKey;
                      return Positioned.fill(
                        child: DraggableCard(
                          key: cardKey ?? ValueKey(id),
                          name: name,
                          description: u['description']?.toString() ?? '',
                          imageUrl: imageUrl,
                          isBand: isBand,
                          city: cityName,
                          country: countryName,
                          gender: gender,
                          userData: u,
                          tagById: _tagById,
                          categoryNames: _categoryNames,
                          onSwipedLeft: () async {
                            await _dislike(id);
                            setState(() => _users.removeAt(index));
                          },
                          onSwipedRight: () async {
                            await _like(id);
                            setState(() => _users.removeAt(index));
                          },
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
          ),
          if (_users.isEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: Material(
                  color: Colors.white.withOpacity(0.92),
                  shape: const CircleBorder(),
                  elevation: 6,
                  child: IconButton(
                    tooltip: 'Adjust filters',
                    icon: const Icon(Icons.tune, color: Color(0xFF5B3CF0)),
                    onPressed: () => Navigator.pushNamed(context, '/filters'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

          final Widget phoneExperience = _buildPhoneExperience(isWide);
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
            child: SizedBox.expand(child: phoneExperience),
          );
          final Widget framedPhone = SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: phoneShell,
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_filtersBackgroundStart, _filtersBackgroundEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
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
                                const Color(0xFF9C6BFF).withOpacity(0.25),
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
                                  const Color(0xFF40C9FF).withOpacity(0.18),
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
                            child: _WideHeader(
                              headline: _matchHeadline,
                              locationLabel: _currentLocationLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Center the card and side nav together on wide screens
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: shellPadding,
                    child: isWide
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              framedPhone,
                              const SizedBox(width: 32),
                              AppSideNav(current: SideNavItem.home),
                            ],
                          )
                        : framedPhone,
                  ),
                ),
                // Bottom navigation for mobile only
                if (!isWide)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
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

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final bool isElevated;
  final double size;
  final double iconSize;

  const _RoundActionButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.isElevated = false,
    this.size = 56,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isElevated ? 0.25 : 0.15),
              blurRadius: isElevated ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}

class _WideHeader extends StatelessWidget {
  final String headline;
  final String locationLabel;

  const _WideHeader({required this.headline, required this.locationLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                headline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF40C9FF)],
                  ),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your location',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DraggableCard extends StatefulWidget {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isBand;
  final String? city;
  final String? country;
  final String? gender;
  final Map<String, dynamic> userData;
  final Map<String, TagDto> tagById;
  final Map<String, String> categoryNames;
  final VoidCallback onSwipedLeft;
  final VoidCallback onSwipedRight;
  final bool isDraggable;
  final ApiClient api; // Add this
  final TokenStore tokens; // Add this
  final EventHubService? eventHubService;
  final bool showPrimaryActions;
  final VoidCallback? onPrimaryLike;
  final VoidCallback? onPrimaryDislike;
  final VoidCallback? onPrimaryFilter;
  final bool isWideLayout;

  const DraggableCard({
    super.key,
    required this.name,
    required this.description,
    this.imageUrl,
    this.isBand = false,
    this.city,
    this.country,
    this.gender,
    required this.userData,
    required this.tagById,
    required this.categoryNames,
    required this.onSwipedLeft,
    required this.onSwipedRight,
    this.isDraggable = true,
    required this.api, // Add this
    required this.tokens, // Add this
    this.eventHubService,
    this.showPrimaryActions = false,
    this.onPrimaryLike,
    this.onPrimaryDislike,
    this.onPrimaryFilter,
    this.isWideLayout = false,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard>
    with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rot = 0.0;
  late AnimationController _ctrl;
  late Animation<Offset> _animPos;
  late Animation<double> _animRot;
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  bool _isAnimating = false;
  _Decision _decision =
      _Decision.none; // explicit decision state for keyboard swipes

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  List<String> get _allImages {
    final images = <String>[];
    if (widget.imageUrl != null) images.add(widget.imageUrl!);

    // Add more images from profilePictures if available
    if (widget.userData['profilePictures'] is List) {
      final pics = widget.userData['profilePictures'] as List;
      for (final pic in pics) {
        if (pic is Map) {
          String? url;
          // prefer explicit url field
          url = pic['url']?.toString();
          // fallback to fileUrl (backend uses fileUrl) and build absolute
          url ??= pic['fileUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            // Normalize absolute if needed
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              final abs = Uri.parse(widget.api.baseUrl)
                  .resolve(url.startsWith('/') ? url.substring(1) : url)
                  .toString();
              url = abs;
            }
            if (!images.contains(url)) {
              images.add(url);
            }
          }
        }
      }
    }
    return images;
  }

  void _runOffScreen(Offset target, double rot, VoidCallback onComplete) {
    _animPos = Tween(
      begin: _pos,
      end: target,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _animRot = Tween(
      begin: _rot,
      end: rot,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.addListener(() {
      setState(() {
        _pos = _animPos.value;
        _rot = _animRot.value;
      });
    });
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _isAnimating = false;
        _decision = _Decision.none; // reset decision after animation completes
        onComplete();
      }
    });
    _ctrl.forward(from: 0);
  }

  // Programmatic swipe controls (used by arrow keys)
  void swipeRight() {
    if (_isAnimating || !widget.isDraggable) return;
    _isAnimating = true;
    _decision = _Decision.like;
    final w = MediaQuery.of(context).size.width;
    _runOffScreen(Offset(w * 1.5, _pos.dy), 0.5, widget.onSwipedRight);
  }

  void swipeLeft() {
    if (_isAnimating || !widget.isDraggable) return;
    _isAnimating = true;
    _decision = _Decision.nope;
    final w = MediaQuery.of(context).size.width;
    _runOffScreen(Offset(-w * 1.5, _pos.dy), -0.5, widget.onSwipedLeft);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final images = _allImages;
    final bool isWide = widget.isWideLayout;
    final double heroHeight = isWide ? h * 0.48 : h * 0.45;
    final double actionButtonSize = isWide ? 44 : 50;
    final double actionIconSize = isWide ? 20 : 22;
    final double actionSpacing = isWide ? 12 : 16;
    final double contentBottomPadding = widget.showPrimaryActions
        ? (isWide ? 150 : 190)
        : (isWide ? 110 : 140);
    final threshold = w * 0.25;
    final dragLike = (_pos.dx / threshold).clamp(0.0, 1.0);
    final dragNope = (-_pos.dx / threshold).clamp(0.0, 1.0);
    final likeOpacity = _decision == _Decision.like ? 1.0 : dragLike;
    final nopeOpacity = _decision == _Decision.nope ? 1.0 : dragNope;

    // Extract tags grouped by category (analogous to ProfileScreen)
    final Map<String, List<String>> groupedTags = {};
    if (widget.userData['tagsIds'] is List) {
      for (final raw in (widget.userData['tagsIds'] as List)) {
        final id = raw?.toString();
        if (id == null) continue;
        final tag = widget.tagById[id];
        if (tag == null) continue;
        final catId = tag.tagCategoryId ?? '';
        final catName = widget.categoryNames[catId] ?? 'Other';
        groupedTags.putIfAbsent(catName, () => []);
        groupedTags[catName]!.add(tag.name);
      }
    } else if (widget.userData['tags'] is List) {
      // Fallback: when backend returns names directly
      groupedTags['Tags'] = (widget.userData['tags'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Extract age for artists
    int? age;
    if (widget.userData['birthDate'] != null && !widget.isBand) {
      try {
        final birthDate = DateTime.parse(
          widget.userData['birthDate'].toString(),
        );
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }

    // Extract band members
    final bandMembers = <Map<String, dynamic>>[];
    if (widget.isBand && widget.userData['bandMembers'] is List) {
      bandMembers.addAll(
        (widget.userData['bandMembers'] as List).whereType<Map>().map(
          (m) => Map<String, dynamic>.from(m),
        ),
      );
    }

    return Transform.translate(
      offset: _pos,
      child: Transform.rotate(
        angle: _rot,
        child: GestureDetector(
          onTap: () {
            // Tap to toggle image
            if (images.length > 1) {
              setState(() {
                _currentImageIndex = (_currentImageIndex + 1) % images.length;
              });
            }
          },
          onPanUpdate: widget.isDraggable
              ? (d) {
                  setState(() {
                    _pos += d.delta;
                    _rot = _pos.dx / (w * 4);
                  });
                }
              : null,
          onPanEnd: widget.isDraggable
              ? (e) {
                  final threshold = w * 0.25;
                  if (_pos.dx > threshold) {
                    _runOffScreen(
                      Offset(w * 1.5, _pos.dy),
                      0.5,
                      widget.onSwipedRight,
                    );
                  } else if (_pos.dx < -threshold) {
                    _runOffScreen(
                      Offset(-w * 1.5, _pos.dy),
                      -0.5,
                      widget.onSwipedLeft,
                    );
                  } else {
                    // snap back
                    _animPos = Tween(begin: _pos, end: Offset.zero).animate(
                      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                    );
                    _animRot = Tween(begin: _rot, end: 0.0).animate(
                      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
                    );
                    _ctrl.addListener(() {
                      setState(() {
                        _pos = _animPos.value;
                        _rot = _animRot.value;
                      });
                    });
                    _ctrl.forward(from: 0);
                  }
                }
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isWide ? 32 : 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isWide ? 32 : 0),
                boxShadow: isWide
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Scrollable content
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.only(bottom: contentBottomPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main image section with indicators
                            Stack(
                              children: [
                                // Image
                                Container(
                                  height: heroHeight,
                                  width: double.infinity,
                                  child: images.isNotEmpty
                                      ? Image.network(
                                          images[_currentImageIndex],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[300],
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 100,
                                                    color: Colors.grey[500],
                                                  ),
                                                );
                                              },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.person,
                                            size: 100,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                ),
                                // (Removed small overlays; replaced by global stamps below)
                                // Image indicators
                                if (images.length > 1)
                                  Positioned(
                                    top: 8,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      children: List.generate(
                                        images.length,
                                        (idx) => Expanded(
                                          child: Container(
                                            height: 3,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: idx == _currentImageIndex
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(
                                                      0.5,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Artist/Band Tag (Top Right)
                                Positioned(
                                  top: 24,
                                  right: 20,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isWide ? 12 : 16,
                                      vertical: isWide ? 6 : 8,
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
                                      widget.isBand ? 'BAND' : 'ARTIST',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isWide ? 11 : 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                                // Gradient overlay at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: heroHeight * 0.8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          const Color(
                                            0xFF150A32,
                                          ).withOpacity(0.2),
                                          const Color(
                                            0xFF150A32,
                                          ).withOpacity(0.8),
                                          const Color(0xFF150A32),
                                        ],
                                        stops: const [0.0, 0.3, 0.75, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Name and location overlay
                                Positioned(
                                  bottom: 12,
                                  left: 20,
                                  right: 20,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final userId =
                                              widget.userData['id']
                                                  ?.toString() ??
                                              '';
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VisitProfileScreen(
                                                    api: widget.api,
                                                    tokens: widget.tokens,
                                                    userId: userId,
                                                    eventHubService: widget.eventHubService,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          '${widget.name}${age != null ? ', $age' : ''}',
                                          style: TextStyle(
                                            fontSize: isWide ? 22 : 24,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if ((widget.city ?? '').isNotEmpty ||
                                          (widget.country ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            [widget.city, widget.country]
                                                .where(
                                                  (e) =>
                                                      e != null && e.isNotEmpty,
                                                )
                                                .join(', ')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.95,
                                              ),
                                              fontSize: isWide ? 11 : 12,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.0,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (widget.showPrimaryActions) ...[
                                        const SizedBox(height: 18),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _RoundActionButton(
                                              icon: Icons.close,
                                              backgroundColor: Colors.white
                                                  .withOpacity(0.92),
                                              iconColor: const Color(
                                                0xFF9245D5,
                                              ),
                                              onTap:
                                                  widget.onPrimaryDislike ??
                                                  () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                            ),
                                            SizedBox(width: actionSpacing),
                                            _RoundActionButton(
                                              icon: Icons.tune,
                                              backgroundColor: Colors.white
                                                  .withOpacity(0.92),
                                              iconColor: const Color(
                                                0xFF4C3F8F,
                                              ),
                                              onTap:
                                                  widget.onPrimaryFilter ??
                                                  () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                              isElevated: true,
                                            ),
                                            SizedBox(width: actionSpacing),
                                            _RoundActionButton(
                                              icon: Icons.favorite,
                                              backgroundColor: Colors.white
                                                  .withOpacity(0.92),
                                              iconColor: const Color(
                                                0xFFE65080,
                                              ),
                                              onTap:
                                                  widget.onPrimaryLike ?? () {},
                                              size: actionButtonSize,
                                              iconSize: actionIconSize,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // About section
                            if (widget.description.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 20,
                                  vertical: isWide ? 16 : 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ABOUT',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF6A4DBE),
                                      ),
                                    ),
                                    SizedBox(height: isWide ? 8 : 10),
                                    Text(
                                      widget.description,
                                      style: TextStyle(
                                        fontSize: isWide ? 13 : 14,
                                        height: 1.45,
                                        color: const Color(0xFF1F1F1F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Tag sections styled per mock
                            if (groupedTags.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 20,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: groupedTags.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 18,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.key.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isWide ? 12 : 13,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                              color: const Color(0xFF6A4DBE),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: isWide ? 6 : 8,
                                            runSpacing: isWide ? 8 : 10,
                                            children: entry.value
                                                .map(
                                                  (tagName) => Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: isWide
                                                              ? 12
                                                              : 16,
                                                          vertical: isWide
                                                              ? 8
                                                              : 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors
                                                          .deepPurple
                                                          .shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors
                                                            .deepPurple
                                                            .shade200,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      tagName,
                                                      style: TextStyle(
                                                        fontSize: isWide
                                                            ? 11
                                                            : 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .deepPurple
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            // Gender section (under tags)
                            if (widget.gender != null &&
                                widget.gender!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GENDER',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: const Color(0xFF6A4DBE),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.gender!,
                                      style: TextStyle(
                                        fontSize: isWide ? 13 : 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Band members section
                            if (bandMembers.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 18 : 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'BAND MEMBERS',
                                      style: TextStyle(
                                        fontSize: isWide ? 12 : 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: const Color(0xFF6A4DBE),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...bandMembers.map((member) {
                                      final name =
                                          member['name']?.toString() ?? '';
                                      final age =
                                          member['age']?.toString() ?? '';
                                      final role =
                                          member['bandRole']?.toString() ??
                                          member['bandRoleName']?.toString() ??
                                          '';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  Colors.purple[100],
                                              child: Icon(
                                                Icons.person,
                                                color: Colors.purple[700],
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '$name${age.isNotEmpty ? ', $age' : ''}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: isWide
                                                          ? 13
                                                          : 14,
                                                    ),
                                                  ),
                                                  if (role.isNotEmpty)
                                                    Text(
                                                      role,
                                                      style: TextStyle(
                                                        fontSize: isWide
                                                            ? 11
                                                            : 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // Tinted decision overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: likeOpacity > 0
                                ? Colors.green.withOpacity(
                                    (isWide ? 0.06 : 0.10) * likeOpacity + 0.04,
                                  )
                                : nopeOpacity > 0
                                ? Colors.redAccent.withOpacity(
                                    (isWide ? 0.06 : 0.10) * nopeOpacity + 0.04,
                                  )
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // Large LIKE stamp
                    Positioned(
                      top: isWide ? 20 : 28,
                      right: isWide ? 18 : 24,
                      child: Opacity(
                        opacity: likeOpacity,
                        child: Transform.rotate(
                          angle: 0.18,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 14 : 18,
                              vertical: isWide ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border.all(color: Colors.green, width: 4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'LIKE',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: isWide ? 30 : 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Large NOPE stamp
                    Positioned(
                      top: isWide ? 20 : 28,
                      left: isWide ? 18 : 24,
                      child: Opacity(
                        opacity: nopeOpacity,
                        child: Transform.rotate(
                          angle: -0.18,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 14 : 18,
                              vertical: isWide ? 8 : 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border.all(
                                color: Colors.redAccent,
                                width: 4,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'NOPE',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: isWide ? 30 : 38,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Decision { none, like, nope }
