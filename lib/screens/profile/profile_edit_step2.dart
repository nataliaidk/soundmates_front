import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/models.dart';

/// Step 2 of profile editing: Tags, Description, Band Members, Profile Photo
class ProfileEditStep2 extends StatelessWidget {
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

  String _humanize(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  String _bandRoleName(String bandRoleId) {
    for (final r in bandRoles) {
      if (r.id == bandRoleId) return r.name;
    }
    return bandRoleId;
  }

  Widget _buildTags() {
    if (tagOptions.isEmpty) {
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No tags available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    final categories = tagOptions.keys.toList();
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
          final selectedSet = selectedTags[cat] ?? {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  _humanize(cat),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              InkWell(
                onTap: () => onShowTagPicker(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedSet.isEmpty
                            ? 'Tap to select'
                            : '${selectedSet.length} selected',
                        style: TextStyle(
                          color: selectedSet.isEmpty ? Colors.grey.shade500 : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              if (selectedSet.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedSet.map((val) {
                    final found = tagOptions[cat]!.firstWhere(
                      (o) => o['value'] == val,
                      orElse: () => {'label': val.toString()},
                    );
                    final label = found['label']?.toString() ?? val.toString();
                    return Chip(
                      label: Text(label),
                      backgroundColor: Colors.deepPurple.shade100,
                      deleteIconColor: Colors.deepPurple.shade700,
                      onDeleted: () => onRemoveTag(cat, val),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildBandMembersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Band members',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (bandMembers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No members added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ...bandMembers.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
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
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.deepPurple.shade400),
                        onPressed: () => onEditBandMember(m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => onRemoveBandMember(m),
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
            onPressed: onAddBandMember,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple.shade400,
              side: BorderSide(color: Colors.deepPurple.shade400, width: 2),
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
    return Column(
      children: [
        // Profile photo circle at the top
        Center(
          child: GestureDetector(
            onTap: onPickProfilePhoto,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.deepPurple.shade400, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple.shade50,
                    backgroundImage: pickedProfilePhoto?.bytes != null
                        ? MemoryImage(pickedProfilePhoto!.bytes!)
                        : null,
                    child: pickedProfilePhoto?.bytes == null
                        ? Icon(Icons.person, size: 60, color: Colors.deepPurple.shade200)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: onPickProfilePhoto,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                if (pickedProfilePhoto != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        onPressed: onRemoveProfilePhoto,
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
          'Tap to ${pickedProfilePhoto == null ? 'add' : 'change'} profile photo',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: descController,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Tell us about yourself...',
            filled: true,
            fillColor: Colors.deepPurple.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
          maxLines: 4,
        ),
        _buildTags(),
        if (isBand) _buildBandMembersSection(context),
        const SizedBox(height: 24),
        
        // Back and Complete buttons
        Row(
          children: [
            if (showBackButton) ...[
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.deepPurple.shade400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: TextStyle(
                      color: Colors.deepPurple.shade400,
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
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade400,
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
        
        if (status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
