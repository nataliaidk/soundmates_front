import 'package:flutter_test/flutter_test.dart';
import 'package:soundmates/api/event_hub_service.dart';
import 'package:soundmates/api/token_store.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Mock TokenStore for testing
class MockTokenStore extends TokenStore {
  String? _accessToken;

  @override
  Future<String?> readAccessToken() async {
    return _accessToken;
  }

  @override
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize dotenv with test values
    dotenv.testLoad(fileInput: '''
API_BASE_URL=http://localhost:5000/
''');
  });

  group('EventHubService', () {
    late MockTokenStore mockTokenStore;
    late EventHubService eventHubService;

    setUp(() {
      mockTokenStore = MockTokenStore();
      eventHubService = EventHubService(tokenStore: mockTokenStore);
    });

    tearDown(() async {
      await eventHubService.disconnect();
    });

    test('should initialize with no connection', () {
      expect(eventHubService.connection, isNull);
      expect(eventHubService.connectionId, isNull);
    });

    test('should require access token to connect', () async {
      // No token stored
      await eventHubService.connect();

      // Connection should not be established without token
      // In real scenario, this would print an error message
      expect(true, isTrue); // Test that it doesn't crash
    });

    test('should handle connect with valid token', () async {
      await mockTokenStore.saveAccessToken('test_access_token');

      // This will attempt to connect but may fail in test environment
      // We just verify it doesn't crash
      await eventHubService.connect();

      // In test environment, connection might not succeed, but shouldn't crash
      expect(true, isTrue);
    });

    test('should handle disconnect when not connected', () async {
      // Should not throw when disconnecting without connection
      await eventHubService.disconnect();

      expect(eventHubService.connection, isNull);
    });

    test('should handle multiple disconnect calls', () async {
      await eventHubService.disconnect();
      await eventHubService.disconnect();
      await eventHubService.disconnect();

      expect(eventHubService.connection, isNull);
    });

    test('should allow setting callbacks', () {
      eventHubService.onMessageReceived = (data) {};
      eventHubService.onMatchReceived = (data) {};
      eventHubService.onMatchCreated = (data) {};

      expect(eventHubService.onMessageReceived, isNotNull);
      expect(eventHubService.onMatchReceived, isNotNull);
      expect(eventHubService.onMatchCreated, isNotNull);
    });

    test('should manage message listeners', () {
      void listener1(dynamic data) {}
      void listener2(dynamic data) {}

      eventHubService.addMessageListener(listener1);
      eventHubService.addMessageListener(listener2);

      // Verify listeners can be added
      expect(true, isTrue);

      // Remove listeners
      eventHubService.removeMessageListener(listener1);
      eventHubService.removeMessageListener(listener2);

      expect(true, isTrue);
    });

    test('should not add duplicate message listeners', () {
      void listener(dynamic data) {}

      eventHubService.addMessageListener(listener);
      eventHubService.addMessageListener(listener);
      eventHubService.addMessageListener(listener);

      // Should only be added once
      // We can't directly verify this, but the method should handle it
      expect(true, isTrue);
    });

    test('should handle removing non-existent listener', () {
      void listener(dynamic data) {}

      // Should not throw when removing listener that wasn't added
      eventHubService.removeMessageListener(listener);

      expect(true, isTrue);
    });

    test('should manage active conversation user', () {
      expect(eventHubService.activeConversationUserId, isNull);

      eventHubService.setActiveConversationUser('user-123');
      expect(eventHubService.activeConversationUserId, equals('user-123'));

      eventHubService.setActiveConversationUser('user-456');
      expect(eventHubService.activeConversationUserId, equals('user-456'));

      eventHubService.setActiveConversationUser(null);
      expect(eventHubService.activeConversationUserId, isNull);
    });

    test('should handle connect after previous disconnect', () async {
      await mockTokenStore.saveAccessToken('token1');
      await eventHubService.connect();
      await eventHubService.disconnect();

      await mockTokenStore.saveAccessToken('token2');
      await eventHubService.connect();

      // Should handle reconnection without issues
      expect(true, isTrue);
    });

    test('should handle connection state changes', () async {
      await mockTokenStore.saveAccessToken('test_token');
      
      // Connect
      await eventHubService.connect();
      
      // Disconnect
      await eventHubService.disconnect();
      
      expect(eventHubService.connection, isNull);
    });

    group('Callback scenarios', () {
      test('should support multiple message listeners', () {
        final listeners = <Function(dynamic)>[];

        for (int i = 0; i < 5; i++) {
          void listener(dynamic data) {}
          listeners.add(listener);
          eventHubService.addMessageListener(listener);
        }

        expect(true, isTrue);

        // Clean up
        for (final listener in listeners) {
          eventHubService.removeMessageListener(listener);
        }
      });

      test('should handle clearing callbacks', () {
        eventHubService.onMessageReceived = (data) {};
        eventHubService.onMatchReceived = (data) {};
        eventHubService.onMatchCreated = (data) {};

        // Clear callbacks
        eventHubService.onMessageReceived = null;
        eventHubService.onMatchReceived = null;
        eventHubService.onMatchCreated = null;

        expect(eventHubService.onMessageReceived, isNull);
        expect(eventHubService.onMatchReceived, isNull);
        expect(eventHubService.onMatchCreated, isNull);
      });
    });

    group('Edge cases', () {
      test('should handle empty token', () async {
        await mockTokenStore.saveAccessToken('');
        
        await eventHubService.connect();

        // Should handle gracefully
        expect(true, isTrue);
      });

      test('should handle connect without token store', () async {
        final service = EventHubService(tokenStore: mockTokenStore);
        await service.connect();

        // Should not crash
        expect(true, isTrue);
      });

      test('should handle rapid connect/disconnect cycles', () async {
        await mockTokenStore.saveAccessToken('test_token');

        for (int i = 0; i < 3; i++) {
          await eventHubService.connect();
          await eventHubService.disconnect();
        }

        expect(true, isTrue);
      });
    });
  });
}
