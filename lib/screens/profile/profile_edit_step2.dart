import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/models.dart';
import '../../theme/app_design_system.dart';
import '../../utils/validators.dart';

/// Step 2 of profile editing: Tags, Description, Band Members, Profile Photo
class ProfileEditStep2 extends StatefulWidget {
  final TextEditingController descController;
  final Map<String, List<Map<String, dynamic>>> tagOptions;
  final Map<String, Set<dynamic>> selectedTags;
  final bool isBand;
  final List<BandMemberDto> bandMembers;
  final List<BandRoleDto> bandRoles;
  final PlatformFile? pickedProfilePhoto;
  final VoidCallback onBack;
  final VoidCallback onComplete;
  final Function(String) onShowTagPicker;
  final Function(String, dynamic) onRemoveTag;
  final VoidCallback onAddBandMember;
  final Function(BandMemberDto) onEditBandMember;
  final Function(BandMemberDto) onRemoveBandMember;
  final VoidCallback onPickProfilePhoto;
  final VoidCallback onRemoveProfilePhoto;
  final String status;
  final bool showBackButton;

  const ProfileEditStep2({
    super.key,
    required this.descController,
    required this.tagOptions,
    required this.selectedTags,
    required this.isBand,
    required this.bandMembers,
    required this.bandRoles,
    required this.pickedProfilePhoto,
    required this.onBack,
    required this.onComplete,
    required this.onShowTagPicker,
    required this.onRemoveTag,
    required this.onAddBandMember,
    required this.onEditBandMember,
    required this.onRemoveBandMember,
    required this.onPickProfilePhoto,
    required this.onRemoveProfilePhoto,
    required this.status,
    this.showBackButton = true,
  });

  @override
  State<ProfileEditStep2> createState() => _ProfileEditStep2State();
}

class _ProfileEditStep2State extends State<ProfileEditStep2> {
  String _humanize(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  String _bandRoleName(String bandRoleId) {
    for (final r in widget.bandRoles) {
      if (r.id == bandRoleId) return r.name;
    }
    return bandRoleId;
  }

  IconData _categoryIcon(String categoryKey) {
    switch (categoryKey.toLowerCase()) {
      case 'activity':
        return Icons.star;
      case 'instruments':
        return Icons.music_note;
      case 'band status':
        return Icons.info_outline;
      case 'genres':
        return Icons.library_music;
      default:
        return Icons.label_outline;
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accentPurple,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTags(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.tagOptions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('TAGS'),
          const SizedBox(height: 12),
          _buildCard(
            context,
            isDark,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tags available',
                style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
              ),
            ),
          ),
        ],
      );
    }

    final categories = widget.tagOptions.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TAGS'),
        const SizedBox(height: 12),
        ...categories.map((cat) {
          final selectedSet = widget.selectedTags[cat] ?? {};
          final options = widget.tagOptions[cat] ?? [];
          final selectedOptions = options.where((o) => selectedSet.contains(o['value'])).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCard(
              context,
              isDark,
              child: InkWell(
                onTap: () => widget.onShowTagPicker(cat),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _categoryIcon(cat),
                            color: AppColors.accentPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _humanize(cat).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.add_circle_outline,
                            color: AppColors.accentPurple,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedOptions.isEmpty)
                        Text(
                          'Tap to select ${cat.toLowerCase()}',
                          style: TextStyle(
                            color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                            fontSize: 14,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedOptions.map((option) {
                            final label = option['label']?.toString() ?? option['value'].toString();
                            final value = option['value'];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accentPurple,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => widget.onRemoveTag(cat, value),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBandMembersSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BAND MEMBERS'),
        const SizedBox(height: 12),
        _buildCard(
          context,
          isDark,
          child: Column(
            children: [
              if (widget.bandMembers.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 48,
                        color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No members added yet',
                        style: TextStyle(
                          color: AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...widget.bandMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final m = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppTheme.getAdaptiveGrey(context, lightShade: 200, darkShade: 800),
                        ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentPurple.withOpacity(0.15),
                          child: Icon(
                            Icons.person,
                            color: AppColors.accentPurple,
                          ),
                        ),
                        title: Text(
                          m.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getAdaptiveText(context),
                          ),
                        ),
                        subtitle: Text(
                          '${_bandRoleName(m.bandRoleId)} • ${m.age} years old',
                          style: TextStyle(
                            color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                color: AppColors.accentPurple,
                                size: 20,
                              ),
                              onPressed: () => widget.onEditBandMember(m),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: isDark ? const Color(0xFFE57373) : Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: () => widget.onRemoveBandMember(m),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Member'),
                    onPressed: widget.onAddBandMember,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentPurple,
                      side: BorderSide(color: AppColors.accentPurple, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile photo section
        _buildSectionHeader('PROFILE PHOTO'),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: widget.onPickProfilePhoto,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentPurple, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentPurple.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDark ? AppColors.surfaceDarkAlt : Colors.grey.shade100,
                    backgroundImage: widget.pickedProfilePhoto?.bytes != null
                        ? MemoryImage(widget.pickedProfilePhoto!.bytes!)
                        : null,
                    child: widget.pickedProfilePhoto?.bytes == null
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                          )
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                if (widget.pickedProfilePhoto != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: widget.onRemoveProfilePhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFFE57373) : Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            widget.pickedProfilePhoto == null ? 'Tap to add photo' : 'Tap to change photo',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Description section
        _buildSectionHeader('ABOUT YOU'),
        const SizedBox(height: 12),
        _buildCard(
          context,
          isDark,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setStateLocal) {
                return TextFormField(
                  controller: widget.descController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => validateDescription(value ?? ''),
                  style: TextStyle(
                    color: AppTheme.getAdaptiveText(context),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself, your music journey, and what you\'re looking for...',
                    hintStyle: TextStyle(
                      color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                      fontSize: 14,
                    ),
                    counterText: '${widget.descController.text.length}/500',
                    counterStyle: TextStyle(
                      color: AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500),
                      fontSize: 12,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 5,
                  maxLength: 500,
                  onChanged: (value) {
                    setStateLocal(() {}); // Update character count
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tags section
        _buildTags(context),
        const SizedBox(height: 8),

        // Band members section (only for bands)
        if (widget.isBand) ...[
          _buildBandMembersSection(context, isDark),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 8),

        // Action buttons
        Row(
          children: [
            if (widget.showBackButton) ...[
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentPurple,
                    side: BorderSide(color: AppColors.accentPurple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (widget.status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFFE57373) : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: isDark ? const Color(0xFFE57373) : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.status,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFFCDD2) : Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
