import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../api/api_client.dart';
import '../../api/models.dart';
import 'profile_band_member_dialog.dart';
import '../shared/media_models.dart';
import '../shared/instagram_post_viewer.dart';

/// Profile view with two tabs: Your Info and Multimedia
class ProfileViewTabs extends StatefulWidget {
  final String name;
  final String description;
  final String city;
  final String country;
  final DateTime? birthDate;
  final Map<String, List<String>> tagGroups;
  final List<BandMemberDto> bandMembers;
  final List<BandRoleDto> bandRoles;
  final List<ProfilePictureDto> profilePictures;
  final List<MusicSampleDto> musicSamples;
  final ApiClient api;
  final bool isBand;
  final VoidCallback onEditProfile;
  final VoidCallback? onAddMedia;
  final VoidCallback? onManageMedia;
  final bool startInEditMode;

  const ProfileViewTabs({
    super.key,
    required this.name,
    required this.description,
    required this.city,
    required this.country,
    required this.birthDate,
    required this.tagGroups,
    required this.bandMembers,
    required this.bandRoles,
    required this.profilePictures,
    required this.musicSamples,
    required this.api,
    required this.isBand,
    required this.onEditProfile,
    this.onAddMedia,
    this.onManageMedia,
    required this.startInEditMode,
  });

  @override
  State<ProfileViewTabs> createState() => _ProfileViewTabsState();
}

class _ProfileViewTabsState extends State<ProfileViewTabs> {
  int _selectedTab = 0;

  String _bandRoleName(String bandRoleId) {
    for (final r in widget.bandRoles) {
      if (r.id == bandRoleId) return r.name;
    }
    return bandRoleId;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Profile Header - Horizontal Layout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Profile Picture (use first uploaded photo if available)
                Builder(
                  builder: (context) {
                    final String? avatarUrl = widget.profilePictures.isNotEmpty
                        ? widget.profilePictures.first.getAbsoluteUrl(
                            widget.api.baseUrl,
                          )
                        : null;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.shade400,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.deepPurple.shade50,
                        backgroundImage: avatarUrl != null
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey[600],
                              )
                            : null,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 20),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        widget.name.isEmpty ? 'Your Name' : widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      if (widget.city.isNotEmpty || widget.country.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [
                                  if (widget.city.isNotEmpty) widget.city,
                                  if (widget.country.isNotEmpty) widget.country,
                                ].join(', '),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Birth Date (for artists)
                      if (widget.birthDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.birthDate!
                              .toIso8601String()
                              .split('T')
                              .first
                              .replaceAll('-', '/'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.deepPurple.shade400
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Your Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.deepPurple.shade400
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Multimedia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedTab == 0
                  ? _buildYourInfoTab()
                  : _buildMultimediaTab(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildYourInfoTab() {
    // Get all categories with tags and sort alphabetically
    final allCategories =
        widget.tagGroups.keys
            .where((cat) => widget.tagGroups[cat]!.isNotEmpty)
            .toList()
          ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Section
        if (widget.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

        // Tags Section with Edit functionality
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Edit button aligned to the right
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onEditProfile,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              if (widget.tagGroups.isEmpty)
                Text(
                  'No tags added yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                )
              else
                for (final category in allCategories)
                  if (widget.tagGroups[category]!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.tagGroups[category]!
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

              // Band Members Section
              if (widget.isBand && widget.bandMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'BAND MEMBERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...widget.bandMembers.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            getIconForRoleName(_bandRoleName(m.bandRoleId)),
                            color: Colors.deepPurple.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${_bandRoleName(m.bandRoleId)} • ${m.age} y/o',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultimediaTab() {
    // Combine all media into one list for grid display
    final List<_MediaItem> allMedia = [];

    // Add photos
    for (final pic in widget.profilePictures) {
      allMedia.add(
        _MediaItem(
          type: _MediaType.image,
          url: pic.getAbsoluteUrl(widget.api.baseUrl),
          fileName: pic.fileUrl.split('/').last,
        ),
      );
    }

    // Add music samples (audio/video)
    for (final sample in widget.musicSamples) {
      final fileName = sample.fileUrl.split('/').last;
      final isAudio = fileName.toLowerCase().endsWith('.mp3');
      allMedia.add(
        _MediaItem(
          type: isAudio ? _MediaType.audio : _MediaType.video,
          url: sample.getAbsoluteUrl(widget.api.baseUrl),
          fileName: fileName,
        ),
      );
    }

    return Column(
      children: [
        // All Media Section - Grid with photos, audio, and video
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Photos & Media',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onManageMedia,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Manage'),
                      ),
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: widget.onAddMedia ?? widget.onEditProfile,
                        icon: const Icon(Icons.add_photo_alternate, size: 16),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allMedia.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No media yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: allMedia.length,
                  itemBuilder: (context, index) {
                    final media = allMedia[index];

                    return GestureDetector(
                      onTap: () => _openMedia(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background based on media type
                              if (media.type == _MediaType.image)
                                Image.network(
                                  media.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                )
                              else if (media.type == _MediaType.video)
                                // Show video thumbnail (first frame)
                                _VideoThumbnail(videoUrl: media.url)
                              else
                                // Audio files
                                Container(
                                  color: Colors.deepPurple.shade50,
                                  child: Center(
                                    child: Icon(
                                      Icons.audiotrack,
                                      size: 48,
                                      color: Colors.deepPurple.shade400,
                                    ),
                                  ),
                                ),

                              // Play button overlay for audio/video
                              if (media.type != _MediaType.image)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                  child: const Align(
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Welcome Message - show only for new users (coming from registration)
        if (widget.startInEditMode)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B68EE), Color(0xFF9D7FEE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Soundmates!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: 'Your profile is ready! '),
                      TextSpan(
                        text: 'Start exploring ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'and connect with other musicians who share your passion.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Let's go!"),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openMedia(int index) {
    // Convert all media items to MediaItem format
    final List<MediaItem> mediaItems = [];

    // Add profile pictures
    for (final pic in widget.profilePictures) {
      mediaItems.add(
        MediaItem(
          type: MediaType.image,
          url: pic.getAbsoluteUrl(widget.api.baseUrl),
          fileName: pic.fileUrl.split('/').last,
        ),
      );
    }

    // Add music samples
    for (final sample in widget.musicSamples) {
      final fileName = sample.fileUrl.split('/').last;
      final isAudio = fileName.toLowerCase().endsWith('.mp3');
      mediaItems.add(
        MediaItem(
          type: isAudio ? MediaType.audio : MediaType.video,
          url: sample.getAbsoluteUrl(widget.api.baseUrl),
          fileName: fileName,
        ),
      );
    }

    // Navigate to Instagram-style viewer
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: InstagramPostViewer(
              items: mediaItems,
              initialIndex: index,
              accentColor: Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
}

// Helper classes for media items
enum _MediaType { image, audio, video }

class _MediaItem {
  final _MediaType type;
  final String url;
  final String fileName;

  _MediaItem({required this.type, required this.url, required this.fileName});
}

/// Widget that displays video thumbnail (first frame)
class _VideoThumbnail extends StatefulWidget {
  final String videoUrl;

  const _VideoThumbnail({required this.videoUrl});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();
      // Pause immediately to show first frame
      await _controller!.pause();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading video thumbnail: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.videocam_off, color: Colors.grey, size: 32),
      );
    }

    if (!_initialized || _controller == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.size.width,
        height: _controller!.value.size.height,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
