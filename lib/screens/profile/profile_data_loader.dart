import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/models.dart';

/// Helper class for loading profile-related data from the API
class ProfileDataLoader {
  final ApiClient api;

  ProfileDataLoader(this.api);

  Future<List<CountryDto>> loadCountries() async {
    try {
      final resp = await api.getCountries();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<CountryDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(CountryDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<CityDto>> loadCities(String countryId) async {
    try {
      final resp = await api.getCities(countryId);
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<CityDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) {
              list.add(CityDto.fromJson(Map<String, dynamic>.from(e)));
            }
          }
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<List<GenderDto>> loadGenders() async {
    try {
      final resp = await api.getGenders();
      if (resp.statusCode == 200) {
        var dec = jsonDecode(resp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          final List<GenderDto> genders = [];
          for (final e in dec) {
            if (e is Map) genders.add(GenderDto.fromJson(Map<String, dynamic>.from(e)));
          }
          return genders;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<BandRoleDto>> loadBandRoles() async {
    try {
      final resp = await api.getBandRoles();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<BandRoleDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(BandRoleDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        return list;
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> loadMyProfile() async {
    try {
      final resp = await api.getMyProfile();
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<TagDto>> loadTags() async {
    try {
      final resp = await api.getTags();
      if (resp.statusCode == 200) {
        var dec = jsonDecode(resp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          final List<TagDto> tags = [];
          for (final e in dec) {
            if (e is Map) tags.add(TagDto.fromJson(Map<String, dynamic>.from(e)));
          }
          return tags;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<List<TagCategoryDto>> loadTagCategories() async {
    try {
      final resp = await api.getTagCategories();
      if (resp.statusCode == 200) {
        var dec = jsonDecode(resp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          final List<TagCategoryDto> cats = [];
          for (final e in dec) {
            if (e is Map) cats.add(TagCategoryDto.fromJson(Map<String, dynamic>.from(e)));
          }
          return cats;
        }
      }
    } catch (_) {}
    return [];
  }
}
