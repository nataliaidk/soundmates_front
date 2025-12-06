import 'package:flutter_test/flutter_test.dart';
import 'package:soundmates/utils/audio_notifier.dart';

// NOTE: Full testing of AudioNotifier is limited due to just_audio's architecture.
// The just_audio plugin creates unique platform channels for each AudioPlayer instance
// (e.g., com.ryanheise.just_audio.methods.{uuid}), making it difficult to mock in unit tests.
//
// Integration tests or widget tests with actual audio files would be more appropriate  
// for comprehensive audio functionality testing. These unit tests focus on verifying
// the API surface exists and the singleton pattern works correctly.

void main() {
  group('AudioNotifier', () {
    test('should be a singleton', () {
      final instance1 = AudioNotifier.instance;
      final instance2 = AudioNotifier.instance;

      expect(instance1, same(instance2));
    });

    test('should have all required methods', () {
      final notifier = AudioNotifier.instance;
      
      // Verify all methods exist and are callable
      expect(notifier.preloadAll, isA<Function>());
      expect(notifier.playMatchReceived, isA<Function>());
      expect(notifier.playMatchMutual, isA<Function>());
      expect(notifier.playMessage, isA<Function>());
      expect(notifier.dispose, isA<Function>());
    });

    test('method signatures are correct', () {
      final notifier = AudioNotifier.instance;
      
      // Verify methods are Future-returning functions
      // We don't call them to avoid platform channel issues
      expect(notifier.preloadAll, isA<Future<void> Function()>());
      expect(notifier.playMatchReceived, isA<Future<void> Function()>());
      expect(notifier.playMatchMutual, isA<Future<void> Function()>());
      expect(notifier.playMessage, isA<Future<void> Function()>());
      expect(notifier.dispose, isA<Future<void> Function()>());
    });
  });
}
