import 'package:flutter_test/flutter_test.dart';
import 'package:soundmates/api/token_store.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TokenStore', () {
    late TokenStore tokenStore;
    final Map<String, String> mockStorage = {};

    setUp(() {
      mockStorage.clear();
      
      // Mock flutter_secure_storage channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'write':
              final args = methodCall.arguments as Map;
              mockStorage[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              final args = methodCall.arguments as Map;
              return mockStorage[args['key'] as String];
            case 'delete':
              final args = methodCall.arguments as Map;
              mockStorage.remove(args['key'] as String);
              return null;
            case 'readAll':
              return mockStorage;
            case 'deleteAll':
              mockStorage.clear();
              return null;
            default:
              return null;
          }
        },
      );

      tokenStore = TokenStore();
    });

    tearDown(() {
      // Clean up mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
    });

    group('Access Token', () {
      test('should save and read access token', () async {
        const testToken = 'test_access_token_123';
        
        await tokenStore.saveAccessToken(testToken);
        final result = await tokenStore.readAccessToken();
        
        expect(result, equals(testToken));
      });

      test('should return null when no access token stored', () async {
        final result = await tokenStore.readAccessToken();
        
        expect(result, isNull);
      });

      test('should delete access token', () async {
        const testToken = 'test_access_token_456';
        
        await tokenStore.saveAccessToken(testToken);
        await tokenStore.deleteAccessToken();
        final result = await tokenStore.readAccessToken();
        
        expect(result, isNull);
      });
    });

    group('Refresh Token', () {
      test('should save and read refresh token', () async {
        const testToken = 'test_refresh_token_789';
        
        await tokenStore.saveRefreshToken(testToken);
        final result = await tokenStore.readRefreshToken();
        
        expect(result, equals(testToken));
      });

      test('should return null when no refresh token stored', () async {
        final result = await tokenStore.readRefreshToken();
        
        expect(result, isNull);
      });

      test('should delete refresh token', () async {
        const testToken = 'test_refresh_token_abc';
        
        await tokenStore.saveRefreshToken(testToken);
        await tokenStore.deleteRefreshToken();
        final result = await tokenStore.readRefreshToken();
        
        expect(result, isNull);
      });
    });

    group('Clear All', () {
      test('should clear both access and refresh tokens', () async {
        const accessToken = 'access_xyz';
        const refreshToken = 'refresh_xyz';
        
        await tokenStore.saveAccessToken(accessToken);
        await tokenStore.saveRefreshToken(refreshToken);
        
        await tokenStore.clear();
        
        final access = await tokenStore.readAccessToken();
        final refresh = await tokenStore.readRefreshToken();
        
        expect(access, isNull);
        expect(refresh, isNull);
      });
    });

    group('Token Overwrite', () {
      test('should overwrite existing access token', () async {
        const oldToken = 'old_access_token';
        const newToken = 'new_access_token';
        
        await tokenStore.saveAccessToken(oldToken);
        await tokenStore.saveAccessToken(newToken);
        final result = await tokenStore.readAccessToken();
        
        expect(result, equals(newToken));
      });

      test('should overwrite existing refresh token', () async {
        const oldToken = 'old_refresh_token';
        const newToken = 'new_refresh_token';
        
        await tokenStore.saveRefreshToken(oldToken);
        await tokenStore.saveRefreshToken(newToken);
        final result = await tokenStore.readRefreshToken();
        
        expect(result, equals(newToken));
      });
    });
  });
}
