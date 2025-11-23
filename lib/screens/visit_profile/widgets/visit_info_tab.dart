import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../visit_profile_model.dart';
import '../../../theme/app_design_system.dart';

class VisitInfoTab extends StatelessWidget {
  final VisitProfileViewModel data;

  const VisitInfoTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final orderedCategories = [
      'Instruments',
      'Genres',
      'Activity',
      'Collaboration type',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        const SizedBox(height: 10),

        // About Section
        _buildSectionTitle('About'),
        const SizedBox(height: 8),
        Text(
          data.profile.description.isNotEmpty
              ? data.profile.description
              : "Looking for someone to jam with occasionally and for some touring opportunity!",
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[800],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),

        // Native Audio Player
        if (data.audioTracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: NativeAudioPlayer(
              tracks: data.audioTracks,
              accentColor: AppColors.accentPurple,
            ),
          ),

        // Tags Sections
        for (final category in orderedCategories)
          if (data.groupedTags.containsKey(category) &&
              data.groupedTags[category]!.isNotEmpty) ...[
            _buildSectionTitle(category),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.groupedTags[category]!
                  .map((tag) => _buildModernChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimaryAlt,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Native Audio Player with just_audio integration
class NativeAudioPlayer extends StatefulWidget {
  final List<VisitProfileAudioTrack> tracks;
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
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
                      backgroundColor: Colors.grey.shade200,
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade400,
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
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey.shade400,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load audio',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
