import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import '../visit_profile_model.dart';

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
            Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: InstagramPostViewer(
                      items: items,
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

/// Instagram-style post viewer (like the mockup)
class InstagramPostViewer extends StatefulWidget {
  final List<VisitProfileMediaItem> items;
  final int initialIndex;
  final Color accentColor;

  const InstagramPostViewer({
    super.key,
    required this.items,
    required this.initialIndex,
    required this.accentColor,
  });

  @override
  State<InstagramPostViewer> createState() => _InstagramPostViewerState();
}

class _InstagramPostViewerState extends State<InstagramPostViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Request focus for keyboard events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _navigateToPage(int delta) {
    final newIndex = (_currentIndex + delta).clamp(0, widget.items.length - 1);
    if (newIndex != _currentIndex) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _navigateToPage(-1); // Previous
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _navigateToPage(1); // Next
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Top Bar (like Instagram)
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    // Progress dots
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.items.length,
                              (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 3,
                            width: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: index == _currentIndex
                                  ? widget.accentColor
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
            ),

            // Media Content (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _MediaPostContent(
                    item: item,
                    accentColor: widget.accentColor,
                    isActive: index == _currentIndex,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual media post content
class _MediaPostContent extends StatefulWidget {
  final VisitProfileMediaItem item;
  final Color accentColor;
  final bool isActive;

  const _MediaPostContent({
    required this.item,
    required this.accentColor,
    required this.isActive,
  });

  @override
  State<_MediaPostContent> createState() => _MediaPostContentState();
}

class _MediaPostContentState extends State<_MediaPostContent> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showPlayButton = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initializeMedia();
    }
  }

  @override
  void didUpdateWidget(_MediaPostContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeMedia();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeMedia();
    }
  }

  Future<void> _initializeMedia() async {
    if (widget.item.type == VisitProfileMediaType.video) {
      await _initializeVideo();
    } else if (widget.item.type == VisitProfileMediaType.audio) {
      await _initializeAudio();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.item.url),
      );
      await _videoController!.initialize();

      // Auto-play the video
      await _videoController!.play();

      // Listen to video state changes
      _videoController!.addListener(() {
        if (mounted && _videoController != null) {
          final isPlaying = _videoController!.value.isPlaying;
          if (_showPlayButton == isPlaying) {
            setState(() {
              _showPlayButton = !isPlaying;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _initializeAudio() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setUrl(widget.item.url);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _disposeMedia() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _videoController = null;
    _audioPlayer = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeMedia();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == VisitProfileMediaType.image) {
      return _buildImageView();
    } else if (widget.item.type == VisitProfileMediaType.video) {
      return _buildVideoView();
    } else {
      return _buildAudioView();
    }
  }

  Widget _buildImageView() {
    return Container(
      color: Colors.white,
      child: PhotoView(
        imageProvider: NetworkImage(widget.item.url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
          );
        },
      ),
    );
  }

  Widget _buildVideoView() {
    if (_hasError) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _videoController == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Transparent tap detector overlay (doesn't block swipes)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (_) {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                    _showPlayButton = true;
                  } else {
                    _videoController!.play();
                    _showPlayButton = false;
                  }
                });
              },
            ),
          ),
          // Play/Pause overlay icon
          if (_showPlayButton)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioView() {
    if (_hasError) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load audio',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _audioPlayer == null) {
      return Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Audio Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.audiotrack,
                  size: 80,
                  color: widget.accentColor,
                ),
              ),
              const SizedBox(height: 48),

              // Progress Bar
              StreamBuilder<Duration>(
                stream: _audioPlayer!.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final duration = _audioPlayer!.duration ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0;

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final newPosition = duration * value;
                            _audioPlayer!.seek(newPosition);
                          },
                          activeColor: widget.accentColor,
                          inactiveColor: Colors.grey.shade300,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Controls
              StreamBuilder<PlayerState>(
                stream: _audioPlayer!.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final isPlaying = playerState?.playing ?? false;
                  final processingState = playerState?.processingState;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.replay_10,
                          color: Colors.black87,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPosition =
                              _audioPlayer!.position -
                                  const Duration(seconds: 10);
                          _audioPlayer!.seek(newPosition);
                        },
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            _audioPlayer!.pause();
                          } else {
                            _audioPlayer!.play();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            shape: BoxShape.circle,
                          ),
                          child:
                          processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering
                              ? const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(
                          Icons.forward_10,
                          color: Colors.black87,
                          size: 32,
                        ),
                        onPressed: () {
                          final newPosition =
                              _audioPlayer!.position +
                                  const Duration(seconds: 10);
                          _audioPlayer!.seek(newPosition);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
