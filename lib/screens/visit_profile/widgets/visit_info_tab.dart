import 'package:flutter/material.dart';
import '../visit_profile_model.dart';
import '../../../theme/app_design_system.dart';
import '../../shared/native_audio_player.dart';

class VisitInfoTab extends StatelessWidget {
  final VisitProfileViewModel data;

  const VisitInfoTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final orderedCategories = [
      'Instruments',
      'Genres',
      'Activity',
      'Collaboration type',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      children: [
        const SizedBox(height: 10),

        // About Section
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
        const SizedBox(height: 16),

        // Native Audio Player
        if (data.audioTracks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: NativeAudioPlayer(
              tracks: data.audioTracks
                  .map(
                    (track) =>
                        AudioTrack(title: track.title, fileUrl: track.fileUrl),
                  )
                  .toList(),
              accentColor: AppColors.accentPurple,
            ),
          ),

        // Tags Sections
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
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimaryAlt,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
