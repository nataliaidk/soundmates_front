import 'package:flutter/material.dart';
import '../visit_profile_model.dart';
import '../../../theme/app_design_system.dart';
import '../../shared/native_audio_player.dart';
import '../../../api/api_client.dart';
import '../../../api/models.dart';

class VisitInfoTab extends StatelessWidget {
  final VisitProfileViewModel data;
  final ApiClient? api;
  final String? userId;

  const VisitInfoTab({
    super.key,
    required this.data,
    this.api,
    this.userId,
  });

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
        if (data.profile.description.isNotEmpty) ...[
          _buildSectionTitle(context, 'About'),
          const SizedBox(height: 8),
          Text(
            data.profile.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? AppColors.textWhite : AppColors.textDarkGrey,
            ),
          ),
        ],
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
            _buildSectionTitle(context, category),
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
          _buildSectionTitle(context, 'Band Members'),
          const SizedBox(height: 12),
          ...data.bandMembers.map((member) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark
                        ? AppColors.surfaceDarkAlt
                        : AppColors.avatarBackground,
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
                          '${member.name}${member.age.isNotEmpty ? ', ${member.age}' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? AppColors.textWhite : Colors.black,
                          ),
                        ),
                        if (member.role.isNotEmpty)
                          Text(
                            member.role,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textWhite70
                                  : AppColors.textSecondary,
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

        // Report Button Section
        if (api != null && userId != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 12,
            ),
            child: Center(
              child: SizedBox(
                width: (MediaQuery.of(context).size.width - 48) * 0.5,
                child: GestureDetector(
                  onTap: () => _showReportDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.flag,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'REPORT THIS USER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showReportDialog(BuildContext context) {
    if (api == null || userId == null) return;

    String selectedReason = 'Inappropriate Content';
    final List<String> reasons = [
      'Inappropriate Content',
      'Spam',
      'Fake Profile',
      'Harassment',
      'Other',
    ];
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
              title: Text(
                'Report User',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason',
                      style: TextStyle(
                        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedReason,
                      dropdownColor: isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: reasons.map((String reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedReason = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: TextStyle(
                        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: TextStyle(
                        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Please provide more details...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textWhite.withAlpha(128)
                              : AppColors.textPrimary.withAlpha(128),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    descriptionController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please provide a description'),
                        ),
                      );
                      return;
                    }

                    try {
                      final dto = ReportUserDto(
                        reportedUserId: userId!,
                        reason: selectedReason,
                        description: descriptionController.text.trim(),
                      );

                      final response = await api!.reportUser(dto);

                      if (!context.mounted) return;
                      descriptionController.dispose();
                      Navigator.of(context).pop();

                      if (response.statusCode == 200 || response.statusCode == 201) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report submitted successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit report: ${response.statusCode}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      descriptionController.dispose();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error submitting report: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Submit Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        color: isDark
            ? AppColors.accentPurpleSoft
            : AppColors.textPurpleVibrant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildModernChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.accentPurpleDark : AppColors.accentPurple,
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
