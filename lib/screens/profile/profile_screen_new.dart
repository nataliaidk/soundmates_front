import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import '../../theme/app_design_system.dart';
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
    // Validate before saving
    final validationError = _validateProfile();
    if (validationError != null) {
      setState(() => _status = validationError);
      return;
    }

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

    if (resp.statusCode == 200) {
      setState(() => _status = '');
      await _maybeUploadProfilePhoto();
      await _goToProfileView();
    } else {
      // Parse error response for better error messages
      final errorMessage = _parseErrorResponse(resp);
      setState(() => _status = errorMessage);
    }
  }

  String? _validateProfile() {
    // Validate name
    if (_name.text.trim().isEmpty) {
      return 'Name is required';
    }
    if (_name.text.trim().length > 50) {
      return 'Name is too long (max 50 characters)';
    }

    // Validate location
    if (_selectedCountry == null) {
      return 'Please select a country';
    }
    if (_selectedCity == null) {
      return 'Please select a city';
    }

    // Validate artist-specific fields
    if (_isBand != true) {
      if (_birthDate == null) {
        return 'Birth date is required for artists';
      }
      // Validate age (must be at least 13)
      final age = DateTime.now().difference(_birthDate!).inDays ~/ 365;
      if (age < 13) {
        return 'You must be at least 13 years old';
      }
      if (age > 100) {
        return 'Birth date must be within the last 100 years';
      }
      if (_selectedGender == null) {
        return 'Please select your gender';
      }
    }

    // Validate band members
    if (_isBand == true) {
      for (final member in _bandMembers) {
        if (member.name.trim().isEmpty) {
          return 'Band member name cannot be empty';
        }
        if (member.name.trim().length > 50) {
          return 'Band member name is too long (max 50 characters)';
        }
        if (member.age < 13) {
          return 'Band member "${member.name}" must be at least 13 years old';
        }
        if (member.age > 100) {
          return 'Band member "${member.name}" age must be 100 or less';
        }
      }
    }

    // Validate description (optional but has max length)
    if (_desc.text.trim().length > 500) {
      return 'Description is too long (max 500 characters)';
    }

    return null; // No validation errors
  }

  String _parseErrorResponse(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);

      // Check for validation errors in common formats
      if (body is Map) {
        // Check for 'errors' field (common in ASP.NET validation)
        if (body.containsKey('errors')) {
          final errors = body['errors'];
          if (errors is Map) {
            final messages = <String>[];
            errors.forEach((key, value) {
              if (value is List) {
                messages.addAll(value.map((v) => v.toString()));
              } else {
                messages.add(value.toString());
              }
            });
            if (messages.isNotEmpty) {
              return messages.join('\n');
            }
          }
        }

        // Check for 'message' field
        if (body.containsKey('message')) {
          return body['message'].toString();
        }

        // Check for 'title' field (ASP.NET problem details)
        if (body.containsKey('title')) {
          return body['title'].toString();
        }

        // Check for 'detail' field (ASP.NET problem details)
        if (body.containsKey('detail')) {
          return body['detail'].toString();
        }
      }

      // If body is a string
      if (body is String && body.isNotEmpty) {
        return body;
      }
    } catch (_) {
      // JSON parsing failed
    }

    // Fallback based on status code
    switch (resp.statusCode) {
      case 400:
        return 'Invalid data. Please check all fields and try again.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You don\'t have permission to perform this action.';
      case 404:
        return 'Profile not found. Please try again.';
      case 413:
        return 'Data too large. Please reduce the size of your content.';
      case 422:
        return 'Invalid data format. Please check all fields.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong (Error ${resp.statusCode}). Please try again.';
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

    // If completing profile creation (from registration), go to discover screen
    if (_isFromRegistration) {
      Navigator.pushReplacementNamed(context, '/discover');
    } else {
      // Otherwise go back to profile view
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showNav = !_isEditing;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prevent back navigation during profile creation
    return PopScope(
      canPop: !_isFromRegistration, // Disable back button during registration flow
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFromRegistration) {
          // User tried to go back during profile creation
          if (_currentStep == 2) {
            // Go back to step 1 instead of leaving
            setState(() => _currentStep = 1);
          } else {
            // On step 1, show a message that they can't go back
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please complete your profile to continue'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[50],
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
              title: Text(
                'Your Profile',
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: isDark ? AppColors.textWhite : Colors.black,
                  ),
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
                    onManageMedia: () async {
                      await Navigator.pushNamed(context, '/profile/manage-media');
                      // Reload profile after managing media
                      await _loadProfileAndTags();
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
