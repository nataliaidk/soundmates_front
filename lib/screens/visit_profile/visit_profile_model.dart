import '../../api/models.dart';

/// Model reprezentujący stan całego ekranu Visit Profile.
/// Zawiera dane gotowe do wyświetlenia, bez potrzeby dalszego przetwarzania.
class VisitProfileViewModel {
  final OtherUserProfileDto profile;
  final String locationString;
  final String? profileImageUrl;
  final Map<String, List<String>> groupedTags;
  final List<VisitProfileMediaItem> galleryItems;
  final List<VisitProfileAudioTrack> audioTracks;

  VisitProfileViewModel({
    required this.profile,
    required this.locationString,
    this.profileImageUrl,
    required this.groupedTags,
    required this.galleryItems,
    required this.audioTracks,
  });
}

/// Odpowiednik enum _MediaType z oryginalnego pliku.
enum VisitProfileMediaType { image, audio, video }

/// Odpowiednik klasy _MediaItem z oryginalnego pliku.
/// Używana głównie w siatce galerii.
class VisitProfileMediaItem {
  final VisitProfileMediaType type;
  final String url; // Pełny URL (absolute)
  final String
  fileName; // Używane do rozpoznania typu pliku lub wyświetlenia nazwy

  VisitProfileMediaItem({
    required this.type,
    required this.url,
    required this.fileName,
  });
}

/// Klasa pomocnicza dla odtwarzacza w zakładce "Details".
/// Zbiera dane, które w oryginale były rozrzucone po metodzie _buildInformationTab.
class VisitProfileAudioTrack {
  final int index; // Track number (1-based)
  final String title; // Formatted as "{userName} audio {index}"
  final String artist; // User name
  final String? coverUrl; // URL to profile picture (cover)
  final String fileUrl; // URL to audio file

  VisitProfileAudioTrack({
    required this.index,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.fileUrl,
  });
}
