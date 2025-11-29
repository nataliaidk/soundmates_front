import 'package:flutter/material.dart';
import '../visit_profile_model.dart';
import '../../shared/media_models.dart';
import '../../shared/instagram_post_viewer.dart';
import '../../shared/video_thumbnail.dart';
import '../../../theme/app_design_system.dart';


class VisitMediaTab extends StatelessWidget {
  final List<VisitProfileMediaItem> items;

  const VisitMediaTab({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: isDark ? AppColors.textWhite70 : AppColors.textGrey,
            ),
            SizedBox(height: 16),
            Text(
              'No media shared yet',
              style: TextStyle(color: isDark ? AppColors.textWhite70 : AppColors.textGrey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _MediaGridItem(
          item: items[index],
          onTap: () {
            // Convert VisitProfileMediaItem to MediaItem
            final mediaItems = items.map((item) {
              MediaType type;
              switch (item.type) {
                case VisitProfileMediaType.image:
                  type = MediaType.image;
                  break;
                case VisitProfileMediaType.audio:
                  type = MediaType.audio;
                  break;
                case VisitProfileMediaType.video:
                  type = MediaType.video;
                  break;
              }
              return MediaItem(
                url: item.url,
                type: type,
                fileName: item.url.split('/').last,
              );
            }).toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InstagramPostViewer(
                  items: mediaItems,
                  initialIndex: index,
                  accentColor: AppColors.accentPurpleBlue,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MediaGridItem extends StatelessWidget {
  final VisitProfileMediaItem item;
  final VoidCallback onTap;

  const _MediaGridItem({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Layer
              if (item.type == VisitProfileMediaType.image)
                Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              else if (item.type == VisitProfileMediaType.video)
                VideoThumbnail(videoUrl: item.url)
              else
                // Audio placeholder with gradient and music notes
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withAlpha(179),
                        accentColor.withAlpha(102),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background music notes pattern
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withAlpha(77),
                          size: 24,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withAlpha(77),
                          size: 24,
                        ),
                      ),
                      // Center large music note
                      Center(
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 56,
                        ),
                      ),
                    ],
                  ),
                ),

              // Play Icon Overlay for video/audio
              if (item.type != VisitProfileMediaType.image)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(51),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
