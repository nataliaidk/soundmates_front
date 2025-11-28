import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/models.dart';
import 'swiping_view_model.dart';

/// Loader class responsible for fetching and processing all data needed by the Swiping screen.
/// Follows the pattern established in visit_profile_loader.dart.
class SwipingDataLoader {
  final ApiClient api;

  SwipingDataLoader(this.api);

  /// Main method to load all data for the Swiping screen.
  /// Returns a complete SwipingViewModel ready for display.
  Future<SwipingViewModel> loadData() async {
    // Initialize dictionaries
    final Map<String, TagDto> tagById = {};
    final Map<String, String> categoryNames = {};
    final Map<String, String> genderIdToName = {};
    final Map<String, String> countryIdToName = {};
    final Map<String, Map<String, String>> citiesByCountry = {};

    // Load auxiliary data in parallel
    final results = await Future.wait([
      _loadTagData(),
      _loadGenders(),
      _loadCountries(),
      _loadPreference(),
      _loadCurrentUserProfile(),
    ]);

    final tagData = results[0] as Map<String, dynamic>;
    final genders = results[1] as Map<String, String>;
    final countries = results[2] as Map<String, String>;
    final preference = results[3] as Map<String, bool>;
    final currentUserProfile = results[4] as Map<String, String?>;

    tagById.addAll(tagData['tagById'] as Map<String, TagDto>);
    categoryNames.addAll(tagData['categoryNames'] as Map<String, String>);
    genderIdToName.addAll(genders);
    countryIdToName.addAll(countries);

    final showArtists = preference['showArtists'] ?? true;
    final showBands = preference['showBands'] ?? true;

    // Fetch users
    final usersData = await _fetchUsers(showArtists, showBands);
    final rawUsers = usersData['users'] as List<Map<String, dynamic>>;
    final totalMatches = usersData['totalMatches'] as int;

    // Preload cities for all countries in the user list
    await _preloadCitiesForUsers(
      rawUsers,
      currentUserProfile['currentUserCountryId'],
      citiesByCountry,
    );

    // Process users into SwipingCardData
    final users = <SwipingCardData>[];
    for (final u in rawUsers) {
      users.add(
        _processUserData(u, genderIdToName, countryIdToName, citiesByCountry),
      );
    }

    // Fetch images
    final Map<String, String> userImages = {};
    for (final u in rawUsers) {
      final id = u['id']?.toString();
      if (id != null && id.isNotEmpty) {
        final imageUrl = await _fetchUserImage(id, u);
        if (imageUrl != null) {
          userImages[id] = imageUrl;
        }
      }
    }

    return SwipingViewModel(
      users: users,
      userImages: userImages,
      totalMatches: totalMatches,
      tagById: tagById,
      categoryNames: categoryNames,
      countryIdToName: countryIdToName,
      citiesByCountry: citiesByCountry,
      genderIdToName: genderIdToName,
      currentUserCountryId: currentUserProfile['currentUserCountryId'],
      currentUserCityId: currentUserProfile['currentUserCityId'],
      currentUserCountryName: currentUserProfile['currentUserCountryName'],
      currentUserCityName: currentUserProfile['currentUserCityName'],
      showArtists: showArtists,
      showBands: showBands,
    );
  }

  Future<Map<String, dynamic>> _loadTagData() async {
    final Map<String, TagDto> tagById = {};
    final Map<String, String> categoryNames = {};
    final Map<String, List<TagDto>> tagGroups = {};

    try {
      final tagsResp = await api.getTags();
      final categoriesResp = await api.getTagCategories();

      if (tagsResp.statusCode == 200 && categoriesResp.statusCode == 200) {
        var tagsDecoded = jsonDecode(tagsResp.body);
        if (tagsDecoded is String) tagsDecoded = jsonDecode(tagsDecoded);
        var catsDecoded = jsonDecode(categoriesResp.body);
        if (catsDecoded is String) catsDecoded = jsonDecode(catsDecoded);

        final List<TagDto> tags = [];
        if (tagsDecoded is List) {
          for (final e in tagsDecoded) {
            if (e is Map) {
              final t = TagDto.fromJson(Map<String, dynamic>.from(e));
              tags.add(t);
              tagById[t.id] = t;
            }
          }
        }

        if (catsDecoded is List) {
          for (final e in catsDecoded) {
            if (e is Map) {
              final c = TagCategoryDto.fromJson(Map<String, dynamic>.from(e));
              categoryNames[c.id] = c.name;
              tagGroups.putIfAbsent(c.id, () => []);
            }
          }
        }

        for (final t in tags) {
          if (t.tagCategoryId != null &&
              tagGroups.containsKey(t.tagCategoryId)) {
            tagGroups[t.tagCategoryId]!.add(t);
          }
        }
      }
    } catch (_) {
      // Silent fail; UI will fallback to plain tags if needed
    }

    return {
      'tagById': tagById,
      'categoryNames': categoryNames,
      'tagGroups': tagGroups,
    };
  }

  Future<Map<String, String>> _loadGenders() async {
    final Map<String, String> genderIdToName = {};
    try {
      final resp = await api.getGenders();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final g = GenderDto.fromJson(Map<String, dynamic>.from(e));
              genderIdToName[g.id] = g.name;
            }
          }
        }
      }
    } catch (_) {}
    return genderIdToName;
  }

  Future<Map<String, String>> _loadCountries() async {
    final Map<String, String> countryIdToName = {};
    try {
      final resp = await api.getCountries();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              final c = CountryDto.fromJson(Map<String, dynamic>.from(e));
              countryIdToName[c.id] = c.name;
            }
          }
        }
      }
    } catch (_) {}
    return countryIdToName;
  }

  Future<Map<String, bool>> _loadPreference() async {
    bool showArtists = true;
    bool showBands = true;
    try {
      final resp = await api.getMatchPreference();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is Map) {
          showArtists = decoded['showArtists'] is bool
              ? decoded['showArtists']
              : true;
          showBands = decoded['showBands'] is bool
              ? decoded['showBands']
              : true;
        }
      }
    } catch (_) {
      // Use defaults
    }
    return {'showArtists': showArtists, 'showBands': showBands};
  }

  Future<Map<String, String?>> _loadCurrentUserProfile() async {
    String? currentUserCountryId;
    String? currentUserCityId;
    String? currentUserCountryName;
    String? currentUserCityName;

    try {
      final resp = await api.getMyProfile();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is Map) {
          currentUserCountryId = decoded['countryId']?.toString();
          currentUserCityId = decoded['cityId']?.toString();
          currentUserCountryName =
              decoded['countryName']?.toString() ??
              decoded['country']?.toString();
          currentUserCityName =
              decoded['cityName']?.toString() ?? decoded['city']?.toString();
        }
      }
    } catch (_) {
      // Ignore, header will fallback to placeholder
    }

    return {
      'currentUserCountryId': currentUserCountryId,
      'currentUserCityId': currentUserCityId,
      'currentUserCountryName': currentUserCountryName,
      'currentUserCityName': currentUserCityName,
    };
  }

  Future<Map<String, dynamic>> _fetchUsers(
    bool showArtists,
    bool showBands,
  ) async {
    final List<Map<String, dynamic>> allUsers = [];

    // Fetch artists if enabled
    if (showArtists) {
      try {
        final resp = await api.getPotentialMatchesArtists(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(
              decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
            );
          }
        }
      } catch (_) {}
    }

    // Fetch bands if enabled
    if (showBands) {
      try {
        final resp = await api.getPotentialMatchesBands(limit: 50, offset: 0);
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is List) {
            allUsers.addAll(
              decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
            );
          }
        }
      } catch (_) {}
    }

    return {'users': allUsers, 'totalMatches': allUsers.length};
  }

  Future<void> _preloadCitiesForUsers(
    List<Map<String, dynamic>> users,
    String? currentUserCountryId,
    Map<String, Map<String, String>> citiesByCountry,
  ) async {
    try {
      final Set<String> countryIds = {};
      if (currentUserCountryId != null && currentUserCountryId.isNotEmpty) {
        countryIds.add(currentUserCountryId);
      }
      for (final u in users) {
        final c = (u['countryId'] ?? u['country'])?.toString();
        if (c != null && c.isNotEmpty) countryIds.add(c);
      }
      for (final countryId in countryIds) {
        if (citiesByCountry.containsKey(countryId)) continue;
        try {
          final resp = await api.getCities(countryId);
          if (resp.statusCode == 200) {
            var decoded = jsonDecode(resp.body);
            if (decoded is String) decoded = jsonDecode(decoded);
            final Map<String, String> map = {};
            if (decoded is List) {
              for (final e in decoded) {
                if (e is Map) {
                  final city = CityDto.fromJson(Map<String, dynamic>.from(e));
                  map[city.id] = city.name;
                }
              }
            }
            citiesByCountry[countryId] = map;
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<String?> _fetchUserImage(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      // Try to use profilePictures from the user data first
      if (userData['profilePictures'] is List &&
          (userData['profilePictures'] as List).isNotEmpty) {
        final pics = userData['profilePictures'] as List;
        final first = pics.first;
        if (first is Map) {
          final url = first['url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
      }

      // Fallback: fetch from endpoint
      final resp = await api.getProfilePicturesForUser(userId);
      if (resp.statusCode != 200) return null;
      var decoded = jsonDecode(resp.body);
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.firstWhere((e) => e is Map, orElse: () => null);
        if (first is Map) {
          // Try common fields
          String? url;
          for (final key in [
            'url',
            'fileUrl',
            'downloadUrl',
            'path',
            'file',
            'fileName',
            'filename',
            'id',
          ]) {
            if (first.containsKey(key) && first[key] != null) {
              final v = first[key].toString();
              if (key == 'id') {
                // Construct a probable download URL: base/profile-pictures/{id}
                final base = api.baseUrl;
                url = Uri.parse(base).resolve('profile-pictures/$v').toString();
              } else {
                url = v;
              }
              break;
            }
          }
          return url;
        }
      }
    } catch (_) {}
    return null;
  }

  SwipingCardData _processUserData(
    Map<String, dynamic> u,
    Map<String, String> genderIdToName,
    Map<String, String> countryIdToName,
    Map<String, Map<String, String>> citiesByCountry,
  ) {
    final id = u['id']?.toString() ?? '';
    final name = u['name']?.toString() ?? '(no name)';
    final description = u['description']?.toString() ?? '';
    final isBand = u['isBand'] is bool ? u['isBand'] as bool : false;

    final rawCountryId = (u['countryId'] ?? u['country'])?.toString();
    final rawCityId = (u['cityId'] ?? u['city'])?.toString();
    final countryName = rawCountryId != null
        ? (countryIdToName[rawCountryId] ?? u['countryName']?.toString())
        : (u['countryName']?.toString() ?? u['country']?.toString());
    final cityName = (rawCountryId != null && rawCityId != null)
        ? (citiesByCountry[rawCountryId] != null
              ? (citiesByCountry[rawCountryId]![rawCityId] ??
                    u['cityName']?.toString())
              : u['cityName']?.toString())
        : (u['cityName']?.toString() ?? u['city']?.toString());

    String? gender;
    if (!isBand) {
      if (u['gender'] != null) {
        gender = u['gender'].toString();
      } else if (u['genderId'] != null) {
        gender = genderIdToName[u['genderId'].toString()];
      }
    }

    int? age;
    if (u['birthDate'] != null && !isBand) {
      try {
        final birthDate = DateTime.parse(u['birthDate'].toString());
        age = DateTime.now().year - birthDate.year;
      } catch (_) {}
    }

    return SwipingCardData(
      userData: u,
      id: id,
      name: name,
      description: description,
      isBand: isBand,
      city: cityName,
      country: countryName,
      gender: gender,
      age: age,
    );
  }

  /// Send a like action to the API
  Future<int> like(String receiverId) async {
    final resp = await api.like(SwipeDto(receiverId: receiverId));
    return resp.statusCode;
  }

  /// Send a dislike action to the API
  Future<int> dislike(String receiverId) async {
    final resp = await api.dislike(SwipeDto(receiverId: receiverId));
    return resp.statusCode;
  }
}
