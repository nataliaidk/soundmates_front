import 'package:flutter/foundation.dart';
import '../api/token_store.dart';
import '../api/api_client.dart';

class AuthNotifier extends ChangeNotifier {
  final TokenStore tokens;
  final ApiClient api;

  AuthNotifier({required this.tokens, required this.api});

  String? _access;
  String? get accessToken => _access;

  Future<void> load() async {
    _access = await tokens.readAccessToken();
    notifyListeners();
  }

  Future<void> setTokens({required String access, String? refresh}) async {
    await tokens.saveAccessToken(access);
    if (refresh != null) await tokens.saveRefreshToken(refresh);
    _access = access;
    notifyListeners();
  }

  Future<void> clear() async {
    await tokens.clear();
    _access = null;
    notifyListeners();
  }
}
