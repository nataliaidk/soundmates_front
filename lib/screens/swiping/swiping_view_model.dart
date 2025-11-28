import '../../api/models.dart';

/// View model representing the complete state of the Swiping screen.
/// Contains all data ready for display without requiring further processing.
class SwipingViewModel {
  final List<SwipingCardData> users;
  final Map<String, String> userImages; // userId -> imageUrl
  final int totalMatches;
  final Map<String, TagDto> tagById;
  final Map<String, String> categoryNames;
  final Map<String, String> countryIdToName;
  final Map<String, Map<String, String>> citiesByCountry;
  final Map<String, String> genderIdToName;
  final String? currentUserCountryId;
  final String? currentUserCityId;
  final String? currentUserCountryName;
  final String? currentUserCityName;
  final bool showArtists;
  final bool showBands;

  SwipingViewModel({
    required this.users,
    required this.userImages,
    required this.totalMatches,
    required this.tagById,
    required this.categoryNames,
    required this.countryIdToName,
    required this.citiesByCountry,
    required this.genderIdToName,
    this.currentUserCountryId,
    this.currentUserCityId,
    this.currentUserCountryName,
    this.currentUserCityName,
    required this.showArtists,
    required this.showBands,
  });

  /// Get the current match index (1-based)
  int get currentMatchIndex {
    if (totalMatches == 0) return 0;
    if (users.isEmpty) return totalMatches;
    final processed = totalMatches - users.length;
    final current = processed + 1;
    if (current < 1) return 1;
    if (current > totalMatches) return totalMatches;
    return current;
  }

  /// Get the headline text for the header
  String get matchHeadline {
    if (totalMatches == 0) {
      return 'No potential matches yet';
    }
    return 'Showing $currentMatchIndex of $totalMatches potential matches';
  }

  /// Get the current user's location label
  String get currentLocationLabel {
    final city = _resolveCityName(
      currentUserCountryId,
      currentUserCityId,
      currentUserCityName,
    );
    final country = _resolveCountryName(
      currentUserCountryId,
      currentUserCountryName,
    );
    if (city != null && country != null) return '$city, $country';
    return city ?? country ?? 'Location not set';
  }

  String? _resolveCountryName(String? countryId, String? fallback) {
    if (countryId != null) {
      final resolved = countryIdToName[countryId];
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String? _resolveCityName(
    String? countryId,
    String? cityId,
    String? fallback,
  ) {
    if (countryId != null && cityId != null) {
      final mapped = citiesByCountry[countryId]?[cityId];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }
}

/// Data class representing a single user card.
class SwipingCardData {
  final Map<String, dynamic> userData;
  final String id;
  final String name;
  final String description;
  final bool isBand;
  final String? city;
  final String? country;
  final String? gender;
  final int? age;

  SwipingCardData({
    required this.userData,
    required this.id,
    required this.name,
    required this.description,
    required this.isBand,
    this.city,
    this.country,
    this.gender,
    this.age,
  });
}
