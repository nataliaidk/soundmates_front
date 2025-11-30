import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import '../../theme/app_design_system.dart';
import '../../utils/validators.dart';
import 'profile_data_loader.dart';
import 'profile_tag_manager.dart';
import 'profile_band_member_dialog.dart';

/// Standalone screen for editing tags, description, band members, and profile photo
/// Used from profile view - no step navigation
class ProfileEditTagsScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;

  const ProfileEditTagsScreen({
    super.key,
    required this.api,
    required this.tokens,
  });

  @override
  State<ProfileEditTagsScreen> createState() => _ProfileEditTagsScreenState();
}

class _ProfileEditTagsScreenState extends State<ProfileEditTagsScreen> {
  final _desc = TextEditingController();
  
  late ProfileDataLoader _dataLoader;
  late ProfileTagManager _tagManager;
  
  String _status = '';
  bool _isBand = false;
  List<BandMemberDto> _bandMembers = [];
  List<BandRoleDto> _bandRoles = [];
  PlatformFile? _pickedProfilePhoto;
  List<ProfilePictureDto> _profilePictures = [];
  
  @override
  void initState() {
    super.initState();
    _dataLoader = ProfileDataLoader(widget.api);
    _tagManager = ProfileTagManager();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _status = 'Loading...');

    // Load band roles
    final roles = await _dataLoader.loadBandRoles();
    _bandRoles = roles;

    // Load profile first to get isBand value
    final profile = await _dataLoader.loadMyProfile();
    if (profile == null) {
      setState(() => _status = 'Failed to load profile');
      return;
    }

    // Parse profile to get isBand
    _desc.text = profile['description'] ?? '';
    _isBand = profile['isBand'] == true;

    // Load tag categories and tags with correct filter
    final categories = await _dataLoader.loadTagCategories();
    final tags = await _dataLoader.loadTags();
    _tagManager.initialize(
      categories: categories,
      tags: tags,
      filterForBand: _isBand,
    );

    // Set user tags
    _tagManager.setUserTags(
      profile['tagsIds'] is List
          ? (profile['tagsIds'] as List).map((t) => t.toString()).toList()
          : [],
    );
    _tagManager.populateSelectedForEdit();

    // Parse rest of profile
    _parseProfile(profile);

    setState(() => _status = '');
  }

  void _parseProfile(Map<String, dynamic> profile) {
    // Description and isBand are already parsed above

    // Band members
    if (profile['bandMembers'] is List) {
      _bandMembers = (profile['bandMembers'] as List)
          .map((m) => BandMemberDto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    // Load existing profile pictures
    if (profile['profilePictures'] is List) {
      _profilePictures = (profile['profilePictures'] as List)
          .map((pic) => ProfilePictureDto.fromJson(Map<String, dynamic>.from(pic)))
          .toList();
    }
  }

  Future<void> _save() async {
    setState(() => _status = 'Saving...');

    final allSelected = _tagManager.getAllSelectedTagIds();
    
    // We need to preserve name and location - fetch from current profile
    final profile = await _dataLoader.loadMyProfile();
    if (profile == null) {
      setState(() => _status = 'Failed to load profile for update');
      return;
    }

    final name = profile['name'] ?? '';
    final countryId = profile['countryId']?.toString() ?? profile['country_id']?.toString();
    final cityId = profile['cityId']?.toString() ?? profile['city_id']?.toString();
    
    // Get media orders
    List<String> profilePicturesOrder = [];
    List<String> musicSamplesOrder = [];
    if (profile['profilePictures'] is List) {
      profilePicturesOrder = (profile['profilePictures'] as List)
          .map((p) => p['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    if (profile['musicSamples'] is List) {
      musicSamplesOrder = (profile['musicSamples'] as List)
          .map((s) => s['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    
    dynamic resp;
    if (_isBand) {
      final dto = UpdateBandProfile(
        isBand: true,
        name: name,
        description: _desc.text.trim(),
        countryId: countryId,
        cityId: cityId,
        tagsIds: allSelected,
        bandMembers: _bandMembers,
        profilePicturesOrder: profilePicturesOrder,
        musicSamplesOrder: musicSamplesOrder,
      );
      resp = await widget.api.updateBandProfile(dto, allSelected.isEmpty ? null : allSelected);
    } else {
      // For artist, we also need birth date and gender (required fields)
      final genderId = profile['genderId']?.toString() ?? profile['gender_id']?.toString();
      DateTime? birthDate;
      if (profile['birthDate'] != null) {
        birthDate = DateTime.tryParse(profile['birthDate'].toString());
      }
      
      // Validate required fields for artist
      if (name.isEmpty) {
        setState(() => _status = 'Error: Name is required');
        return;
      }
      if (countryId == null || countryId.isEmpty) {
        setState(() => _status = 'Error: Country is required');
        return;
      }
      if (cityId == null || cityId.isEmpty) {
        setState(() => _status = 'Error: City is required');
        return;
      }
      if (birthDate == null) {
        setState(() => _status = 'Error: Birth date is required for artists');
        return;
      }
      if (genderId == null || genderId.isEmpty) {
        setState(() => _status = 'Error: Gender is required for artists');
        return;
      }
      
      final dto = UpdateArtistProfile(
        isBand: false,
        name: name,
        description: _desc.text.trim(),
        countryId: countryId,
        cityId: cityId,
        birthDate: birthDate,
        genderId: genderId,
        tagsIds: allSelected,
        profilePicturesOrder: profilePicturesOrder,
        musicSamplesOrder: musicSamplesOrder,
      );
      resp = await widget.api.updateArtistProfile(dto, allSelected.isEmpty ? null : allSelected);
    }

    setState(() => _status = 'Profile update: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      await _maybeUploadProfilePhoto();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  Future<void> _maybeUploadProfilePhoto() async {
    if (_pickedProfilePhoto != null && _pickedProfilePhoto!.bytes != null) {
      String uploadName = _pickedProfilePhoto!.name.trim();
      final lower = uploadName.toLowerCase();
      if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
        uploadName = '$uploadName.jpg';
      }
      final streamed = await widget.api.uploadProfilePicture(
        _pickedProfilePhoto!.bytes!,
        uploadName,
      );
      if (!mounted) return;
      setState(() => _status += ' ; photo upload: ${streamed.statusCode}');
      _pickedProfilePhoto = null;
    }
  }

  Future<void> _showTagPicker(String category) async {
    final options = _tagManager.buildOptionsForEdit()[category] ?? [];
    final selected = _tagManager.selected[category] ?? {};

    await showDialog(
      context: context,
      builder: (ctx) {
        final localSelected = Set.from(selected);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Select $category'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: options.map<Widget>((opt) {
                    final val = opt['value'];
                    final label = opt['label']?.toString() ?? val.toString();
                    final isSelected = localSelected.contains(val);
                    return CheckboxListTile(
                      title: Text(label),
                      value: isSelected,
                      onChanged: (checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            localSelected.add(val);
                          } else {
                            localSelected.remove(val);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tagManager.selected[category] = localSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addBandMember() async {
    final member = await showBandMemberDialog(
      context: context,
      bandRoles: _bandRoles,
    );
    if (member != null) {
      setState(() {
        _bandMembers.add(member);
      });
    }
  }

  Future<void> _editBandMember(BandMemberDto existing) async {
    final updated = await showBandMemberDialog(
      context: context,
      bandRoles: _bandRoles,
      member: existing,
    );
    if (updated != null) {
      setState(() {
        final idx = _bandMembers.indexWhere((m) => m.id == existing.id);
        if (idx >= 0) {
          _bandMembers[idx] = updated;
        }
      });
    }
  }

  void _removeBandMember(BandMemberDto member) {
    setState(() {
      _bandMembers.removeWhere((m) => m.id == member.id);
    });
  }

  Future<void> _pickProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedProfilePhoto = result.files.first;
      });
    }
  }

  String _humanize(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  String _bandRoleName(String bandRoleId) {
    for (final r in _bandRoles) {
      if (r.id == bandRoleId) return r.name;
    }
    return bandRoleId;
  }

  @override
  Widget build(BuildContext context) {
    final tagOptions = _tagManager.buildOptionsForEdit();
    final categories = tagOptions.keys.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: isDark ? AppColors.textWhite : Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textWhite : Colors.black,
          ),
          onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
        ),
      ),
      body: _status == 'Loading...'
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo circle at the top
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfilePhoto,
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
                              backgroundImage: _pickedProfilePhoto?.bytes != null
                                  ? MemoryImage(_pickedProfilePhoto!.bytes!)
                                  : (_profilePictures.isNotEmpty
                                      ? NetworkImage(_profilePictures.first.getAbsoluteUrl(widget.api.baseUrl))
                                      : null),
                              child: _pickedProfilePhoto?.bytes == null && _profilePictures.isEmpty
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
                                onPressed: _pickProfilePhoto,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                          if (_pickedProfilePhoto != null || _profilePictures.isNotEmpty)
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
                                  onPressed: () {
                                    setState(() {
                                      _pickedProfilePhoto = null;
                                      // Note: This only clears from UI, actual deletion would need API call
                                      _profilePictures = [];
                                    });
                                  },
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
                  Center(
                    child: Text(
                      'Tap to ${_pickedProfilePhoto == null ? 'add' : 'change'} profile photo',
                      style: TextStyle(fontSize: 12, color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description
                  TextFormField(
                    controller: _desc,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => validateDescription(value ?? ''),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      helperText: '${_desc.text.length}/500 characters',
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
                      hintText: 'Tell others about yourself...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                    maxLines: 4,
                    onChanged: (value) {
                      setState(() {}); // Trigger rebuild to update character count
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  const Text(
                    'Tags',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (tagOptions.isEmpty)
                    Text(
                      '(no tags available)',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  else
                    ...categories.map((cat) {
                      final selectedSet = _tagManager.selected[cat] ?? {};
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _humanize(cat),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _showTagPicker(cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                                borderRadius: BorderRadius.circular(30),
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
                                return Chip(
                                  label: Text(label),
                                  backgroundColor: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                                  deleteIconColor: AppColors.accentPurple,
                                  onDeleted: () {
                                    setState(() {
                                      _tagManager.selected[cat]?.remove(val);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),

                  // Band Members Section
                  if (_isBand) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Band Members',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_bandMembers.isEmpty)
                      Text(
                        '(no members added)',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      ..._bandMembers.map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDarkAlt : AppColors.accentPurpleSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              title: Text('${m.name} (${m.age} y/o)'),
                              subtitle: Text(
                                'Role: ${_bandRoleName(m.bandRoleId)} • Order: ${m.displayOrder}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: AppColors.accentPurple),
                                    onPressed: () => _editBandMember(m),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: isDark ? const Color(0xFFE57373) : const Color(0xFFEF5350)),
                                    onPressed: () => _removeBandMember(m),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentPurple,
                        side: BorderSide(color: AppColors.accentPurple, width: 2),
                      ),
                      label: const Text('Add Band Member'),
                      onPressed: _addBandMember,
                    ),
                    const SizedBox(height: 32),
                  ],


                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPurple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),

                  if (_status.isNotEmpty && _status != 'Loading...') ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _status.contains('200')
                            ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9))
                            : (isDark ? const Color(0xFFB71C1C) : const Color(0xFFFFEBEE)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _status.contains('200')
                              ? (isDark ? const Color(0xFF4CAF50) : const Color(0xFF81C784))
                              : (isDark ? const Color(0xFFE57373) : const Color(0xFFE57373)),
                        ),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('200')
                              ? (isDark ? const Color(0xFFA5D6A7) : const Color(0xFF1B5E20))
                              : (isDark ? const Color(0xFFFFCDD2) : const Color(0xFFC62828)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _desc.dispose();
    super.dispose();
  }
}
