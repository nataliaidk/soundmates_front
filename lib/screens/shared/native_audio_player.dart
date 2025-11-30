import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../theme/app_design_system.dart';

/// Generic audio track interface for the native audio player
class AudioTrack {
  final String title;
  final String fileUrl;

  const AudioTrack({required this.title, required this.fileUrl});
}

/// Native Audio Player with just_audio integration
///
/// A reusable audio player widget that supports:
/// - Multiple tracks with navigation
/// - Play/pause controls
/// - Progress bar with time display
/// - Loading and error states
/// - Customizable accent color
class NativeAudioPlayer extends StatefulWidget {
  final List<AudioTrack> tracks;
  final Color accentColor;

  const NativeAudioPlayer({
    super.key,
    required this.tracks,
    required this.accentColor,
  });

  @override
  State<NativeAudioPlayer> createState() => _NativeAudioPlayerState();
}

class _NativeAudioPlayerState extends State<NativeAudioPlayer> {
  late AudioPlayer _player;
  int _currentTrackIndex = 0;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _player = AudioPlayer();
    await _loadTrack(_currentTrackIndex);
  }

  Future<void> _loadTrack(int index) async {
    if (index < 0 || index >= widget.tracks.length) return;

    try {
      await _player.setUrl(widget.tracks[index].fileUrl);
      if (mounted) {
        setState(() {
          _currentTrackIndex = index;
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading audio: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _playNext() {
    if (_currentTrackIndex < widget.tracks.length - 1) {
      _loadTrack(_currentTrackIndex + 1);
    }
  }

  void _playPrevious() {
    if (_currentTrackIndex > 0) {
      _loadTrack(_currentTrackIndex - 1);
    }
  }

  @override
  void dispose() {
    _player.dispose();
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
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    final currentTrack = widget.tracks[_currentTrackIndex];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getAdaptiveGrey(
            context,
            lightShade: 200,
            darkShade: 800,
          ),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(
              isDark ? 0.3 : 0.05,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track Title
          Text(
            currentTrack.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textWhite : const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _player.duration ?? Duration.zero;
              final progress = duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0;

              return Column(
                children: [
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.getAdaptiveGrey(
                        context,
                        lightShade: 200,
                        darkShade: 800,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.accentColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Time labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          color: AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 600,
                            darkShade: 400,
                          ),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          color: AppTheme.getAdaptiveGrey(
                            context,
                            lightShade: 600,
                            darkShade: 400,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Control Buttons
          StreamBuilder<PlayerState>(
            stream: _player.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              final processingState = playerState?.processingState;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Button
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: _currentTrackIndex > 0
                          ? AppTheme.getAdaptiveText(context)
                          : AppTheme.getAdaptiveGrey(
                              context,
                              lightShade: 400,
                              darkShade: 600,
                            ),
                      size: 32,
                    ),
                    onPressed: _currentTrackIndex > 0 ? _playPrevious : null,
                  ),
                  const SizedBox(width: 20),

                  // Play/Pause Button
                  GestureDetector(
                    onTap: () {
                      if (isPlaying) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child:
                          processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
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
                  const SizedBox(width: 20),

                  // Next Button
                  IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: _currentTrackIndex < widget.tracks.length - 1
                          ? AppTheme.getAdaptiveText(context)
                          : AppTheme.getAdaptiveGrey(
                              context,
                              lightShade: 400,
                              darkShade: 600,
                            ),
                      size: 32,
                    ),
                    onPressed: _currentTrackIndex < widget.tracks.length - 1
                        ? _playNext
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getAdaptiveGrey(
            context,
            lightShade: 200,
            darkShade: 800,
          ),
          width: 1,
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: widget.accentColor),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getAdaptiveGrey(
            context,
            lightShade: 200,
            darkShade: 800,
          ),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load audio',
            style: TextStyle(
              color: AppTheme.getAdaptiveGrey(
                context,
                lightShade: 700,
                darkShade: 300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
