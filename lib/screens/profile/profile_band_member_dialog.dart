import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../api/models.dart';
import '../../utils/validators.dart';
import '../../theme/app_design_system.dart';

/// Shows a dialog to add or edit a band member
Future<BandMemberDto?> showBandMemberDialog({
  required BuildContext context,
  required List<BandRoleDto> bandRoles,
  BandMemberDto? member,
}) async {
  final nameCtrl = TextEditingController(text: member?.name ?? '');
  final ageCtrl = TextEditingController(text: member?.age.toString() ?? '');
  String? nameError;
  String? ageError;
  String? roleError;

  // Preselect current role (if editing)
  BandRoleDto? selectedRole;
  if (member != null && bandRoles.isNotEmpty) {
    selectedRole = bandRoles.firstWhere(
      (r) => r.id == member.bandRoleId,
      orElse: () => bandRoles.first,
    );
  }

  return await showDialog<BandMemberDto>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppTheme.getAdaptiveSurface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            member == null ? 'Add Band Member' : 'Edit Band Member',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.getAdaptiveText(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: nameError,
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.accentPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                ),
                onChanged: (_) {
                  if (nameError != null) {
                    setDialogState(() => nameError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageCtrl,
                decoration: InputDecoration(
                  labelText: 'Age',
                  errorText: ageError,
                  prefixIcon: Icon(Icons.cake_outlined, color: AppColors.accentPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                  helperText: 'Must be between 13 and 100',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (ageError != null) {
                    setDialogState(() => ageError = null);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<BandRoleDto>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  errorText: roleError,
                  prefixIcon: Icon(Icons.music_note, color: AppColors.accentPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
                  ),
                ),
                items: bandRoles.map(
                  (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                ).toList(),
                onChanged: (v) {
                  setDialogState(() {
                    selectedRole = v;
                    roleError = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                // Validate all fields
                final nameValidation = validateBandMemberName(nameCtrl.text);
                final ageValidation = validateBandMemberAge(ageCtrl.text);
                final roleValidation = selectedRole == null ? 'Please select a role' : null;

                if (nameValidation != null || ageValidation != null || roleValidation != null) {
                  setDialogState(() {
                    nameError = nameValidation;
                    ageError = ageValidation;
                    roleError = roleValidation;
                  });
                  return;
                }

                final dto = BandMemberDto(
                  id: member?.id ?? const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  age: int.parse(ageCtrl.text),
                  displayOrder: 0,
                  bandId: 'TEMP',
                  bandRoleId: selectedRole!.id,
                );
                Navigator.pop(ctx, dto);
              },
              child: Text(member == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    ),
  );
}

/// Returns an appropriate icon for a band role name
IconData getIconForRoleName(String roleName) {
  final n = roleName.toLowerCase();
  
  if (n.contains('backing') && n.contains('vocal')) return Icons.mic;
  if (n.contains('vocalist') || n.contains('vocal') || n.contains('singer')) return Icons.mic;
  if (n.contains('double bass')) return Icons.queue_music;
  if (n == 'bassist' || n.contains('bassist')) return Icons.queue_music;
  if (n.contains('guitarist') || n.contains('guitar')) return Icons.queue_music;
  if (n.contains('keyboardist') || n.contains('keyboard') || n.contains('piano') || n.contains('keys')) return Icons.piano;
  if (n.contains('turntablist')) return Icons.headset;
  if (n.contains('synth')) return Icons.graphic_eq;
  if (n.contains('brass')) return Icons.audiotrack;
  if (n.contains('cellist') || n.contains('cello')) return Icons.queue_music;
  if (n.contains('violinist') || n.contains('violin')) return Icons.audiotrack;
  if (n.contains('woodwind')) return Icons.audiotrack;
  if (n.contains('drummer') || n.contains('drum')) return Icons.music_note;
  if (n.contains('other')) return Icons.help_outline;
  if (n.contains('producer') || n.contains('production')) return Icons.equalizer;
  if (n.contains('dj')) return Icons.headset;
  if (n.contains('music')) return Icons.music_note;
  
  return Icons.person;
}
