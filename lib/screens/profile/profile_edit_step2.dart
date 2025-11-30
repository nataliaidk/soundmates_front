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
      default:
        return Icons.label_outline;
    }
  }

  Widget _buildTags(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (widget.tagOptions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Select tags',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getAdaptiveGrey(context, lightShade: 100, darkShade: 850),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No tags available',
              style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
            ),
          ),
        ],
      );
    }

    final categories = widget.tagOptions.keys.toList();
    final accentColor = AppColors.accentPurple;
    final containerColor = isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft;
    final borderColor = isDark ? AppColors.accentPurple.withOpacity(0.3) : AppColors.accentPurple.withOpacity(0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Select tags',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...categories.map((cat) {
          final selectedSet = widget.selectedTags[cat] ?? {};
          final options = widget.tagOptions[cat] ?? [];
          final selectedOptions = options.where((o) => selectedSet.contains(o['value'])).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_categoryIcon(cat), color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _humanize(cat),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getAdaptiveText(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => widget.onShowTagPicker(cat),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: selectedOptions.isEmpty
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: selectedOptions.isEmpty
                            ? Text(
                                'Tap to select',
                                style: TextStyle(
                                  color: isDark ? AppColors.accentPurple.withOpacity(0.7) : AppColors.accentPurple.withOpacity(0.5),
                                  fontSize: 15,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedOptions.map((option) {
                                  final label = option['label']?.toString() ?? option['value'].toString();
                                  final value = option['value'];
                                  return Chip(
                                    label: Text(label),
                                    backgroundColor: AppColors.accentPurple,
                                    labelStyle: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    deleteIcon: const Icon(Icons.close, size: 18),
                                    deleteIconColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    onDeleted: () => widget.onRemoveTag(cat, value),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.keyboard_arrow_down, color: accentColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBandMembersSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Band members',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (widget.bandMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getAdaptiveGrey(context, lightShade: 100, darkShade: 850),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No members added yet',
              style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
            ),
          )
        else
          ...widget.bandMembers.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    '${m.name} (${m.age} y/o)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _bandRoleName(m.bandRoleId),
                    style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 700, darkShade: 300)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: AppColors.accentPurple),
                        onPressed: () => widget.onEditBandMember(m),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: isDark ? const Color(0xFFE57373) : Colors.red),
                        onPressed: () => widget.onRemoveBandMember(m),
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add member'),
            onPressed: widget.onAddBandMember,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentPurple,
              side: BorderSide(color: AppColors.accentPurple, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Profile photo circle at the top
        Center(
          child: GestureDetector(
            onTap: widget.onPickProfilePhoto,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentPurple, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                    backgroundImage: widget.pickedProfilePhoto?.bytes != null
                        ? MemoryImage(widget.pickedProfilePhoto!.bytes!)
                        : null,
                    child: widget.pickedProfilePhoto?.bytes == null
                        ? Icon(Icons.person, size: 60, color: AppColors.accentPurple.withOpacity(0.5))
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
                      border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: widget.onPickProfilePhoto,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                if (widget.pickedProfilePhoto != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFE57373) : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: widget.onRemoveProfilePhoto,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap to ${widget.pickedProfilePhoto == null ? 'add' : 'change'} profile photo',
          style: TextStyle(fontSize: 12, color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
        ),
        const SizedBox(height: 24),
        StatefulBuilder(
          builder: (context, setStateLocal) {
            return TextFormField(
              controller: widget.descController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateDescription(value ?? ''),
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Tell us about yourself...',
                helperText: '${widget.descController.text.length}/500 characters',
                filled: true,
                fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
              maxLines: 4,
              onChanged: (value) {
                setStateLocal(() {}); // Trigger rebuild to update character count
              },
            );
          },
        ),
        _buildTags(context),
        if (widget.isBand) _buildBandMembersSection(context, isDark),
        const SizedBox(height: 24),
        
        // Back and Complete buttons
        Row(
          children: [
            if (widget.showBackButton) ...[
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: widget.onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accentPurple, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: AppColors.accentPurple,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (widget.status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFB71C1C) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.status,
              style: TextStyle(color: isDark ? const Color(0xFFFFCDD2) : const Color(0xFFC62828)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
