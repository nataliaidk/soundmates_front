import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Handles short notification sounds (match/message) across the app.
class AudioNotifier {
  AudioNotifier._internal();

  static final AudioNotifier instance = AudioNotifier._internal();

  final Map<_NotificationSound, AudioPlayer> _players = {};
  bool _preloadStarted = false;

  Future<void> preloadAll() async {
    if (_preloadStarted) return;
    _preloadStarted = true;
    await Future.wait(
      _NotificationSound.values.map((sound) async {
        try {
          await _preparePlayer(sound);
        } catch (e) {
          debugPrint('AudioNotifier preload failed for $sound: $e');
        }
      }),
    );
  }

  Future<void> playMatchReceived() => _play(_NotificationSound.matchReceived);

  Future<void> playMatchMutual() => _play(_NotificationSound.matchMutual);

  Future<void> playMessage() => _play(_NotificationSound.messageReceived);

  Future<void> dispose() async {
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _preloadStarted = false;
  }

  Future<void> _play(_NotificationSound sound) async {
    try {
      final player = _players[sound] ?? await _preparePlayer(sound);
      await player.seek(Duration.zero);
      await player.play();
    } catch (e) {
      debugPrint('AudioNotifier playback failed for $sound: $e');
    }
  }

  Future<AudioPlayer> _preparePlayer(_NotificationSound sound) async {
    final player = _players[sound] ?? AudioPlayer();
    _players[sound] = player;
    await player.setAsset(sound.assetPath);
    return player;
  }
}

enum _NotificationSound {
  matchReceived('lib/assets/sounds/match-received.mp3'),
  matchMutual('lib/assets/sounds/match-given.mp3'),
  messageReceived('lib/assets/sounds/message-received.mp3');

  const _NotificationSound(this.assetPath);

  final String assetPath;
}
