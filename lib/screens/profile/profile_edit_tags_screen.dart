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
        setState(() => _status = 'Name is required');
        return;
      }
      if (countryId == null || countryId.isEmpty) {
        setState(() => _status = 'Country is required');
        return;
      }
      if (cityId == null || cityId.isEmpty) {
        setState(() => _status = 'City is required');
        return;
      }
      if (birthDate == null) {
        setState(() => _status = 'Birth date is required for artists');
        return;
      }
      if (genderId == null || genderId.isEmpty) {
        setState(() => _status = 'Gender is required for artists');
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

    if (resp.statusCode == 200) {
      await _maybeUploadProfilePhoto();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/profile');
    } else {
      setState(() => _status = 'Failed to save changes. Please try again.');
    }
  }

  Future<void> _maybeUploadProfilePhoto() async {
    if (_pickedProfilePhoto != null && _pickedProfilePhoto!.bytes != null) {
      String uploadName = _pickedProfilePhoto!.name.trim();
      final lower = uploadName.toLowerCase();
      if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
        uploadName = '$uploadName.jpg';
      }
      await widget.api.uploadProfilePicture(
        _pickedProfilePhoto!.bytes!,
        uploadName,
      );
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
                      activeColor: AppColors.accentPurple,
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                  ),
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
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTags(BuildContext context, bool isDark) {
    final tagOptions = _tagManager.buildOptionsForEdit();
    if (tagOptions.isEmpty) {
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

    final categories = tagOptions.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('TAGS'),
        const SizedBox(height: 12),
        ...categories.map((cat) {
          final selectedSet = _tagManager.selected[cat] ?? {};
          final options = tagOptions[cat] ?? [];
          final selectedOptions = options.where((o) => selectedSet.contains(o['value'])).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCard(
              context,
              isDark,
              child: InkWell(
                onTap: () => _showTagPicker(cat),
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
                                    onTap: () {
                                      setState(() {
                                        _tagManager.selected[cat]?.remove(value);
                                      });
                                    },
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
              if (_bandMembers.isEmpty)
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
                ..._bandMembers.asMap().entries.map((entry) {
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
                              onPressed: () => _editBandMember(m),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: isDark ? const Color(0xFFE57373) : Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: () => _removeBandMember(m),
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
                    onPressed: _addBandMember,
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile photo section
                  _buildSectionHeader('PROFILE PHOTO'),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _pickProfilePhoto,
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
                              backgroundImage: _pickedProfilePhoto?.bytes != null
                                  ? MemoryImage(_pickedProfilePhoto!.bytes!)
                                  : (_profilePictures.isNotEmpty
                                      ? NetworkImage(_profilePictures.first.getAbsoluteUrl(widget.api.baseUrl))
                                      : null),
                              child: _pickedProfilePhoto?.bytes == null && _profilePictures.isEmpty
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
                          if (_pickedProfilePhoto != null || _profilePictures.isNotEmpty)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pickedProfilePhoto = null;
                                    _profilePictures = [];
                                  });
                                },
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
                      _pickedProfilePhoto == null && _profilePictures.isEmpty
                          ? 'Tap to add photo'
                          : 'Tap to change photo',
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
                            controller: _desc,
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
                              counterText: '${_desc.text.length}/500',
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
                  _buildTags(context, isDark),
                  const SizedBox(height: 8),

                  // Band members section (only for bands)
                  if (_isBand) ...[
                    _buildBandMembersSection(context, isDark),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 8),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _save,
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
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_status.isNotEmpty && _status != 'Loading...' && _status != 'Saving...') ...[
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
                              _status,
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

                  const SizedBox(height: 32),
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
