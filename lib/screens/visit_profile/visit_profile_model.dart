import '../../api/models.dart';

/// Model reprezentujący stan całego ekranu Visit Profile.
/// Zawiera dane gotowe do wyświetlenia, bez potrzeby dalszego przetwarzania.
class VisitProfileViewModel {
  final OtherUserProfileDto profile;
  final String locationString;
  final String? profileImageUrl; // <--- NOWE POLE
  final Map<String, List<String>> groupedTags;
  final List<VisitProfileMediaItem> galleryItems;
  final VisitProfileAudioTrack? mainAudioTrack;

  VisitProfileViewModel({
    required this.profile,
    required this.locationString,
    this.profileImageUrl, // <--- W KONSTRUKTORZE
    required this.groupedTags,
    required this.galleryItems,
    this.mainAudioTrack,
  });
}

/// Odpowiednik enum _MediaType z oryginalnego pliku.
enum VisitProfileMediaType {
  image,
  audio,
  video
}

/// Odpowiednik klasy _MediaItem z oryginalnego pliku.
/// Używana głównie w siatce galerii.
class VisitProfileMediaItem {
  final VisitProfileMediaType type;
  final String url;      // Pełny URL (absolute)
  final String fileName; // Używane do rozpoznania typu pliku lub wyświetlenia nazwy

  VisitProfileMediaItem({
    required this.type,
    required this.url,
    required this.fileName,
  });
}

/// Klasa pomocnicza dla odtwarzacza w zakładce "Details".
/// Zbiera dane, które w oryginale były rozrzucone po metodzie _buildInformationTab.
class VisitProfileAudioTrack {
  final String title;    // np. nazwa pliku
  final String artist;   // imię użytkownika
  final String? coverUrl; // URL do zdjęcia profilowego (okładki)
  final String fileUrl;   // URL do pliku audio

  VisitProfileAudioTrack({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.fileUrl,
  });
}
//fix