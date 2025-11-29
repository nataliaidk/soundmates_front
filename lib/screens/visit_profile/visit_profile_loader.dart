import 'dart:convert';
import '../../api/api_client.dart';
import '../../api/models.dart';
import 'visit_profile_model.dart';

class VisitProfileLoader {
  final ApiClient api;

  VisitProfileLoader(this.api);

  Future<VisitProfileViewModel> loadData(String userId) async {
    try {
      // 1. Pobierz profil
      final profile = await api.getOtherUserProfile(userId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // 2. Zmienne na słowniki
      List<TagDto> allTags = [];
      List<TagCategoryDto> allCategories = [];
      List<CountryDto> allCountries = [];
      List<CityDto> relevantCities = [];

      // 3. Pobierz dane słownikowe
      try {
        final responses = await Future.wait([
          api.getTags(),
          api.getTagCategories(),
          api.getCountries(),
          if (profile.country != null)
            api.getCities(profile.country!)
          else
            Future.value(null),
        ]);

        if (responses[0] != null && responses[0]!.statusCode == 200) {
          allTags = (jsonDecode(responses[0]!.body) as List)
              .map((e) => TagDto.fromJson(e))
              .toList();
        }
        if (responses[1] != null && responses[1]!.statusCode == 200) {
          allCategories = (jsonDecode(responses[1]!.body) as List)
              .map((e) => TagCategoryDto.fromJson(e))
              .toList();
        }
        if (responses[2] != null && responses[2]!.statusCode == 200) {
          allCountries = (jsonDecode(responses[2]!.body) as List)
              .map((e) => CountryDto.fromJson(e))
              .toList();
        }
        if (responses.length > 3 &&
            responses[3] != null &&
            responses[3]!.statusCode == 200) {
          relevantCities = (jsonDecode(responses[3]!.body) as List)
              .map((e) => CityDto.fromJson(e))
              .toList();
        }
      } catch (e) {
        print('Warning: Failed to load auxiliary data: $e');
      }

      // 4. Przetwarzanie
      final locationStr = _resolveLocationString(
        profile,
        allCountries,
        relevantCities,
      );
      final groupedTags = _groupTags(profile.tags, allTags, allCategories);

      // Tu używamy nowych nazw klas z modelu:
      final galleryItems = _prepareGalleryItems(profile);
      final audioTracks = _prepareAudioTracks(profile);
      final bandMembers = _prepareBandMembers(profile);
      String? profilePicUrl;
      if (profile.profilePictures.isNotEmpty) {
        profilePicUrl = profile.profilePictures.first.getAbsoluteUrl(
          api.baseUrl,
        );
      }

      return VisitProfileViewModel(
        profile: profile,
        locationString: locationStr,
        profileImageUrl: profilePicUrl,
        groupedTags: groupedTags,
        galleryItems: galleryItems,
        audioTracks: audioTracks,
        bandMembers: bandMembers,
      );
    } catch (e) {
      throw Exception('Failed to load profile data: $e');
    }
  }

  // --- Metody pomocnicze ---

  String _resolveLocationString(
    OtherUserProfileDto profile,
    List<CountryDto> countries,
    List<CityDto> cities,
  ) {
    String? countryName;
    String? cityName;

    if (profile.country != null) {
      final foundCountry = countries.firstWhere(
        (c) => c.id == profile.country,
        orElse: () => CountryDto(id: '', name: ''),
      );
      if (foundCountry.id.isNotEmpty) countryName = foundCountry.name;
    }

    if (profile.city != null) {
      final foundCity = cities.firstWhere(
        (c) => c.id == profile.city,
        orElse: () => CityDto(id: '', name: ''),
      );
      if (foundCity.id.isNotEmpty) cityName = foundCity.name;
    }

    final parts = [
      cityName,
      countryName,
    ].where((s) => s != null && s.isNotEmpty).toList();
    return parts.join(', ');
  }

  Map<String, List<String>> _groupTags(
    List<String> profileTagIds,
    List<TagDto> allTags,
    List<TagCategoryDto> allCategories,
  ) {
    final Map<String, List<String>> grouped = {};
    final catIdToName = {for (var c in allCategories) c.id: c.name};
    final tagIdToTag = {for (var t in allTags) t.id: t};

    for (final tId in profileTagIds) {
      final tagObj = tagIdToTag[tId];
      if (tagObj != null && tagObj.tagCategoryId != null) {
        final catName = catIdToName[tagObj.tagCategoryId] ?? 'Other';
        grouped.putIfAbsent(catName, () => []);
        grouped[catName]!.add(tagObj.name);
      }
    }
    return grouped;
  }

  // Zwraca listę VisitProfileMediaItem (zgodnie z modelem)
  List<VisitProfileMediaItem> _prepareGalleryItems(
    OtherUserProfileDto profile,
  ) {
    final List<VisitProfileMediaItem> items = [];

    // Zdjęcia
    for (final pic in profile.profilePictures) {
      items.add(
        VisitProfileMediaItem(
          type: VisitProfileMediaType.image,
          url: pic.getAbsoluteUrl(api.baseUrl),
          fileName: pic.fileUrl.split('/').last,
        ),
      );
    }

    // Muzyka / Wideo w galerii
    if (profile.musicSamples != null) {
      for (final sample in profile.musicSamples!) {
        final fileName = sample.fileUrl.split('/').last;
        final lowerName = fileName.toLowerCase();
        final isAudio =
            lowerName.endsWith('.mp3') ||
            lowerName.endsWith('.wav') ||
            lowerName.endsWith('.m4a');

        items.add(
          VisitProfileMediaItem(
            type: isAudio
                ? VisitProfileMediaType.audio
                : VisitProfileMediaType.video,
            url: sample.getAbsoluteUrl(api.baseUrl),
            fileName: fileName,
          ),
        );
      }
    }
    return items;
  }

  // Zwraca listę VisitProfileAudioTrack (zgodnie z modelem)
  List<VisitProfileAudioTrack> _prepareAudioTracks(
    OtherUserProfileDto profile,
  ) {
    final List<VisitProfileAudioTrack> tracks = [];

    if (profile.musicSamples != null && profile.musicSamples!.isNotEmpty) {
      final userName = profile.name ?? 'Unknown Artist';
      final coverUrl = profile.profilePictures.isNotEmpty
          ? profile.profilePictures.first.getAbsoluteUrl(api.baseUrl)
          : null;

      for (int i = 0; i < profile.musicSamples!.length; i++) {
        final sample = profile.musicSamples![i];
        final index = i + 1; // 1-based indexing

        tracks.add(
          VisitProfileAudioTrack(
            index: index,
            title: '$userName audio $index',
            artist: userName,
            coverUrl: coverUrl,
            fileUrl: sample.getAbsoluteUrl(api.baseUrl),
          ),
        );
      }
    }

    return tracks;
  }

  // Zwraca listę BandMemberInfo (zgodnie z modelem)
  List<BandMemberInfo> _prepareBandMembers(OtherUserProfileDto profile) {
    final List<BandMemberInfo> members = [];

    // Check if profile is a band and has band members
    if (profile is OtherUserProfileBandDto) {
      final bandProfile = profile as OtherUserProfileBandDto;
      if (bandProfile.bandMembers != null &&
          bandProfile.bandMembers!.isNotEmpty) {
        for (final member in bandProfile.bandMembers!) {
          members.add(
            BandMemberInfo(
              name: '${member.name}, ${member.age}',
              role: '', // BandMemberDto only has bandRoleId, not role name
              age: member.age.toString(),
            ),
          );
        }
      }
    }

    return members;
  }
}
