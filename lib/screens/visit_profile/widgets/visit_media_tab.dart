import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../visit_profile_model.dart';

class VisitMediaTab extends StatelessWidget {
  final List<VisitProfileMediaItem> items;

  const VisitMediaTab({super.key, required this.items});

  // Stała kolorów z oryginału
  static const Color _accentPurple = Color(0xFF7B51D3);

  @override
  Widget build(BuildContext context) {
    // 1. Stan pusty (Empty State)
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No media shared yet',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    // 2. Siatka multimediów
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _MediaGridItem(item: item, accentColor: _accentPurple);
      },
    );
  }
}

/// Pojedynczy kafel w siatce galerii
class _MediaGridItem extends StatelessWidget {
  final VisitProfileMediaItem item;
  final Color accentColor;

  const _MediaGridItem({
    required this.item,
    required this.accentColor,
  });

  Future<void> _openMedia() async {
    try {
      final uri = Uri.parse(item.url);
      // launchUrl wymaga konfiguracji w AndroidManifest/Info.plist,
      // zakładam że jest to już zrobione w projekcie.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch url: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openMedia,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Warstwa tła (Zdjęcie lub Ikona typu)
              if (item.type == VisitProfileMediaType.image)
                Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                )
              else
                Container(
                  color: const Color(0xFFF0F2F5),
                  child: Icon(
                    item.type == VisitProfileMediaType.audio
                        ? Icons.audiotrack
                        : Icons.videocam,
                    color: accentColor,
                    size: 32,
                  ),
                ),

              // Warstwa nakładki (Ikona Play dla audio/wideo)
              if (item.type != VisitProfileMediaType.image)
                Positioned.fill(
                  child: Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
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