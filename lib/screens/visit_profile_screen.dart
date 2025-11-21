import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui'; // Required for ImageFilter (Blur)
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../widgets/app_bottom_nav.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

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
  OtherUserProfileDto? _profile;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  final Map<String, List<TagDto>> _tagGroups = {};
  final Map<String, String> _categoryIdToName = {};
  final Map<String, String> _countryIdToName = {};
  final Map<String, String> _cityIdToName = {};

  // Premium Color Palette
  final Color _primaryDark = const Color(0xFF1A1A1A);
  final Color _accentPurple = const Color(0xFF7B51D3);
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _softBg = const Color(0xFFF8F9FC);
  final Color _surfaceWhite = Colors.white;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadTagData();
  }

  // ... [Keep your existing _loadLocationData, _loadTagData, _groupProfileTags, _loadProfile methods exactly as they were] ...
  Future<void> _loadLocationData() async {
    try {
      final countriesResp = await widget.api.getCountries();
      if (countriesResp.statusCode == 200) {
        final decoded = jsonDecode(countriesResp.body);
        final list = decoded is List ? decoded : [];
        for (final c in list) {
          final country = CountryDto.fromJson(c);
          _countryIdToName[country.id] = country.name;
        }
      }
      if (_profile?.country != null) {
        final citiesResp = await widget.api.getCities(_profile!.country!);
        if (citiesResp.statusCode == 200) {
          final decoded = jsonDecode(citiesResp.body);
          final list = decoded is List ? decoded : [];
          for (final c in list) {
            final city = CityDto.fromJson(c);
            _cityIdToName[city.id] = city.name;
          }
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      /* Handle error silently */
    }
  }

  Future<void> _loadTagData() async {
    try {
      final tagsResp = await widget.api.getTags();
      final categoriesResp = await widget.api.getTagCategories();
      if (tagsResp.statusCode == 200 && categoriesResp.statusCode == 200) {
        final tagsList = (jsonDecode(tagsResp.body) as List)
            .map((e) => TagDto.fromJson(e))
            .toList();
        final categoriesList = (jsonDecode(categoriesResp.body) as List)
            .map((e) => TagCategoryDto.fromJson(e))
            .toList();
        setState(() {
          for (final cat in categoriesList) {
            _categoryIdToName[cat.id] = cat.name;
            _tagGroups[cat.id] = [];
          }
          for (final tag in tagsList) {
            if (tag.tagCategoryId != null &&
                _tagGroups.containsKey(tag.tagCategoryId)) {
              _tagGroups[tag.tagCategoryId]!.add(tag);
            }
          }
        });
      }
    } catch (e) {
      /* Handle error silently */
    }
  }

  Map<String, List<String>> _groupProfileTags() {
    if (_profile == null) return {};
    final Map<String, List<String>> grouped = {};
    for (final tagId in _profile!.tags) {
      String? categoryId;
      String? tagName;
      for (final entry in _tagGroups.entries) {
        final tag = entry.value.firstWhere((t) => t.id == tagId,
            orElse: () => TagDto(id: '', name: ''));
        if (tag.id.isNotEmpty) {
          categoryId = entry.key;
          tagName = tag.name;
          break;
        }
      }
      if (categoryId != null && tagName != null) {
        final categoryName = _categoryIdToName[categoryId] ?? 'Other';
        grouped.putIfAbsent(categoryName, () => []);
        grouped[categoryName]!.add(tagName);
      }
    }
    return grouped;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.getOtherUserProfile(widget.userId);
      if (profile != null) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
        await _loadLocationData();
      } else {
        setState(() {
          _error = 'Failed to load profile';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: _softBg,
        body: Center(child: CircularProgressIndicator(color: _accentPurple)),
      );
    }

    if (_error != null || _profile == null) {
      return Scaffold(
        backgroundColor: _softBg,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(child: Text(_error ?? 'Profile not found')),
      );
    }

    final profilePicUrl = _profile!.profilePictures.isNotEmpty
        ? _profile!.profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
        : null;

    final locationString = [
      if (_profile!.city != null && _cityIdToName[_profile!.city] != null)
        _cityIdToName[_profile!.city],
      if (_profile!.country != null &&
          _countryIdToName[_profile!.country] != null)
        _countryIdToName[_profile!.country],
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: _surfaceWhite,
      body: Stack(
        children: [
          // Main Scroll View
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // 1. Premium Image Header
                SliverAppBar(
                  expandedHeight: 500, // Increased height slightly
                  pinned: true,
                  backgroundColor: _primaryDark,
                  elevation: 0,
                  leading: const SizedBox(), // Hidden, custom back button used
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image with Hero-like feel
                        if (profilePicUrl != null)
                          Image.network(
                            profilePicUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[800]),
                          )
                        else
                          Container(color: Colors.grey[800]),

                        // Cinematic Gradient Overlay (Stronger at bottom for text contrast)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.7),
                                Colors.black.withOpacity(0.95),
                              ],
                              stops: const [0.0, 0.4, 0.75, 1.0],
                            ),
                          ),
                        ),

                        // Header Content (Name, Age, Location)
                        Positioned(
                          left: 20,
                          // Right padding added so text doesn't go under buttons
                          right: 130,
                          bottom: 30, // Raised slightly
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Match Badge
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _accentPurple,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                        color: _accentPurple.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2))
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 6),
                                    Text("Matched",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11)),
                                  ],
                                ),
                              ),

                              // Name & Age
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _profile!.name ?? 'Unknown',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                        height: 1.2
                                    ),
                                  ),
                                  if (_profile is OtherUserProfileArtistDto) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(_profile as OtherUserProfileArtistDto).calculatedAge ?? ''}',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 32,
                                          fontWeight: FontWeight.w300,
                                          height: 1.2
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.black, width: 1.5),
                                    ),
                                  )
                                ],
                              ),

                              // Location
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      locationString.isEmpty
                                          ? 'Unknown Location'
                                          : locationString,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // >>> ACTION BUTTONS OVERLAY <<<
                        Positioned(
                          bottom: 30,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Unmatch Button (Small, Red)
                              _buildOverlayButton(
                                  text: "Unmatch",
                                  icon: Icons.close,
                                  color: _accentRed,
                                  isPrimary: false
                              ),
                              const SizedBox(height: 12),
                              // Message Button (Large, Purple)
                              _buildOverlayButton(
                                  text: "Message",
                                  icon: Icons.chat_bubble_outline,
                                  color: _accentPurple,
                                  isPrimary: true
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: Container(
              decoration: BoxDecoration(
                color: _surfaceWhite,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              // Slightly negative margin to pull it up over the image
              margin: const EdgeInsets.only(top: 0),
              child: Column(
                children: [
                  // 2. Sticky Tab Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    decoration: BoxDecoration(
                      color: _surfaceWhite,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      children: [
                        // Tabs
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
                                fontWeight: FontWeight.w700, fontSize: 13),
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(19),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2))
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

                  // 3. Scrollable Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInformationTab(),
                        _buildMultimediaTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Header Controls (Glassmorphism)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _buildGlassButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: Colors.black.withOpacity(0.2),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.near_me, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text("2.5 km",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Keep Bottom Nav at bottom
          const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(current: BottomNavItem.home)),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  // New widget for buttons overlaying the image
  Widget _buildOverlayButton({required String text, required IconData icon, required Color color, required bool isPrimary}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isPrimary ? 20 : 16, vertical: isPrimary ? 12 : 10),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isPrimary ? 20 : 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isPrimary ? 14 : 13)),
        ],
      ),
    );
  }


  Widget _buildGlassButton(
      {required IconData icon, required VoidCallback onTap}) {
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

  Widget _buildInformationTab() {
    final tagGroups = _groupProfileTags();
    final orderedCategories = [
      'Instruments',
      'Genres',
      'Activity',
      'Collaboration type'
    ];

    // Determine Audio Data
    String? musicTitle = "No Track Selected";
    String? musicArtist = _profile!.name;
    String? musicCover = _profile!.profilePictures.isNotEmpty
        ? _profile!.profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
        : null;

    if (_profile!.musicSamples != null && _profile!.musicSamples!.isNotEmpty) {
      musicTitle = _profile!.musicSamples!.first.fileUrl.split('/').last;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        const SizedBox(height: 10),
        _buildSectionTitle('About'),
        const SizedBox(height: 8),
        Text(
          _profile!.description.isNotEmpty
              ? _profile!.description
              : "Looking for someone to jam with occasionally and for some touring opportunity!",
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[800],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),
        for (final category in orderedCategories)
          if (tagGroups.containsKey(category) &&
              tagGroups[category]!.isNotEmpty) ...[
            _buildSectionTitle(category),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tagGroups[category]!
                  .map((tag) => _buildModernChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

        // Music Player
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2A2D3E), const Color(0xFF1F2029)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3), blurRadius: 8)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: musicCover != null
                          ? Image.network(musicCover,
                          width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                          width: 56,
                          height: 56,
                          color: Colors.white10,
                          child: const Icon(Icons.music_note,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          musicTitle ?? "Audio Track",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          musicArtist ?? "Artist",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fake progress bar
              Stack(
                children: [
                  Container(height: 4, color: Colors.white12),
                  Container(height: 4, width: 100, color: _accentPurple),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.shuffle, color: Colors.white54, size: 20),
                  const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.black, size: 28),
                  ),
                  const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  const Icon(Icons.repeat, color: Colors.white54, size: 20),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildModernChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFE0E0E0).withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMultimediaTab() {
    final List<_MediaItem> allMedia = [];
    for (final pic in _profile!.profilePictures) {
      allMedia.add(_MediaItem(
          type: _MediaType.image,
          url: pic.getAbsoluteUrl(widget.api.baseUrl),
          fileName: pic.fileUrl.split('/').last));
    }
    if (_profile!.musicSamples != null) {
      for (final sample in _profile!.musicSamples!) {
        final fileName = sample.fileUrl.split('/').last;
        final isAudio = fileName.toLowerCase().endsWith('.mp3');
        allMedia.add(_MediaItem(
            type: isAudio ? _MediaType.audio : _MediaType.video,
            url: sample.getAbsoluteUrl(widget.api.baseUrl),
            fileName: fileName));
      }
    }

    if (allMedia.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No media shared yet',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: allMedia.length,
      itemBuilder: (context, index) {
        final media = allMedia[index];
        return GestureDetector(
          onTap: () => _openMedia(media),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5))
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.type == _MediaType.image)
                    Image.network(
                      media.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey)),
                    )
                  else
                    Container(
                      color: const Color(0xFFF0F2F5),
                      child: Icon(
                        media.type == _MediaType.audio
                            ? Icons.audiotrack
                            : Icons.videocam,
                        color: _accentPurple,
                        size: 32,
                      ),
                    ),

                  // Overlay Icon
                  if (media.type != _MediaType.image)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black12,
                        child: const Center(
                            child: Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 40)),
                      ),
                    )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openMedia(_MediaItem media) {
    try {
      launchUrl(Uri.parse(media.url), mode: LaunchMode.externalApplication);
    } catch (e) {
      /* ignore */
    }
  }
}

enum _MediaType { image, audio, video }

class _MediaItem {
  final _MediaType type;
  final String url;
  final String fileName;
  _MediaItem({required this.type, required this.url, required this.fileName});
}