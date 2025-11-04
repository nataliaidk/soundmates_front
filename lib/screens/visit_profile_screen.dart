import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import 'dart:convert';

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

class _VisitProfileScreenState extends State<VisitProfileScreen> with SingleTickerProviderStateMixin {
  OtherUserProfileDto? _profile;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  final Map<String, List<TagDto>> _tagGroups = {};
  final Map<String, String> _categoryIdToName = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
    _loadTagData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            if (tag.tagCategoryId != null && _tagGroups.containsKey(tag.tagCategoryId)) {
              _tagGroups[tag.tagCategoryId]!.add(tag);
            }
          }
        });
      }
    } catch (e) {
      print('Error loading tag data: $e');
    }
  }

  Map<String, List<String>> _groupProfileTags() {
    if (_profile == null) return {};

    final Map<String, List<String>> grouped = {};

    for (final tagId in _profile!.tags) {
      String? categoryId;
      String? tagName;

      for (final entry in _tagGroups.entries) {
        final tag = entry.value.firstWhere(
              (t) => t.id == tagId,
          orElse: () => TagDto(id: '', name: ''),
        );
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
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple.shade400,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Profile not found', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    final profilePicUrl = _profile!.profilePictures.isNotEmpty
        ? _profile!.profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Hero section with image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (profilePicUrl != null)
                    Image.network(
                      profilePicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.person, size: 80, color: Colors.grey.shade400),
                      ),
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.person, size: 80, color: Colors.grey.shade400),
                    ),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Profile info overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _profile!.name ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_profile is OtherUserProfileArtistDto)
                              Text(
                                '${(_profile as OtherUserProfileArtistDto).age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _profile!.isBand
                                    ? Colors.deepPurple.shade400
                                    : Colors.blue.shade400,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _profile!.isBand ? 'BAND' : 'ARTIST',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (_profile is OtherUserProfileArtistDto &&
                                (_profile as OtherUserProfileArtistDto).gender != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                (_profile as OtherUserProfileArtistDto).gender!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (_profile!.city != null || _profile!.country != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.white.withOpacity(0.9)),
                              const SizedBox(width: 4),
                              Text(
                                [_profile!.city, _profile!.country]
                                    .where((e) => e != null)
                                    .join(', '),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: Colors.deepPurple.shade400,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(text: 'Information'),
                  Tab(text: 'Multimedia'),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
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
    );
  }

  Widget _buildInformationTab() {
    final tagGroups = _groupProfileTags();
    final orderedCategories = ['Instruments', 'Genres', 'Activity', 'Collaboration type'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About section
          _buildSectionTitle('About'),
          const SizedBox(height: 12),
          Text(
            _profile!.description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 32),

          // Tags sections
          for (final category in orderedCategories)
            if (tagGroups.containsKey(category) && tagGroups[category]!.isNotEmpty) ...[
              _buildTagSection(category, tagGroups[category]!),
              const SizedBox(height: 24),
            ],

          // Band members (if band)
          if (_profile is OtherUserProfileBandDto) ...[
            _buildSectionTitle('Band Members'),
            const SizedBox(height: 12),
            ...(_profile as OtherUserProfileBandDto).bandMembers.map((member) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.deepPurple.shade400,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Age ${member.age}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ),
            const SizedBox(height: 32),
          ],

          // Gender (if artist)
          if (_profile is OtherUserProfileArtistDto &&
              (_profile as OtherUserProfileArtistDto).gender != null) ...[
            _buildSectionTitle('Gender'),
            const SizedBox(height: 12),
            Text(
              (_profile as OtherUserProfileArtistDto).gender!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMultimediaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_profile!.profilePictures.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _profile!.profilePictures.length,
              itemBuilder: (context, index) {
                final pic = _profile!.profilePictures[index];
                final url = pic.getAbsoluteUrl(widget.api.baseUrl);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image, color: Colors.grey.shade400),
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 36,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No media available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
