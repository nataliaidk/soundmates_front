import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../api/models.dart';

/// Shows a dialog to add or edit a band member
Future<BandMemberDto?> showBandMemberDialog({
  required BuildContext context,
  required List<BandRoleDto> bandRoles,
  BandMemberDto? member,
}) async {
  final nameCtrl = TextEditingController(text: member?.name ?? '');
  final ageCtrl = TextEditingController(text: member?.age.toString() ?? '');

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
          title: Text(member == null ? 'Add band member' : 'Edit band member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: ageCtrl,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BandRoleDto>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: bandRoles.map(
                  (r) => DropdownMenuItem(value: r, child: Text(r.name)),
                ).toList(),
                onChanged: (v) => setDialogState(() => selectedRole = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedRole == null) return;
                final dto = BandMemberDto(
                  id: member?.id ?? const Uuid().v4(),
                  name: nameCtrl.text.trim(),
                  age: int.tryParse(ageCtrl.text) ?? 0,
                  displayOrder: 0,
                  bandId: 'TEMP',
                  bandRoleId: selectedRole!.id,
                );
                Navigator.pop(ctx, dto);
              },
              child: const Text('OK'),
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
