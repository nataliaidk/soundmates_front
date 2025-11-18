import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/api_client.dart';
import '../../api/models.dart';
import 'profile_band_member_dialog.dart';

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
          
          // Profile Picture (use first uploaded photo if available)
          Builder(builder: (context) {
            final String? avatarUrl = widget.profilePictures.isNotEmpty
                ? widget.profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
                : null;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                    : null,
              ),
            );
          }),
          const SizedBox(height: 16),
          
          // Name
          Text(
            widget.name.isEmpty ? 'Your Name' : widget.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          
          // Location with icon
          if (widget.city.isNotEmpty || widget.country.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  [
                    if (widget.city.isNotEmpty) widget.city,
                    if (widget.country.isNotEmpty) widget.country,
                  ].join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          const SizedBox(height: 4),
          
          // Birth Date (for artists)
          if (widget.birthDate != null)
            Text(
              widget.birthDate!.toIso8601String().split('T').first.replaceAll('-', '/'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        color: _selectedTab == 0 ? Colors.purple : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Your Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? Colors.white : Colors.black,
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
                        color: _selectedTab == 1 ? Colors.purple : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Multimedia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? Colors.white : Colors.black,
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
              child: _selectedTab == 0 ? _buildYourInfoTab() : _buildMultimediaTab(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildYourInfoTab() {
    const orderedCategories = ['Instruments', 'Genres', 'Activity', 'Collaboration type'];
    
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
                  style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TAGS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onEditProfile,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.tagGroups.isEmpty)
                Text(
                  'No tags added yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                )
              else
                for (final category in orderedCategories)
                  if (widget.tagGroups.containsKey(category) &&
                      widget.tagGroups[category]!.isNotEmpty) ...[
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
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
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
                ...widget.bandMembers.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              getIconForRoleName(_bandRoleName(m.bandRoleId)),
                              color: Colors.purple.shade700,
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
                    )),
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
      allMedia.add(_MediaItem(
        type: _MediaType.image,
        url: pic.getAbsoluteUrl(widget.api.baseUrl),
        fileName: pic.fileUrl.split('/').last,
      ));
    }
    
    // Add music samples (audio/video)
    for (final sample in widget.musicSamples) {
      final fileName = sample.fileUrl.split('/').last;
      final isAudio = fileName.toLowerCase().endsWith('.mp3');
      allMedia.add(_MediaItem(
        type: isAudio ? _MediaType.audio : _MediaType.video,
        url: sample.getAbsoluteUrl(widget.api.baseUrl),
        fileName: fileName,
      ));
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
                  TextButton.icon(
                    onPressed: widget.onAddMedia ?? widget.onEditProfile,
                    icon: const Icon(Icons.add_photo_alternate, size: 16),
                    label: const Text('Add Media'),
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
                        Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
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
                      onTap: () => _openMedia(media),
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
                                      child: Icon(Icons.error, color: Colors.grey[400]),
                                    );
                                  },
                                )
                              else if (media.type == _MediaType.video)
                                // Try to show video thumbnail or fallback to icon
                                Image.network(
                                  media.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.blue[50],
                                      child: const Center(
                                        child: Icon(
                                          Icons.videocam,
                                          size: 48,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else
                                // Audio files
                                Container(
                                  color: Colors.purple[50],
                                  child: const Center(
                                    child: Icon(
                                      Icons.audiotrack,
                                      size: 48,
                                      color: Colors.purple,
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
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    children: [
                      TextSpan(text: 'Your profile is ready! '),
                      TextSpan(
                        text: 'Start exploring ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'and connect with other musicians who share your passion.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  void _openMedia(_MediaItem media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      media.fileName,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Media content
            if (media.type == _MediaType.image)
              InteractiveViewer(
                child: Image.network(
                  media.url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error, color: Colors.white, size: 48),
                            SizedBox(height: 12),
                            Text('Failed to load image', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      media.type == _MediaType.audio ? Icons.audiotrack : Icons.videocam,
                      size: 80,
                      color: media.type == _MediaType.audio ? Colors.purple[300] : Colors.blue[300],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      media.type == _MediaType.audio ? 'Audio File' : 'Video File',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      media.fileName,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(media.url);
                          // Try to launch directly without checking
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          
                          if (!launched && context.mounted) {
                            // If failed, try platformDefault mode
                            final launched2 = await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                            
                            if (!launched2 && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cannot open: ${media.url}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening file: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play / Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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

  _MediaItem({
    required this.type,
    required this.url,
    required this.fileName,
  });
}
