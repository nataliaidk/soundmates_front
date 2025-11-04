import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models.dart';
import 'token_store.dart';
import '../state/auth_notifier.dart';

class ApiClient {
  final String baseUrl;
  final TokenStore? tokenStore;
  final AuthNotifier? authNotifier;

  ApiClient({this.tokenStore, this.authNotifier, String? baseUrl}) : baseUrl = _normalizeBase(baseUrl ?? dotenv.get('API_BASE_URL', fallback: 'http://localhost:5000/'));

  static String _normalizeBase(String url) {
    if (!url.endsWith('/')) return '$url/';
    return url;
  }

  Uri _uri(String path) => Uri.parse(baseUrl).resolve(path.startsWith('/') ? path.substring(1) : path);

  String _sanitizeToken(String token) {
    var t = token.trim();
    if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
      t = t.substring(1, t.length - 1);
    }
    if (t.toLowerCase().startsWith('bearer ')) t = t.substring(7).trim();
    return t;
  }

  Future<http.Response> register(RegisterDto dto) async {
  final headers = _jsonHeaders();
  final resp = await http.post(_uri('/auth/register'), headers: headers, body: jsonEncode(dto.toJson()));
    // try to save tokens immediately
    await saveTokensFromResponseBody(resp.body);
    // also check response headers for Authorization: Bearer ...
    final headerAuth = resp.headers['authorization'] ?? resp.headers['Authorization'];
    if (headerAuth != null && headerAuth.isNotEmpty) {
      final t = _sanitizeToken(headerAuth);
      if (t.isNotEmpty) await setTokens(accessToken: t);
      if (authNotifier != null) await authNotifier!.setTokens(access: t);
    } else if (authNotifier != null) {
      final access = await tokenStore?.readAccessToken();
      if (access != null) await authNotifier!.setTokens(access: _sanitizeToken(access));
    }
    return resp;
  }
  Future<http.Response> getUserOptions() async {
    final uri = _uri('api/lookups/user-options');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  // PUT /users/profile with wrapper { "updateUserDto": { ... } }
  Future<http.Response> updateUserWithTags(UpdateUserProfileDto dto, [List<String>? tags]) async {
    final uri = _uri('/users/profile');
    final headers = await _authHeaders();
    final inner = dto.toJson();
    if (tags != null) inner['tagsIds'] = tags;
    return await _withRefreshRetry(() => http.put(uri, headers: headers, body: jsonEncode(inner)));
  }

  Future<http.Response> updateArtistProfile(UpdateArtistProfile dto, [List<String>? tags]) async {
    final uri = _uri('/users/profile');
    final headers = await _authHeaders();
    final inner = dto.toJson();
    if (tags != null) inner['tagsIds'] = tags;
    return await _withRefreshRetry(() => http.put(uri, headers: headers, body: jsonEncode(inner)));
  }

  Future<http.Response> updateBandProfile(UpdateBandProfile dto, [List<String>? tags]) async {
    final uri = _uri('/users/profile');
    final headers = await _authHeaders();
    final inner = dto.toJson();
    if (tags != null) inner['tagsIds'] = tags;
    return await _withRefreshRetry(() => http.put(uri, headers: headers, body: jsonEncode(inner)));
  }

  Future<http.Response> login(LoginDto dto) async {
    final uri = _uri('/auth/login');
    final headers = _jsonHeaders();
    final resp = await http.post(uri, headers: headers, body: jsonEncode(dto.toJson()));
    // try to save tokens immediately
    await saveTokensFromResponseBody(resp.body);
    // also check response headers for Authorization: Bearer ...
    final headerAuth = resp.headers['authorization'] ?? resp.headers['Authorization'];
    if (headerAuth != null && headerAuth.isNotEmpty) {
      final t = _sanitizeToken(headerAuth);
      if (t.isNotEmpty) await setTokens(accessToken: t);
      if (authNotifier != null) await authNotifier!.setTokens(access: t);
    } else if (authNotifier != null) {
      final access = await tokenStore?.readAccessToken();
      if (access != null) await authNotifier!.setTokens(access: _sanitizeToken(access));
    }
    return resp;
  }

  Future<http.Response> refresh(RefreshTokenDto dto) async {
    final uri = _uri('/auth/refresh');
    final headers = await _authHeaders();
    final resp = await http.post(uri, headers: headers, body: jsonEncode(dto.toJson()));
    await saveTokensFromResponseBody(resp.body);
    final headerAuth = resp.headers['authorization'] ?? resp.headers['Authorization'];
    if (headerAuth != null && headerAuth.isNotEmpty) {
      final t = _sanitizeToken(headerAuth);
      if (t.isNotEmpty) await setTokens(accessToken: t);
      if (authNotifier != null) await authNotifier!.setTokens(access: t);
    } else if (authNotifier != null) {
      final access = await tokenStore?.readAccessToken();
      if (access != null) await authNotifier!.setTokens(access: _sanitizeToken(access));
    }
    return resp;
  }

  Future<http.Response> logout() async {
    final uri = _uri('/auth/logout');
    final headers = await _authHeaders();
    final resp = await http.post(uri, headers: headers);
    await clearTokens();
    if (authNotifier != null) await authNotifier!.clear();
    return resp;
  }

  /// Save tokens to the token store (if present)
  Future<void> setTokens({required String accessToken, String? refreshToken}) async {
    if (tokenStore == null) return;
    final a = _sanitizeToken(accessToken);
    await tokenStore!.saveAccessToken(a);
    if (refreshToken != null) {
      final r = _sanitizeToken(refreshToken);
      await tokenStore!.saveRefreshToken(r);
    }
  }

  Future<void> clearTokens() async {
    if (tokenStore == null) return;
    await tokenStore!.clear();
  }

  /// Try to parse tokens from a login/refresh response body.
  /// Expects JSON body containing e.g. { "accessToken": "...", "refreshToken": "..." }
  Future<void> saveTokensFromResponseBody(String body) async {
    if (tokenStore == null) return;
    try {
      final decoded = jsonDecode(body);
      // If the server returns a JSON string like "<token>", jsonDecode yields a String.
      // Treat that as a raw token candidate.
      if (decoded is String) {
        final s = _sanitizeToken(decoded);
        if (s.isNotEmpty && (s.contains('.') || s.length > 20)) {
          await tokenStore!.saveAccessToken(s);
          return;
        }
      }

      String? findToken(dynamic node, List<String> keys) {
        if (node == null) return null;
        if (node is Map) {
          for (final k in keys) {
            if (node.containsKey(k) && node[k] is String) return node[k] as String;
          }
          for (final v in node.values) {
            final res = findToken(v, keys);
            if (res != null) return res;
          }
        } else if (node is List) {
          for (final e in node) {
            final res = findToken(e, keys);
            if (res != null) return res;
          }
        }
        return null;
      }

      final access = findToken(decoded, ['accessToken', 'access_token', 'token', 'jwt', 'idToken', 'access']);
      final refresh = findToken(decoded, ['refreshToken', 'refresh_token', 'refresh']);
      var saved = false;
      if (access != null) {
        final a = _sanitizeToken(access);
        await tokenStore!.saveAccessToken(a);
        saved = true;
      }
      if (refresh != null) {
        final r = _sanitizeToken(refresh);
        await tokenStore!.saveRefreshToken(r);
        saved = true;
      }
      if (saved) return;
    } catch (_) {
      // ignore parse errors
    }

    // If body wasn't JSON, try treating it as a raw token string (some servers return token plain)
    final s = body.trim();
    if (s.isNotEmpty) {
      // heuristic: JWT-like (has two dots) or long token
      if (s.contains('.') || s.length > 20) {
        final a = _sanitizeToken(s);
        await tokenStore!.saveAccessToken(a);
      }
    }
  }

  Future<http.Response> like(SwipeDto dto) async {
    final uri = _uri('/matching/like');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers, body: jsonEncode(dto.toJson())));
  }

  Future<http.Response> dislike(SwipeDto dto) async {
    final uri = _uri('/matching/dislike');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers, body: jsonEncode(dto.toJson())));
  }

  Future<http.Response> getPotentialMatchesArtists({int limit = 20, int offset = 0}) async {
    final uri = _uri('matching/artists?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getPotentialMatchesBands({int limit = 20, int offset = 0}) async {
    final uri = _uri('matching/bands?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getMatches({int limit = 20, int offset = 0}) async {
    final uri = _uri('matching/matches?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getMessagePreviews({int limit = 20, int offset = 0}) async {
    final uri = _uri('messages/preview?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getMessages(String userId, {int limit = 20, int offset = 0}) async {
    final uri = _uri('messages/$userId?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> sendMessage(SendMessageDto dto) async {
    final uri = _uri('/messages');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers, body: jsonEncode(dto.toJson())));
  }

  Future<http.Response> getMusicSamples({int limit = 20, int offset = 0}) async {
    final uri = _uri('music-samples?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return http.get(uri, headers: headers);
  }

  Future<http.StreamedResponse> uploadMusicSample(List<int> bytes, String filename) async {
    final uri = _uri('music-samples');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _authHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    final parts = filename.split('.');
    final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
    MediaType? ct;
    if (ext == 'mp3') {
      ct = MediaType('audio', 'mpeg');
    } else if (ext == 'wav') {
      ct = MediaType('audio', 'wav');
    } else if (ext == 'ogg') {
      ct = MediaType('audio', 'ogg');
    }
    if (ct != null) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: ct));
    } else {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    }
    final streamed = await request.send();
    if (streamed.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final request2 = http.MultipartRequest('POST', uri);
        final headers2 = await _authHeaders();
        request2.headers.addAll(headers2);
        request2.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
        return request2.send();
      }
    }
    return streamed;
  }

  Future<http.StreamedResponse> uploadProfilePicture(List<int> bytes, String filename) async {
    final uri = _uri('profile-pictures');
    final request = http.MultipartRequest('POST', uri);
    final headers = await _authHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    final parts = filename.split('.');
    final ext = parts.length > 1 ? parts.last.toLowerCase() : '';
    MediaType? ct;
    if (ext == 'jpg' || ext == 'jpeg') {
      ct = MediaType('image', 'jpeg');
    } else if (ext == 'png') {
      ct = MediaType('image', 'png');
    } else if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      ct = MediaType('image', 'jpeg');
    }
    if (ct != null) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: ct));
    } else {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    }
    final streamed = await request.send();
    if (streamed.statusCode == 401) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final request2 = http.MultipartRequest('POST', uri);
        final headers2 = await _authHeaders();
        request2.headers.addAll(headers2);
        request2.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
        return request2.send();
      }
    }
    return streamed;
  }

  Future<http.Response> getProfilePictures({int limit = 20, int offset = 0}) async {
    final uri = _uri('profile-pictures?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getProfilePicturesForUser(String userId, {int limit = 20, int offset = 0}) async {
    final uri = _uri('profile-pictures/$userId?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> deleteProfilePicture(String pictureId) async {
    final uri = _uri('profile-pictures/$pictureId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.delete(uri, headers: headers));
  }

  Future<http.Response> moveProfilePictureUp(String pictureId) async {
    final uri = _uri('profile-pictures/move-display-order-up/$pictureId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers));
  }

  Future<http.Response> moveProfilePictureDown(String pictureId) async {
    final uri = _uri('profile-pictures/move-display-order-down/$pictureId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers));
  }

  Future<http.Response> getMyProfile() async {
    final uri = _uri('users/profile');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  /// Calls users/profile and returns parsed UserDto on success (statusCode 200).
  Future<UserDto?> getMyProfileDto() async {
    final resp = await getMyProfile();
    if (resp.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(resp.body);
      if (decoded is String) {
        final parsed = jsonDecode(decoded);
        if (parsed is Map) return UserDto.fromJson(Map<String, dynamic>.from(parsed));
      } else if (decoded is Map) {
        return UserDto.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  // GET /dictionaries/countries
  Future<http.Response> getCountries() async {
    final uri = _uri('dictionaries/countries');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }
  Future<http.Response> getBandRoles() async {
    final uri = _uri('dictionaries/band-roles');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }
  // GET /dictionaries/cities/{countryId}
  Future<http.Response> getCities(String countryId) async {
    final uri = _uri('dictionaries/cities/$countryId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  // GET /dictionaries/tags
  Future<http.Response> getTags() async {
    final uri = _uri('dictionaries/tags');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  // GET /dictionaries/tag-categories
  Future<http.Response> getTagCategories() async {
    final uri = _uri('dictionaries/tag-categories');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  // GET /dictionaries/genders
  Future<http.Response> getGenders() async {
    final uri = _uri('dictionaries/genders');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> getUserById(String id) async {
    final uri = _uri('users/$id');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> changePassword(ChangePasswordDto dto) async {
    final uri = _uri('users/change-password');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers, body: jsonEncode(dto.toJson())));
  }

  Future<http.Response> deleteMusicSample(String sampleId) async {
    final uri = _uri('music-samples/$sampleId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.delete(uri, headers: headers));
  }

  Future<http.Response> moveMusicSampleUp(String sampleId) async {
    final uri = _uri('music-samples/move-display-order-up/$sampleId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers));
  }

  Future<http.Response> moveMusicSampleDown(String sampleId) async {
    final uri = _uri('music-samples/move-display-order-down/$sampleId');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.post(uri, headers: headers));
  }

  Future<http.Response> getUsers({int limit = 20, int offset = 0}) async {
    final uri = _uri('users?limit=$limit&offset=$offset');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> updateUser(UpdateUserProfileDto dto) async {
    final uri = _uri('/users/profile');
    final headers = await _authHeaders();
    final envelope = {'updateUserDto': dto.toJson()};
    return await _withRefreshRetry(() => http.put(uri, headers: headers, body: jsonEncode(envelope)));
  }

  Future<http.Response> deleteUser(PasswordDto dto) async {
    final uri = _uri('/users');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.delete(uri, headers: headers, body: jsonEncode(dto.toJson())));
  }

  Map<String, String> _jsonHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<Map<String, String>> _authHeaders() async {
    final headers = Map<String, String>.from(_jsonHeaders());
    if (tokenStore != null) {
      var token = await tokenStore!.readAccessToken();
      if (token != null && token.isNotEmpty) {
        token = token.trim();
        if ((token.startsWith('"') && token.endsWith('"')) || (token.startsWith("'") && token.endsWith("'"))) {
          token = token.substring(1, token.length - 1);
        }
        if (token.toLowerCase().startsWith('bearer ')) {
          token = token.substring(7).trim();
        }
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<bool> _tryRefresh() async {
    if (tokenStore == null) return false;
    final refreshToken = await tokenStore!.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
  final resp = await refresh(RefreshTokenDto(refreshToken: refreshToken));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _withRefreshRetry(Future<http.Response> Function() fn) async {
    final resp = await fn();
    if (resp.statusCode != 401) return resp;
    final refreshed = await _tryRefresh();
    if (!refreshed) return resp;
    return await fn();
  }

  Future<http.Response> getMatchPreference() async {
    final uri = _uri('matching/match-preference');
    final headers = await _authHeaders();
    return await _withRefreshRetry(() => http.get(uri, headers: headers));
  }

  Future<http.Response> updateMatchPreference(UpdateMatchPreferenceDto dto) async {
    final uri = _uri('matching/match-preference');
    final headers = await _authHeaders();
    final body = jsonEncode(dto.toJson());
    return await _withRefreshRetry(() => http.put(uri, headers: headers, body: body));
  }

  Future<OtherUserProfileDto?> getOtherUserProfile(String userId) async {
    final resp = await getUserById(userId);
    if (resp.statusCode != 200) return null;

    try {
      final decoded = jsonDecode(resp.body);
      final json = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      if (json == null) return null;

      final userType = json['userType']?.toString();
      final isBand = userType == 'band' || (json['isBand'] is bool ? json['isBand'] as bool : false);

      if (isBand) {
        return OtherUserProfileBandDto.fromJson(json);
      } else {
        return OtherUserProfileArtistDto.fromJson(json);
      }
    } catch (e) {
      print('Error parsing profile: $e');
      return null;
    }
  }


}
