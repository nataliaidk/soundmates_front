import 'dart:convert';
import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for managing existing photos and media files
class ProfileManageMediaScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;

  const ProfileManageMediaScreen({
    super.key,
    required this.api,
    required this.tokens,
  });

  @override
  State<ProfileManageMediaScreen> createState() => _ProfileManageMediaScreenState();
}

class _ProfileManageMediaScreenState extends State<ProfileManageMediaScreen> {
  List<ProfilePictureDto> _profilePictures = [];
  List<MusicSampleDto> _musicSamples = [];
  String _status = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    setState(() {
      _loading = true;
      _status = 'Loading...';
    });

    try {
      // Load profile data which contains pictures and samples
      final profileResp = await widget.api.getMyProfile();
      if (profileResp.statusCode == 200 && profileResp.body.isNotEmpty) {
        final decoded = jsonDecode(profileResp.body);
        final profile = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
        
        // Load profile pictures from profile
        if (profile['profilePictures'] is List) {
          _profilePictures = (profile['profilePictures'] as List)
              .map((pic) => ProfilePictureDto.fromJson(Map<String, dynamic>.from(pic)))
              .toList();
        }
        
        // Load music samples from profile
        if (profile['musicSamples'] is List) {
          _musicSamples = (profile['musicSamples'] as List)
              .map((sample) => MusicSampleDto.fromJson(Map<String, dynamic>.from(sample)))
              .toList();
        }
      }

      setState(() {
        _loading = false;
        _status = '';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error loading media: $e';
      });
    }
  }

  Future<void> _deleteProfilePicture(String pictureId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final resp = await widget.api.deleteProfilePicture(pictureId);
      if (resp.statusCode == 200) {
        setState(() {
          _profilePictures.removeWhere((p) => p.id == pictureId);
          _status = 'Photo deleted';
        });
      } else {
        setState(() => _status = 'Failed to delete photo: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _deleteMusicSample(String sampleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final resp = await widget.api.deleteMusicSample(sampleId);
      if (resp.statusCode == 200) {
        setState(() {
          _musicSamples.removeWhere((s) => s.id == sampleId);
          _status = 'Media deleted';
        });
      } else {
        setState(() => _status = 'Failed to delete media: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _moveProfilePictureUp(String pictureId) async {
    final index = _profilePictures.indexWhere((p) => p.id == pictureId);
    if (index <= 0) return;

    setState(() {
      final temp = _profilePictures[index];
      _profilePictures[index] = _profilePictures[index - 1];
      _profilePictures[index - 1] = temp;
    });

    await _updateMediaOrder();
  }

  Future<void> _moveProfilePictureDown(String pictureId) async {
    final index = _profilePictures.indexWhere((p) => p.id == pictureId);
    if (index < 0 || index >= _profilePictures.length - 1) return;

    setState(() {
      final temp = _profilePictures[index];
      _profilePictures[index] = _profilePictures[index + 1];
      _profilePictures[index + 1] = temp;
    });

    await _updateMediaOrder();
  }

  Future<void> _moveMusicSampleUp(String sampleId) async {
    final index = _musicSamples.indexWhere((s) => s.id == sampleId);
    if (index <= 0) return;

    setState(() {
      final temp = _musicSamples[index];
      _musicSamples[index] = _musicSamples[index - 1];
      _musicSamples[index - 1] = temp;
    });

    await _updateMediaOrder();
  }

  Future<void> _moveMusicSampleDown(String sampleId) async {
    final index = _musicSamples.indexWhere((s) => s.id == sampleId);
    if (index < 0 || index >= _musicSamples.length - 1) return;

    setState(() {
      final temp = _musicSamples[index];
      _musicSamples[index] = _musicSamples[index + 1];
      _musicSamples[index + 1] = temp;
    });

    await _updateMediaOrder();
  }

  Future<void> _updateMediaOrder() async {
    try {
      // Get current profile to extract required fields
      final profileResp = await widget.api.getMyProfile();
      if (profileResp.statusCode != 200) {
        setState(() => _status = 'Failed to load profile');
        return;
      }

      final decoded = jsonDecode(profileResp.body);
      final profile = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
      
      final picturesOrder = _profilePictures.map((p) => p.id).toList();
      final samplesOrder = _musicSamples.map((s) => s.id).toList();

      // Determine if artist or band
      final isBand = profile['isBand'] == true;

      if (isBand) {
        // Band profile
        final bandMembers = profile['bandMembers'] is List
            ? (profile['bandMembers'] as List)
                .map((m) => BandMemberDto.fromJson(Map<String, dynamic>.from(m)))
                .toList()
            : <BandMemberDto>[];

        final dto = UpdateBandProfile(
          isBand: true,
          name: profile['name'] ?? '',
          description: profile['description'] ?? '',
          countryId: profile['countryId']?.toString(),
          cityId: profile['cityId']?.toString(),
          tagsIds: profile['tagsIds'] is List
              ? (profile['tagsIds'] as List).map((t) => t.toString()).toList()
              : [],
          bandMembers: bandMembers,
          musicSamplesOrder: samplesOrder,
          profilePicturesOrder: picturesOrder,
        );
        final resp = await widget.api.updateBandProfile(dto);
        if (resp.statusCode == 200) {
          setState(() => _status = 'Order updated');
        } else {
          setState(() => _status = 'Failed to update order: ${resp.statusCode}');
        }
      } else {
        // Artist profile
        final dto = UpdateArtistProfile(
          isBand: false,
          name: profile['name'] ?? '',
          description: profile['description'] ?? '',
          countryId: profile['countryId']?.toString(),
          cityId: profile['cityId']?.toString(),
          birthDate: profile['birthDate'] != null
              ? DateTime.tryParse(profile['birthDate'].toString())
              : null,
          genderId: profile['genderId']?.toString(),
          tagsIds: profile['tagsIds'] is List
              ? (profile['tagsIds'] as List).map((t) => t.toString()).toList()
              : [],
          musicSamplesOrder: samplesOrder,
          profilePicturesOrder: picturesOrder,
        );
        final resp = await widget.api.updateArtistProfile(dto);
        if (resp.statusCode == 200) {
          setState(() => _status = 'Order updated');
        } else {
          setState(() => _status = 'Failed to update order: ${resp.statusCode}');
        }
      }
    } catch (e) {
      setState(() => _status = 'Error updating order: $e');
    }
  }

  void _openMedia(String url, String fileName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      fileName,
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
            // Content
            if (fileName.toLowerCase().endsWith('.jpg') || 
                fileName.toLowerCase().endsWith('.jpeg'))
              InteractiveViewer(
                child: Image.network(
                  url,
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
                      fileName.toLowerCase().endsWith('.mp3') ? Icons.audiotrack : Icons.videocam,
                      size: 80,
                      color: fileName.toLowerCase().endsWith('.mp3') 
                          ? Colors.purple[300] 
                          : Colors.blue[300],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(url);
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening file: $e'),
                                backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    // Combine all media into one list for grid display
    final List<_MediaItem> allMedia = [];
    
    // Add photos
    for (final pic in _profilePictures) {
      allMedia.add(_MediaItem(
        type: _MediaType.image,
        url: pic.getAbsoluteUrl(widget.api.baseUrl),
        fileName: pic.fileUrl.split('/').last,
        id: pic.id,
      ));
    }
    
    // Add music samples (audio/video)
    for (final sample in _musicSamples) {
      final fileName = sample.fileUrl.split('/').last;
      final isAudio = fileName.toLowerCase().endsWith('.mp3');
      allMedia.add(_MediaItem(
        type: isAudio ? _MediaType.audio : _MediaType.video,
        url: sample.getAbsoluteUrl(widget.api.baseUrl),
        fileName: fileName,
        id: sample.id,
      ));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Media'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap arrows to reorder, tap delete to remove media',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // All Media Grid
                  const Text(
                    'Photos & Media',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  if (allMedia.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No media added yet',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                        final isImage = media.type == _MediaType.image;
                        
                        return Stack(
                          children: [
                            // Media preview
                            GestureDetector(
                              onTap: () => _openMedia(media.url, media.fileName),
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
                                      if (isImage)
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
                                      if (!isImage)
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
                            ),
                            
                            // Control buttons overlay
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Delete button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                      onPressed: () {
                                        if (isImage) {
                                          _deleteProfilePicture(media.id);
                                        } else {
                                          _deleteMusicSample(media.id);
                                        }
                                      },
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Delete',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Move buttons overlay
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Move left/up button
                                  if (index > 0)
                                    Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_back, size: 16),
                                        onPressed: () {
                                          if (isImage) {
                                            _moveProfilePictureUp(media.id);
                                          } else {
                                            _moveMusicSampleUp(media.id);
                                          }
                                        },
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Move left',
                                      ),
                                    ),
                                  // Move right/down button
                                  if (index < allMedia.length - 1)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.arrow_forward, size: 16),
                                        onPressed: () {
                                          if (isImage) {
                                            _moveProfilePictureDown(media.id);
                                          } else {
                                            _moveMusicSampleDown(media.id);
                                          }
                                        },
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Move right',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            // Position indicator
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // Status Message
                  if (_status.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _status.contains('deleted') || _status.contains('Order updated')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('deleted') || _status.contains('Order updated')
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
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
  final String id;

  _MediaItem({
    required this.type,
    required this.url,
    required this.fileName,
    required this.id,
  });
}
