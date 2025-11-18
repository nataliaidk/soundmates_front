import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zpi_test/screens/visit_profile_screen.dart';
import 'package:flutter/services.dart';
import '../widgets/app_bottom_nav.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';

class UsersScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const UsersScreen({super.key, required this.api, required this.tokens});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _out = '';
  List<Map<String, dynamic>> _users = [];
  final Map<String, String?> _userImages = {};
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
  final Map<String, Map<String, String>> _citiesByCountry = {}; // countryId -> {cityId: cityName}
  // Gender dictionary for resolving genderId to name
  final Map<String, String> _genderIdToName = {}; // genderId -> genderName

  @override
  void initState() {
    super.initState();
    _loadTagData();
    _loadCountries();
    _loadGenders();
    _loadPreference();
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
          if (t.tagCategoryId != null && _tagGroups.containsKey(t.tagCategoryId)) {
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
            _showArtists = decoded['showArtists'] is bool ? decoded['showArtists'] : true;
            _showBands = decoded['showBands'] is bool ? decoded['showBands'] : true;
          });
        }
      }
    } catch (_) {
      // ignore, use defaults
    }
    _list();
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
        final resp = await widget.api.getPotentialMatchesArtists(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
          }
        }
      } catch (_) {}
    }

    // Fetch bands if enabled
    if (_showBands) {
      try {
        final resp = await widget.api.getPotentialMatchesBands(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
          }
        }
      } catch (_) {}
    }

    setState(() {
      _users = allUsers;
      _isLoading = false;
      _out = 'Loaded ${_users.length} potential matches';
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

  Future<void> _fetchUserImage(String userId, Map<String, dynamic> userData) async {
    try {
      // Try to use profilePictures from the user data first
      if (userData['profilePictures'] is List && (userData['profilePictures'] as List).isNotEmpty) {
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
          for (final key in ['url', 'fileUrl', 'downloadUrl', 'path', 'file', 'fileName', 'filename', 'id']) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Like: ${resp.statusCode}')));
  }

  Future<void> _dislike(String id) async {
    final resp = await widget.api.dislike(SwipeDto(receiverId: id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dislike: ${resp.statusCode}')));
  }

  Future<void> _showMatches() async {
    final resp = await widget.api.getMatches();
    setState(() => _out = 'Matches: ${resp.statusCode}\n${resp.body}');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RawKeyboardListener(
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
                          : const Text('No potential matches.\nTry adjusting your preferences.'),
                    )
                  : Stack(
                      children: List.generate(_users.length, (index) {
                        final u = _users[index];
                        final id = u['id']?.toString() ?? '';
                        final name = u['name']?.toString() ?? '(no name)';
                        final imageUrl = _userImages[id];
                        final top = index == _users.length - 1;
                        final rawCountryId = (u['countryId'] ?? u['country'])?.toString();
                        final rawCityId = (u['cityId'] ?? u['city'])?.toString();
                        final countryName = rawCountryId != null
                            ? (_countryIdToName[rawCountryId] ?? u['countryName']?.toString())
                            : (u['countryName']?.toString() ?? u['country']?.toString());
                        final cityName = (rawCountryId != null && rawCityId != null)
                            ? (_citiesByCountry[rawCountryId] != null
                                ? (_citiesByCountry[rawCountryId]![rawCityId] ?? u['cityName']?.toString())
                                : u['cityName']?.toString())
                            : (u['cityName']?.toString() ?? u['city']?.toString());
                        String? gender;
                        final isBand = u['isBand'] is bool ? u['isBand'] as bool : false;
                        if (!isBand) {
                          if (u['gender'] != null) {
                            gender = u['gender'].toString();
                          } else if (u['genderId'] != null) {
                            gender = _genderIdToName[u['genderId'].toString()];
                          }
                        }
                        final cardKey = top ? GlobalKey<_DraggableCardState>() : null;
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
                            showPrimaryActions: top,
                            onPrimaryDislike: () => _topCardKey?.currentState?.swipeLeft(),
                            onPrimaryFilter: () => Navigator.pushNamed(context, '/filters'),
                            onPrimaryLike: () => _topCardKey?.currentState?.swipeRight(),
                          ),
                        );
                      }),
                    ),
            ),
            if (_out.isNotEmpty)
              Positioned(
                top: 16,
                left: 20,
                right: 20,
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _out,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            const Positioned(left: 0, right: 0, bottom: 18, child: AppBottomNav(current: BottomNavItem.home)),
          ],
        ),
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

  const _RoundActionButton({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.isElevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62,
        width: 62,
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
        child: Icon(icon, color: iconColor, size: 26),
      ),
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
  final ApiClient api;  // Add this
  final TokenStore tokens;  // Add this
  final bool showPrimaryActions;
  final VoidCallback? onPrimaryLike;
  final VoidCallback? onPrimaryDislike;
  final VoidCallback? onPrimaryFilter;

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
    required this.api,  // Add this
    required this.tokens,  // Add this
    this.showPrimaryActions = false,
    this.onPrimaryLike,
    this.onPrimaryDislike,
    this.onPrimaryFilter,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}


class _DraggableCardState extends State<DraggableCard> with SingleTickerProviderStateMixin {
  Offset _pos = Offset.zero;
  double _rot = 0.0;
  late AnimationController _ctrl;
  late Animation<Offset> _animPos;
  late Animation<double> _animRot;
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  bool _isAnimating = false;
  _Decision _decision = _Decision.none; // explicit decision state for keyboard swipes

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
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
    _animPos = Tween(begin: _pos, end: target).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _animRot = Tween(begin: _rot, end: rot).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      groupedTags['Tags'] = (widget.userData['tags'] as List).map((e) => e.toString()).toList();
    }
    
    // Extract age for artists
    int? age;
    if (widget.userData['birthDate'] != null && !widget.isBand) {
      try {
        final birthDate = DateTime.parse(widget.userData['birthDate'].toString());
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }
    
    // Extract band members
    final bandMembers = <Map<String, dynamic>>[];
    if (widget.isBand && widget.userData['bandMembers'] is List) {
      bandMembers.addAll((widget.userData['bandMembers'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
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
                    _runOffScreen(Offset(w * 1.5, _pos.dy), 0.5, widget.onSwipedRight);
                  } else if (_pos.dx < -threshold) {
                    _runOffScreen(Offset(-w * 1.5, _pos.dy), -0.5, widget.onSwipedLeft);
                  } else {
                    // snap back
                    _animPos = Tween(begin: _pos, end: Offset.zero).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
                    _animRot = Tween(begin: _rot, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
            borderRadius: BorderRadius.zero,
            child: Container(
              color: Colors.white,
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    // Scrollable content
                    Positioned.fill(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main image section with indicators
                      Stack(
                        children: [
                          // Image
                          Container(
                            height: h * 0.5,
                            width: double.infinity,
                            child: images.isNotEmpty
                                ? Image.network(
                                    images[_currentImageIndex],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: Icon(Icons.person, size: 100, color: Colors.grey[500]),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: Icon(Icons.person, size: 100, color: Colors.grey[500]),
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
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: idx == _currentImageIndex ? Colors.white : Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
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
                              height: 320,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x005B3CF0),
                                    Color(0x55240B62),
                                    Color(0xCC130843),
                                    Color(0xF207021F),
                                  ],
                                  stops: [0.0, 0.42, 0.74, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Name and location overlay
                          Positioned(
                            bottom: 18,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    final userId = widget.userData['id']?.toString() ?? '';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VisitProfileScreen(
                                          api: widget.api,
                                          tokens: widget.tokens,
                                          userId: userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    '${widget.name}${age != null ? ', $age' : ''}',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                      shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                                    ),
                                  ),
                                ),
                                if ((widget.city ?? '').isNotEmpty || (widget.country ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      [widget.city, widget.country]
                                          .where((e) => e != null && e.isNotEmpty)
                                          .join(', ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.isBand
                                            ? const Color(0xFF5B3CF0)
                                            : const Color(0xFF8C6BF7),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        widget.isBand ? 'BAND' : 'ARTIST',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (widget.showPrimaryActions) ...[
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _RoundActionButton(
                                        icon: Icons.close,
                                        backgroundColor: const Color(0xFFB388FF),
                                        iconColor: Colors.white,
                                        onTap: widget.onPrimaryDislike ?? () {},
                                      ),
                                      const SizedBox(width: 18),
                                      _RoundActionButton(
                                        icon: Icons.tune,
                                        backgroundColor: Colors.white,
                                        iconColor: const Color(0xFF5B3CF0),
                                        onTap: widget.onPrimaryFilter ?? () {},
                                        isElevated: true,
                                      ),
                                      const SizedBox(width: 18),
                                      _RoundActionButton(
                                        icon: Icons.favorite,
                                        backgroundColor: Colors.white,
                                        iconColor: Colors.pinkAccent,
                                        onTap: widget.onPrimaryLike ?? () {},
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ABOUT',
                                style: TextStyle(
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF5B3CF0),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.description,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF1F1F1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Tag sections styled per mock
                      if (groupedTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: groupedTags.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.9,
                                        color: Color(0xFF6A4DBE),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 10,
                                      children: entry.value.map((tagName) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5EEFF),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Text(
                                          tagName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5B3CF0),
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // Gender section (under tags)
                      if (widget.gender != null && widget.gender!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gender',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.gender!,
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      // Band members section
                      if (bandMembers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Band Members',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              ...bandMembers.map((member) {
                                final name = member['name']?.toString() ?? '';
                                final age = member['age']?.toString() ?? '';
                                final role = member['bandRole']?.toString() ?? member['bandRoleName']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.purple[100],
                                        child: Icon(Icons.person, color: Colors.purple[700], size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$name${age.isNotEmpty ? ', $age' : ''}',
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            if (role.isNotEmpty)
                                              Text(
                                                role,
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                      const SizedBox(height: 24), // Small padding; allow card to reach bottom behind nav
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
                                ? Colors.green.withOpacity(0.10 * likeOpacity + 0.05)
                                : nopeOpacity > 0
                                    ? Colors.redAccent.withOpacity(0.10 * nopeOpacity + 0.05)
                                    : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    // Large LIKE stamp
                    Positioned(
                      top: 28,
                      right: 24,
                      child: Opacity(
                        opacity: likeOpacity,
                        child: Transform.rotate(
                          angle: 0.18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border.all(color: Colors.green, width: 4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,4))],
                            ),
                            child: const Text('LIKE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                )),
                          ),
                        ),
                      ),
                    ),
                    // Large NOPE stamp
                    Positioned(
                      top: 28,
                      left: 24,
                      child: Opacity(
                        opacity: nopeOpacity,
                        child: Transform.rotate(
                          angle: -0.18,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              border: Border.all(color: Colors.redAccent, width: 4),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,4))],
                            ),
                            child: const Text('NOPE',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                )),
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
