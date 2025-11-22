import 'package:flutter/material.dart';
import '../visit_profile_model.dart';

class VisitInfoTab extends StatelessWidget {
  final VisitProfileViewModel data;

  const VisitInfoTab({super.key, required this.data});

  // Kolory przeniesione z oryginału dla zachowania spójności wizualnej
  static const Color _primaryDark = Color(0xFF1A1A1A);
  static const Color _accentPurple = Color(0xFF7B51D3);

  @override
  Widget build(BuildContext context) {
    final orderedCategories = [
      'Instruments',
      'Genres',
      'Activity',
      'Collaboration type'
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        const SizedBox(height: 10),

        // Sekcja About
        _buildSectionTitle('About'),
        const SizedBox(height: 8),
        Text(
          data.profile.description.isNotEmpty
              ? data.profile.description
              : "Looking for someone to jam with occasionally and for some touring opportunity!",
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.grey[800],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Sekcja Tagów (Generowana dynamicznie)
        for (final category in orderedCategories)
          if (data.groupedTags.containsKey(category) &&
              data.groupedTags[category]!.isNotEmpty) ...[
            _buildSectionTitle(category),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.groupedTags[category]!
                  .map((tag) => _buildModernChip(tag))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],

        // Sekcja Odtwarzacza Muzyki
        if (data.mainAudioTrack != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _MusicPlayerCard(
              track: data.mainAudioTrack!,
              accentColor: _accentPurple,
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildModernChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0E0).withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// Wydzielony widget odtwarzacza, aby nie zaśmiecać głównego widoku
class _MusicPlayerCard extends StatelessWidget {
  final VisitProfileAudioTrack track;
  final Color accentColor;

  const _MusicPlayerCard({
    required this.track,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2D3E), Color(0xFF1F2029)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          // Górny wiersz: Okładka + Tytuł + Serduszko
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: track.coverUrl != null
                      ? Image.network(
                    track.coverUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 56,
                    height: 56,
                    color: Colors.white10,
                    child: const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {}, // Placeholder action
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pasek postępu (Fake)
          Stack(
            children: [
              Container(height: 4, color: Colors.white12),
              Container(height: 4, width: 100, color: accentColor),
            ],
          ),
          const SizedBox(height: 16),

          // Przyciski sterowania
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.shuffle, color: Colors.white54, size: 20),
              const Icon(Icons.skip_previous, color: Colors.white, size: 28),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.black, size: 28),
              ),
              const Icon(Icons.skip_next, color: Colors.white, size: 28),
              const Icon(Icons.repeat, color: Colors.white54, size: 20),
            ],
          )
        ],
      ),
    );
  }
}