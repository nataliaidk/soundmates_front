import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'media_models.dart';
import '../../theme/app_design_system.dart';

/// Instagram-style post viewer for media items
class InstagramPostViewer extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  final Color accentColor = AppColors.accentPurpleBlue;

  const InstagramPostViewer({
    super.key,
    required this.items,
    required this.initialIndex,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        backgroundColor: isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceWhite,
        body: Column(
          children: [
            // Top Bar (like Instagram)
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textBlack87,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: FractionallySizedBox(
                        widthFactor: 0.6,
                        child: Row(
                          children: List.generate(
                            widget.items.length,
                            (index) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: index == _currentIndex
                                      ? widget.accentColor
                                      : (isDark
                                            ? AppColors.surfaceDarkGrey
                                            : AppColors.borderLight),
                                ),
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
  final MediaItem item;
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
    if (widget.item.type == MediaType.video) {
      await _initializeVideo();
    } else if (widget.item.type == MediaType.audio) {
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
    if (widget.item.type == MediaType.image) {
      return _buildImageView();
    } else if (widget.item.type == MediaType.video) {
      return _buildVideoView();
    } else {
      return _buildAudioView();
    }
  }

  Widget _buildImageView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: PhotoView(
        imageProvider: NetworkImage(widget.item.url),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        initialScale: PhotoViewComputedScale.contained,
        backgroundDecoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
        ),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              color: AppColors.textGrey,
              size: 64,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_hasError) {
      return Container(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load video',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textBlack87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _videoController == null) {
      return Container(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.textGrey),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_hasError) {
      return Container(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Failed to load audio',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textBlack87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _audioPlayer == null) {
      return Container(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.textGrey),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.surfaceDark : Colors.white,
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
                          inactiveColor: AppColors.borderLight,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textWhite70
                                    : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textWhite70
                                    : Colors.black54,
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
                        icon: Icon(
                          Icons.replay_10,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textBlack87,
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
                        icon: Icon(
                          Icons.forward_10,
                          color: isDark
                              ? AppColors.textWhite
                              : AppColors.textBlack87,
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
