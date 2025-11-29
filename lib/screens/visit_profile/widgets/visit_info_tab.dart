import 'package:flutter/material.dart';
import '../visit_profile_model.dart';
import '../../../theme/app_design_system.dart';
import '../../shared/native_audio_player.dart';

class VisitInfoTab extends StatelessWidget {
  final VisitProfileViewModel data;

  const VisitInfoTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            fontSize: 14,
            height: 1.45,
            color: isDark? AppColors.textWhite : AppColors.textDarkGrey,
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
                  .map((tag) => _buildModernChip(context, tag))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        // Band Members Section
        if (data.bandMembers.isNotEmpty) ...[
          _buildSectionTitle('Band Members'),
          const SizedBox(height: 12),
          ...data.bandMembers.map((member) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.avatarBackground,
                    child: Icon(
                      Icons.person,
                      color: AppColors.accentPurpleDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (member.role.isNotEmpty)
                          Text(
                            member.role,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark? AppColors.textWhite : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPurpleVibrant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildModernChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
