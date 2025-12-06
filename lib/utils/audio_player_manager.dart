import 'package:just_audio/just_audio.dart';

/// Singleton manager to control all active audio players in the app
/// Ensures only one audio plays at a time and provides cleanup methods
class AudioPlayerManager {
  AudioPlayerManager._internal();

  static final AudioPlayerManager instance = AudioPlayerManager._internal();

  final List<AudioPlayer> _activePlayers = [];

  /// Register a new audio player
  void registerPlayer(AudioPlayer player) {
    if (!_activePlayers.contains(player)) {
      _activePlayers.add(player);
    }
  }

  /// Unregister an audio player (typically on dispose)
  void unregisterPlayer(AudioPlayer player) {
    _activePlayers.remove(player);
  }

  /// Stop and pause all active audio players
  Future<void> stopAll() async {
    for (final player in _activePlayers) {
      try {
        await player.pause();
      } catch (e) {
        // Player might be disposed already, ignore
      }
    }
  }

  /// Dispose all active audio players
  Future<void> disposeAll() async {
    for (final player in List.from(_activePlayers)) {
      try {
        await player.dispose();
      } catch (e) {
        // Player might be disposed already, ignore
      }
    }
    _activePlayers.clear();
  }

  /// Pause all other players except the given one (for single-play behavior)
  Future<void> pauseAllExcept(AudioPlayer? exceptPlayer) async {
    for (final player in _activePlayers) {
      if (player != exceptPlayer) {
        try {
          await player.pause();
        } catch (e) {
          // Player might be disposed already, ignore
        }
      }
    }
  }
}

