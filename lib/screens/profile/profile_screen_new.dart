import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import '../../widgets/app_bottom_nav.dart';
import 'profile_data_loader.dart';
import 'profile_tag_manager.dart';
import 'profile_band_member_dialog.dart';
import 'profile_edit_step1.dart';
import 'profile_edit_step2.dart';
import 'profile_view_tabs.dart';
import 'profile_pickers.dart';

/// Main Profile Screen - orchestrates profile viewing and editing
class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final bool startInEditMode;
  final bool isSettingsEdit;
  final bool isFromRegistration;

  const ProfileScreen({
    super.key,
    required this.api,
    required this.tokens,
    this.startInEditMode = false,
    this.isSettingsEdit = false,
    this.isFromRegistration = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

  // State
  bool _isEditing = false;
  int _currentStep = 1;
  bool _isFromRegistration = false;
  String _status = '';
  bool _citiesLoading = false;

  // Data
  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  List<GenderDto> _genders = [];
  List<BandRoleDto> _bandRoles = [];
  CountryDto? _selectedCountry;
  CityDto? _selectedCity;
  GenderDto? _selectedGender;
  bool? _isBand;
  DateTime? _birthDate;

  // Band members
  List<BandMemberDto> _bandMembers = [];

  // Multimedia
  List<ProfilePictureDto> _profilePictures = [];
  List<MusicSampleDto> _musicSamples = [];
  PlatformFile? _pickedProfilePhoto;

  // Helpers
  late ProfileDataLoader _dataLoader;
  final ProfileTagManager _tagManager = ProfileTagManager();
  final Map<String, LatLng> _cityCoords = {};
  final Map<String, LatLng> _geocodeCache = {};

  @override
  void initState() {
    super.initState();
    _dataLoader = ProfileDataLoader(widget.api);
    _isEditing = widget.startInEditMode;
    _isFromRegistration = widget.isFromRegistration;
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadCountries(),
      _loadGenders(),
      _loadBandRoles(),
      _loadProfileAndTags(),
    ]);
  }

  Future<void> _loadCountries() async {
    final countries = await _dataLoader.loadCountries();
    setState(() => _countries = countries);
  }

  Future<void> _loadGenders() async {
    final genders = await _dataLoader.loadGenders();
    setState(() => _genders = genders);
  }

  Future<void> _loadBandRoles() async {
    final roles = await _dataLoader.loadBandRoles();
    setState(() => _bandRoles = roles);
  }

  Future<void> _loadProfileAndTags() async {
    setState(() => _status = 'Loading profile...');

    // Load profile FIRST to get isBand value
    final profile = await _dataLoader.loadMyProfile();
    if (profile == null) {
      setState(() => _status = 'Failed to load profile');
      return;
    }

    _parseProfile(profile);

    // NOW load and filter tags based on isBand
    final tags = await _dataLoader.loadTags();
    final categories = await _dataLoader.loadTagCategories();
    _tagManager.initialize(
      categories: categories,
      tags: tags,
      filterForBand: _isBand,
    );

    _tagManager.setUserTags(
      profile['tagsIds'] is List
          ? (profile['tagsIds'] as List).map((t) => t.toString()).toList()
          : [],
    );
    _tagManager.populateSelectedForEdit();

    setState(() => _status = '');

    // If coming from registration, always start at Step 1
    if (_isFromRegistration) {
      setState(() {
        _isEditing = true;
        _currentStep = 1;
      });
    }
    // If editing from /profile/edit but not from registration, go to Step 2
    else if (widget.startInEditMode && !_isFromRegistration) {
      setState(() {
        _isEditing = true;
        _currentStep = 2;
      });
    }
  }

  void _parseProfile(Map<String, dynamic> profile) {
    // Basic info
    _name.text = profile['name'] ?? '';
    _desc.text = profile['description'] ?? '';
    _city.text = profile['city'] ?? '';
    _country.text = profile['country'] ?? '';
    _isBand = profile['isBand'] is bool
        ? profile['isBand'] as bool
        : (profile['isBand']?.toString().toLowerCase() == 'true');

    // Parse birthDate
    if (profile['birthDate'] != null) {
      final parsed = DateTime.tryParse(profile['birthDate'].toString());
      if (parsed != null) _birthDate = parsed;
    }

    // Gender
    final genderId =
        profile['genderId']?.toString() ?? profile['gender_id']?.toString();
    if (genderId != null && _genders.isNotEmpty) {
      _selectedGender = _genders.firstWhere(
        (g) => g.id == genderId,
        orElse: () => _genders.first,
      );
    }

    // Country and City
    final cid = profile['countryId']?.toString() ?? profile['country_id']?.toString();
    final cityId = profile['cityId']?.toString() ?? profile['city_id']?.toString();
    
    if (cid != null && _countries.isNotEmpty) {
      _selectedCountry = _countries.firstWhere(
        (c) => c.id == cid,
        orElse: () => _countries.first,
      );
      if (_selectedCountry != null) {
        _country.text = _selectedCountry!.name;
        _loadCitiesForSelectedCountry(_selectedCountry!.id).then((_) {
          if (cityId != null && _cities.isNotEmpty) {
            final selCity = _cities.firstWhere(
              (c) => c.id == cityId,
              orElse: () => _cities.first,
            );
            setState(() {
              _selectedCity = selCity;
              _city.text = selCity.name;
            });
          }
        });
      }
    }

    // Pictures and samples
    if (profile['profilePictures'] is List) {
      _profilePictures = (profile['profilePictures'] as List)
          .map((pic) => ProfilePictureDto.fromJson(Map<String, dynamic>.from(pic)))
          .toList();
    }
    if (profile['musicSamples'] is List) {
      _musicSamples = (profile['musicSamples'] as List)
          .map((s) => MusicSampleDto.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }

    // Band members
    if (profile['bandMembers'] is List) {
      _bandMembers = (profile['bandMembers'] as List)
          .map((m) => BandMemberDto.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
  }

  Future<void> _loadCitiesForSelectedCountry(String countryId) async {
    if (_citiesLoading) return;
    setState(() {
      _citiesLoading = true;
      _cities = [];
    });

    final cities = await _dataLoader.loadCities(countryId);
    setState(() {
      _cities = cities;
      _citiesLoading = false;
    });
  }

  Future<LatLng?> _geocodeCity(CityDto city) async {
    if (_cityCoords.containsKey(city.id)) return _cityCoords[city.id];
    if (_geocodeCache.containsKey(city.id)) return _geocodeCache[city.id];

    final countryName = _selectedCountry?.name ?? '';
    final query = [city.name, if (countryName.isNotEmpty) countryName].join(', ');
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');

    try {
      final resp = await http.get(uri, headers: {
        'User-Agent': 'soundmates_front/1.0 (map preview)',
        'Accept': 'application/json'
      });
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(
              first['lon']?.toString() ?? first['lng']?.toString() ?? '');
          if (lat != null && lon != null) {
            final ll = LatLng(lat, lon);
            _geocodeCache[city.id] = ll;
            return ll;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _showCountryPicker() async {
    final result = await showCountryPickerDialog(
      context: context,
      countries: _countries,
    );
    if (result != null) {
      setState(() {
        _selectedCountry = result;
        _country.text = result.name;
        _selectedCity = null;
        _city.text = '';
        _cities = [];
      });
      await _loadCitiesForSelectedCountry(result.id);
    }
  }

  Future<void> _showCityPicker() async {
    if (_selectedCountry == null || _citiesLoading || _cities.isEmpty) return;

    final result = await showCityPickerDialog(
      context: context,
      cities: _cities,
      selectedCountry: _selectedCountry!,
      cityCoords: _cityCoords,
      geocodeCity: _geocodeCity,
    );
    if (result != null) {
      setState(() {
        _selectedCity = result;
        _city.text = result.name;
      });
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birth date',
      cancelText: 'Cancel',
      confirmText: 'OK',
      fieldLabelText: 'Birth date',
      fieldHintText: 'DD/MM/YYYY',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _showTagPicker(String category) async {
    final opts = _tagManager.buildOptionsForEdit()[category];
    if (opts == null || opts.isEmpty) return;

    final current = Set<dynamic>.from(_tagManager.selected[category] ?? {});
    final result = await showDialog<Set<dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select: ${_humanize(category)}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: opts.map((opt) {
                      final val = opt['value'];
                      final label = opt['label']?.toString() ?? val.toString();
                      final checked = current.contains(val);
                      return CheckboxListTile(
                        value: checked,
                        title: Text(label),
                        onChanged: (v) {
                          setDialogState(() {
                            if (v == true) {
                              current.add(val);
                            } else {
                              current.remove(val);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(current),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _tagManager.selected[category] = result;
      });
    }
  }

  String _humanize(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  Future<void> _pickProfilePhoto() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg'],
      withData: true,
      allowMultiple: false,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedProfilePhoto = res.files.first);
    }
  }

  Future<void> _addBandMember() async {
    final result = await showBandMemberDialog(
      context: context,
      bandRoles: _bandRoles,
    );
    if (result != null) {
      setState(() {
        final newMember = result.copyWith(displayOrder: _bandMembers.length);
        _bandMembers.add(newMember);
      });
    }
  }

  Future<void> _editBandMember(BandMemberDto member) async {
    final result = await showBandMemberDialog(
      context: context,
      bandRoles: _bandRoles,
      member: member,
    );
    if (result != null) {
      setState(() {
        final idx = _bandMembers.indexWhere((m) => m.id == member.id);
        if (idx != -1) {
          final updated = result.copyWith(displayOrder: _bandMembers[idx].displayOrder);
          _bandMembers[idx] = updated;
        }
      });
    }
  }

  void _removeBandMember(BandMemberDto member) {
    setState(() {
      _bandMembers.removeWhere((m) => m.id == member.id);
      for (var i = 0; i < _bandMembers.length; i++) {
        _bandMembers[i] = _bandMembers[i].copyWith(displayOrder: i);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _status = 'Saving...');

    final allSelected = _tagManager.getAllSelectedTagIds();
    final picturesOrder = _profilePictures.map((p) => p.id).toList();
    final samplesOrder = _musicSamples.map((s) => s.id).toList();

    http.Response resp;
    if (_isBand == true) {
      final dto = UpdateBandProfile(
        isBand: _isBand,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        countryId: _selectedCountry?.id ?? '',
        cityId: _selectedCity?.id ?? '',
        tagsIds: allSelected,
        musicSamplesOrder: samplesOrder,
        profilePicturesOrder: picturesOrder,
        bandMembers: _bandMembers,
      );
      resp = await widget.api.updateBandProfile(dto, allSelected.isEmpty ? null : allSelected);
    } else {
      final dto = UpdateArtistProfile(
        isBand: _isBand,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        countryId: _selectedCountry?.id ?? '',
        cityId: _selectedCity?.id ?? '',
        birthDate: _birthDate,
        genderId: _selectedGender?.id,
        tagsIds: allSelected,
        musicSamplesOrder: samplesOrder,
        profilePicturesOrder: picturesOrder,
      );
      resp = await widget.api.updateArtistProfile(dto, allSelected.isEmpty ? null : allSelected);
    }

    setState(() => _status = 'Profile update: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      await _maybeUploadProfilePhoto();
      await _goToProfileView();
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
      await _loadProfileAndTags();
      _pickedProfilePhoto = null;
    }
  }

  Future<void> _goToProfileView() async {
    if (!mounted) return;
    // Navigate to profile view route
    Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    final showNav = !_isEditing;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _isEditing
          ? AppBar(
              title: Text(
                widget.isSettingsEdit
                    ? 'Edit Profile'
                    : _isFromRegistration
                        ? (_currentStep == 1 ? 'Create Profile - Step 1' : 'Create Profile - Step 2')
                        : 'Edit Profile',
              ),
              automaticallyImplyLeading: !(_isFromRegistration && _currentStep == 1),
              leading: _isFromRegistration && _currentStep == 1
                  ? null // No back button in Step 1 during registration
                  : _isFromRegistration && _currentStep == 2
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => setState(() => _currentStep = 1),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
                        ),
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: const Text(
                'Your Profile',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
      body: _isEditing
          ? _buildEditingView()
          : Stack(
              children: [
                Positioned.fill(
                  child: ProfileViewTabs(
                    name: _name.text,
                    description: _desc.text,
                    city: _city.text,
                    country: _country.text,
                    birthDate: _birthDate,
                    tagGroups: _tagManager.groupUserTagsForDisplay(),
                    bandMembers: _bandMembers,
                    bandRoles: _bandRoles,
                    profilePictures: _profilePictures,
                    musicSamples: _musicSamples,
                    api: widget.api,
                    isBand: _isBand == true,
                    onEditProfile: () {
                      Navigator.pushNamed(context, '/profile/edit-tags');
                    },
                    onAddMedia: () async {
                      final result = await Navigator.pushNamed(context, '/profile/add-media');
                      // If files were uploaded (result == true), reload profile
                      if (result == true) {
                        await _loadProfileAndTags();
                      }
                    },
                    startInEditMode: widget.startInEditMode,
                  ),
                ),
                if (showNav)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 18,
                    child: AppBottomNav(current: BottomNavItem.profile),
                  ),
              ],
            ),
    );
  }

  Widget _buildEditingView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: _currentStep == 1
            ? ProfileEditStep1(
                nameController: _name,
                cityController: _city,
                countryController: _country,
                isBand: _isBand,
                selectedCountry: _selectedCountry,
                selectedCity: _selectedCity,
                birthDate: _birthDate,
                selectedGender: _selectedGender,
                countries: _countries,
                cities: _cities,
                genders: _genders,
                citiesLoading: _citiesLoading,
                isSettingsEdit: widget.isSettingsEdit,
                onShowCountryPicker: _showCountryPicker,
                onShowCityPicker: _showCityPicker,
                onIsBandChanged: (v) {
                  setState(() {
                    _isBand = v;
                    // Reload tag options for the new account type
                    _dataLoader.loadTags().then((tags) {
                      _dataLoader.loadTagCategories().then((categories) {
                        _tagManager.initialize(
                          categories: categories,
                          tags: tags,
                          filterForBand: _isBand,
                        );
                        setState(() {});
                      });
                    });
                  });
                },
                onPickBirthDate: _pickBirthDate,
                onGenderChanged: (id) {
                  setState(() {
                    if (id == null) {
                      _selectedGender = null;
                    } else {
                      _selectedGender = _genders.firstWhere(
                        (g) => g.id == id,
                        orElse: () => _genders.first,
                      );
                    }
                  });
                },
                onNext: () => setState(() => _currentStep = 2),
                onSave: widget.isSettingsEdit ? _save : null,
                status: _status,
              )
            : ProfileEditStep2(
                descController: _desc,
                tagOptions: _tagManager.buildOptionsForEdit(),
                selectedTags: _tagManager.selected,
                isBand: _isBand == true,
                bandMembers: _bandMembers,
                bandRoles: _bandRoles,
                pickedProfilePhoto: _pickedProfilePhoto,
                onBack: () => setState(() => _currentStep = 1),
                onComplete: _save,
                onShowTagPicker: _showTagPicker,
                onRemoveTag: (cat, val) {
                  setState(() {
                    _tagManager.selected[cat]?.remove(val);
                  });
                },
                onAddBandMember: _addBandMember,
                onEditBandMember: _editBandMember,
                onRemoveBandMember: _removeBandMember,
                onPickProfilePhoto: _pickProfilePhoto,
                onRemoveProfilePhoto: () => setState(() => _pickedProfilePhoto = null),
                status: _status,
                showBackButton: _isFromRegistration, // Only show Back button during registration
              ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }
}
