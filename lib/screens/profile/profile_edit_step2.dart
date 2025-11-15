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
          const SizedBox(height: 12),
          const Text('Select tags:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '(no tags available)',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    final categories = tagOptions.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Select tags:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...categories.map((cat) {
          final selectedSet = selectedTags[cat] ?? {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_humanize(cat), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => onShowTagPicker(cat),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Click to select',
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedSet.isEmpty
                              ? '(none selected)'
                              : '${selectedSet.length} selected',
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (selectedSet.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedSet.map((val) {
                    final found = tagOptions[cat]!.firstWhere(
                      (o) => o['value'] == val,
                      orElse: () => {'label': val.toString()},
                    );
                    final label = found['label']?.toString() ?? val.toString();
                    return InputChip(
                      label: Text(label),
                      onDeleted: () => onRemoveTag(cat, val),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
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
        const Text('Band members', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (bandMembers.isEmpty)
          const Text('(no members added)', style: TextStyle(color: Colors.grey)),
        ...bandMembers.map((m) => ListTile(
              title: Text('${m.name} (${m.age} y/o)'),
              subtitle: Text('Role: ${_bandRoleName(m.bandRoleId)} • Order: ${m.displayOrder}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => onEditBandMember(m),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => onRemoveBandMember(m),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add member'),
          onPressed: onAddBandMember,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: descController,
          decoration: const InputDecoration(labelText: 'Description'),
          maxLines: 3,
        ),
        _buildTags(),
        if (isBand) _buildBandMembersSection(context),
        const SizedBox(height: 12),
        
        // Profile photo (optional)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile photo (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onPickProfilePhoto,
                    icon: const Icon(Icons.photo),
                    label: const Text('Choose photo'),
                  ),
                  const SizedBox(width: 12),
                  if (pickedProfilePhoto != null)
                    Expanded(
                      child: Row(
                        children: [
                          if (pickedProfilePhoto?.bytes != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                pickedProfilePhoto!.bytes!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedProfilePhoto!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: onRemoveProfilePhoto,
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'No file selected',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Back and Complete buttons
        Row(
          children: [
            if (showBackButton) ...[
              ElevatedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: onComplete,
                child: const Text('Complete Profile'),
              ),
            ),
          ],
        ),
        
        if (status.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
