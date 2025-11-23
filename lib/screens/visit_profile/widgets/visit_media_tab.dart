import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../visit_profile_model.dart';
import '../../shared/media_models.dart';
import '../../shared/instagram_post_viewer.dart';

class VisitMediaTab extends StatelessWidget {
  final List<VisitProfileMediaItem> items;

  const VisitMediaTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No media shared yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _MediaGridItem(
          item: items[index],
          onTap: () {
            // Convert VisitProfileMediaItem to MediaItem
            final mediaItems = items.map((item) {
              MediaType type;
              switch (item.type) {
                case VisitProfileMediaType.image:
                  type = MediaType.image;
                  break;
                case VisitProfileMediaType.audio:
                  type = MediaType.audio;
                  break;
                case VisitProfileMediaType.video:
                  type = MediaType.video;
                  break;
              }
              return MediaItem(
                type: type,
                url: item.url,
                fileName: item.fileName,
              );
            }).toList();

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
          },
        );
      },
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final VisitProfileMediaItem item;
  final VoidCallback onTap;

  const _MediaGridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Layer
              if (item.type == VisitProfileMediaType.image)
                Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              else if (item.type == VisitProfileMediaType.video)
                _VideoThumbnail(videoUrl: item.url)
              else
                // Audio placeholder with gradient and music notes
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withOpacity(0.7),
                        accentColor.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background music notes pattern
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withOpacity(0.3),
                          size: 24,
                        ),
                      ),
                      // Center large music note
                      Center(
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ],
                  ),
                ),

              // Play Icon Overlay for video/audio
              if (item.type != VisitProfileMediaType.image)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
