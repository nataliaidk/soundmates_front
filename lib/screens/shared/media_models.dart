/// Shared data models for media items used across different screens

/// Media type enumeration
enum MediaType { image, audio, video }

/// Media item model containing essential media information
class MediaItem {
  final MediaType type;
  final String url; // Full absolute URL
  final String fileName; // Used for file type recognition or display

  MediaItem({required this.type, required this.url, required this.fileName});
}
