import 'package:flutter_test/flutter_test.dart';
import 'package:zpi_test/api/token_store.dart';
import 'package:zpi_test/api/api_client.dart';
import 'package:zpi_test/state/auth_notifier.dart';

// Mock TokenStore for testing
class MockTokenStore extends TokenStore {
  final Map<String, String?> _mockStorage = {};

  @override
  Future<void> saveAccessToken(String token) async {
    _mockStorage['access'] = token;
  }

  @override
  Future<String?> readAccessToken() async {
    return _mockStorage['access'];
  }

  @override
  Future<void> deleteAccessToken() async {
    _mockStorage.remove('access');
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    _mockStorage['refresh'] = token;
  }

  @override
  Future<String?> readRefreshToken() async {
    return _mockStorage['refresh'];
  }

  @override
  Future<void> deleteRefreshToken() async {
    _mockStorage.remove('refresh');
  }

  @override
  Future<void> clear() async {
    _mockStorage.clear();
  }
}

void main() {
  group('AuthNotifier', () {
    late MockTokenStore mockTokenStore;
    late ApiClient mockApiClient;
    late AuthNotifier authNotifier;

    setUp(() {
      mockTokenStore = MockTokenStore();
      mockApiClient = ApiClient(
        tokenStore: mockTokenStore,
        baseUrl: 'http://localhost:5000/',
      );
      authNotifier = AuthNotifier(tokens: mockTokenStore, api: mockApiClient);
    });

    test('should initialize with null access token', () {
      expect(authNotifier.accessToken, isNull);
    });

    group('load', () {
      test('should load access token from storage', () async {
        await mockTokenStore.saveAccessToken('stored_token_123');

        await authNotifier.load();

        expect(authNotifier.accessToken, equals('stored_token_123'));
      });

      test('should handle missing token gracefully', () async {
        await authNotifier.load();

        expect(authNotifier.accessToken, isNull);
      });

      test('should notify listeners when loading', () async {
        await mockTokenStore.saveAccessToken('token_abc');
        
        bool notified = false;
        authNotifier.addListener(() {
          notified = true;
        });

        await authNotifier.load();

        expect(notified, isTrue);
      });
    });

    group('setTokens', () {
      test('should save and set access token', () async {
        await authNotifier.setTokens(access: 'new_access_token');

        expect(authNotifier.accessToken, equals('new_access_token'));
        expect(await mockTokenStore.readAccessToken(), equals('new_access_token'));
      });

      test('should save both access and refresh tokens', () async {
        await authNotifier.setTokens(
          access: 'new_access',
          refresh: 'new_refresh',
        );

        expect(authNotifier.accessToken, equals('new_access'));
        expect(await mockTokenStore.readAccessToken(), equals('new_access'));
        expect(await mockTokenStore.readRefreshToken(), equals('new_refresh'));
      });

      test('should notify listeners when setting tokens', () async {
        bool notified = false;
        authNotifier.addListener(() {
          notified = true;
        });

        await authNotifier.setTokens(access: 'token_xyz');

        expect(notified, isTrue);
      });

      test('should overwrite existing tokens', () async {
        await authNotifier.setTokens(access: 'old_token');
        await authNotifier.setTokens(access: 'new_token');

        expect(authNotifier.accessToken, equals('new_token'));
        expect(await mockTokenStore.readAccessToken(), equals('new_token'));
      });
    });

    group('clear', () {
      test('should clear all tokens from storage', () async {
        await authNotifier.setTokens(access: 'access', refresh: 'refresh');
        
        await authNotifier.clear();

        expect(authNotifier.accessToken, isNull);
        expect(await mockTokenStore.readAccessToken(), isNull);
        expect(await mockTokenStore.readRefreshToken(), isNull);
      });

      test('should notify listeners when clearing', () async {
        await authNotifier.setTokens(access: 'token');
        
        bool notified = false;
        authNotifier.addListener(() {
          notified = true;
        });

        await authNotifier.clear();

        expect(notified, isTrue);
      });

      test('should handle clearing already empty storage', () async {
        await authNotifier.clear();

        expect(authNotifier.accessToken, isNull);
        // Should not throw
      });
    });

    group('integration scenarios', () {
      test('should handle login flow correctly', () async {
        // Simulate login
        await authNotifier.setTokens(
          access: 'login_access_token',
          refresh: 'login_refresh_token',
        );

        expect(authNotifier.accessToken, equals('login_access_token'));
        expect(await mockTokenStore.readAccessToken(), equals('login_access_token'));
        expect(await mockTokenStore.readRefreshToken(), equals('login_refresh_token'));
      });

      test('should handle logout flow correctly', () async {
        // Login first
        await authNotifier.setTokens(access: 'token', refresh: 'refresh');
        
        // Then logout
        await authNotifier.clear();

        expect(authNotifier.accessToken, isNull);
        expect(await mockTokenStore.readAccessToken(), isNull);
        expect(await mockTokenStore.readRefreshToken(), isNull);
      });

      test('should handle token refresh correctly', () async {
        await authNotifier.setTokens(access: 'old_access', refresh: 'old_refresh');
        
        // Simulate token refresh
        await authNotifier.setTokens(access: 'new_access', refresh: 'new_refresh');

        expect(authNotifier.accessToken, equals('new_access'));
        expect(await mockTokenStore.readAccessToken(), equals('new_access'));
        expect(await mockTokenStore.readRefreshToken(), equals('new_refresh'));
      });

      test('should handle app restart with stored tokens', () async {
        // Simulate storing tokens
        await mockTokenStore.saveAccessToken('stored_access');
        await mockTokenStore.saveRefreshToken('stored_refresh');

        // Create new notifier instance (simulating app restart)
        final newNotifier = AuthNotifier(tokens: mockTokenStore, api: mockApiClient);
        await newNotifier.load();

        expect(newNotifier.accessToken, equals('stored_access'));
      });
    });
  });
}
