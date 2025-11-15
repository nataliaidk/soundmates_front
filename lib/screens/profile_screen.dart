import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/city_map_preview.dart';
import 'package:http/http.dart' as http; // for optional geocoding fallback
import '../widgets/app_bottom_nav.dart';
class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final bool startInEditMode;
  // True when opened from Settings -> Account to edit basic info only
  final bool isSettingsEdit;
  
  const ProfileScreen({
    super.key, 
    required this.api, 
    required this.tokens,
    this.startInEditMode = false,
    this.isSettingsEdit = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  List<PlatformFile> _pickedFiles = [];
  PlatformFile? _pickedProfilePhoto; // Single profile photo (optional)
  String _status = '';

  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  bool _citiesLoading = false; // Track if cities are being loaded
  CountryDto? _selectedCountry;
  CityDto? _selectedCity;
  bool? _isBand;
  List<BandMemberDto> _bandMembers = [];
  List<BandRoleDto> ? _bandRoles = [];
  // city id -> coordinates (from backend); we don't modify CityDto
  final Map<String, LatLng> _cityCoords = {};
  // Optional geocode cache for names without provided coordinates
  final Map<String, LatLng> _geocodeCache = {};

  // Profile pictures and music samples
  List<ProfilePictureDto> _profilePictures = [];
  // ignore: unused_field
  List<MusicSampleDto> _musicSamples = [];

  // artist fields
  DateTime? _birthDate;
  List<GenderDto> _genders = [];
  GenderDto? _selectedGender;

  bool _isEditing = false; // Track edit mode
  int _currentStep = 1; // 1 = basic info, 2 = tags/files/description/members
  int _selectedTab = 0; // 0 = Your Info, 1 = Multimedia
  bool _isFromRegistration = false; // Track if we're in registration flow
  Map<String, List<Map<String, dynamic>>> _options = {};
  // map categoryName -> set of selected values
  final Map<String, Set<dynamic>> _selected = {};
  // For displaying tags in view mode
  List<String> _userTagIds = []; // Tag IDs from user profile
  Map<String, List<TagDto>> _tagGroups = {}; // categoryId -> [TagDto]
  Map<String, String> _categoryNames = {}; // categoryId -> categoryName

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode; // Start in edit mode
    // If opened from settings, this is NOT registration flow
    _isFromRegistration = widget.startInEditMode && !widget.isSettingsEdit;
    _loadOptions();
    _loadCountries();
    _loadBandRoles();
    _loadProfilePictures();
    _loadProfileAndTags(); // Load profile and tags together
  }

  Future<void> _loadProfileAndTags() async {
    // Load both profile and tag data, then populate selected tags
    await Future.wait([
      _loadProfile(),
      _loadTagData(),
    ]);
    
    // After both are loaded, populate selected tags for edit mode
    if (_userTagIds.isNotEmpty && _tagGroups.isNotEmpty) {
      _populateSelectedTags();
    }

    // If profile is incomplete (e.g., right after registration), stay in editing (Step 1/2)
    if (_shouldForceEditMode()) {
      if (!mounted) return;
      setState(() {
        _isEditing = true;
        _currentStep = 1;
      });
    }
  }

  bool _shouldForceEditMode() {
    // Name required
    if (_name.text.trim().isEmpty) return true;
    // Country/City required
    if (_selectedCountry == null || _selectedCity == null) return true;
    // Artist-specific fields required
    if (_isBand != true) {
      if (_birthDate == null || _selectedGender == null) return true;
    }
    return false;
  }

  Future<void> _loadProfilePictures() async {
    // This is now handled by _loadProfile() which gets the full profile with pictures and samples
    // Keeping this method for compatibility but it does nothing
  }

  Future<void> _loadTagData() async {
    try {
      final tagsResp = await widget.api.getTags();
      final categoriesResp = await widget.api.getTagCategories();

      if (tagsResp.statusCode == 200 && categoriesResp.statusCode == 200) {
        final tagsList = (jsonDecode(tagsResp.body) as List)
            .map((e) => TagDto.fromJson(e))
            .toList();
        final categoriesList = (jsonDecode(categoriesResp.body) as List)
            .map((e) => TagCategoryDto.fromJson(e))
            .toList();

        setState(() {
          for (final cat in categoriesList) {
            _categoryNames[cat.id] = cat.name;
            _tagGroups[cat.id] = [];
          }
          for (final tag in tagsList) {
            if (tag.tagCategoryId != null && _tagGroups.containsKey(tag.tagCategoryId)) {
              _tagGroups[tag.tagCategoryId]!.add(tag);
            }
          }
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadBandRoles() async {
    try {
      final resp = await widget.api.getBandRoles();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<BandRoleDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(BandRoleDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        setState(()=> _bandRoles = list);
        // Do something with the list of band roles if needed
      }
    } catch (_) {
      // ignore
    }
  }
  Future<void> _loadCountries() async {
    try {
      final resp = await widget.api.getCountries();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<CountryDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(CountryDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        setState(() => _countries = list);
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadOptions() async {
    try {
      setState(() => _status = 'Loading tags...');

      // fetch categories, tags, and genders
      final catResp = await widget.api.getTagCategories();
      final tagResp = await widget.api.getTags();
      final genderResp = await widget.api.getGenders();

      // parse genders first
      if (genderResp.statusCode == 200) {
        var dec = jsonDecode(genderResp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          final List<GenderDto> genders = [];
          for (final e in dec) {
            if (e is Map) genders.add(GenderDto.fromJson(Map<String, dynamic>.from(e)));
          }
          setState(() => _genders = genders);
        }
      }

      final Map<String, List<Map<String, dynamic>>> groups = {};

      List<TagCategoryDto> cats = [];
      if (catResp.statusCode == 200) {
        var dec = jsonDecode(catResp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          for (final e in dec) {
            if (e is Map) cats.add(TagCategoryDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      List<TagDto> tags = [];
      if (tagResp.statusCode == 200) {
        var dec = jsonDecode(tagResp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          for (final e in dec) {
            if (e is Map) tags.add(TagDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }

      if (cats.isNotEmpty) {
        // Filter categories based on isBand value
        final filteredCats = cats.where((c) {
          if (_isBand == null) return true; // Show all if not yet decided
          return c.isForBand == _isBand; // Show only matching categories
        }).toList();
      
        // Build tagGroups and categoryNames for view mode
        final Map<String, List<TagDto>> tagGroupsTemp = {};
        final Map<String, String> categoryNamesTemp = {};
        
        for (final c in filteredCats) {
          print('Category: ${c.name} (${c.id}) - isForBand: ${c.isForBand}');
          final List<Map<String, dynamic>> opts = [];
          final ctTags = tags.where((t) => t.tagCategoryId == c.id).toList();
          tagGroupsTemp[c.id] = ctTags;
          categoryNamesTemp[c.id] = c.name;
          for (final t in ctTags) {
            opts.add({'value': t.id, 'label': t.name});
          }
          if (opts.isNotEmpty) groups[c.name] = opts;
        }
        
        setState(() {
          _tagGroups = tagGroupsTemp;
          _categoryNames = categoryNamesTemp;
        });
      } else if (tags.isNotEmpty) {
        // no categories returned - put all tags under 'tags'
        final List<Map<String, dynamic>> opts = [];
        for (final t in tags) {
          opts.add({'value': t.id, 'label': t.name});
        }
        groups['tags'] = opts;
      }

      // fallback: if no groups created, try old generic userOptions endpoint
      if (groups.isEmpty) {
        final resp = await widget.api.getUserOptions();
        if (resp.statusCode == 200) {
          var decoded = jsonDecode(resp.body);
          if (decoded is String) decoded = jsonDecode(decoded);
          if (decoded is Map) {
            decoded.forEach((k, v) {
              if (v is List) {
                final List<Map<String, dynamic>> opts = [];
                for (final e in v) {
                  if (e is String) {
                    opts.add({'value': e, 'label': e});
                  } else if (e is Map) {
                    final label = e['name'] ?? e['label'] ?? e['text'] ?? e['value'];
                    final value = e['value'] ?? label;
                    if (label != null) opts.add({'value': value, 'label': label.toString()});
                  }
                }
                if (opts.isNotEmpty) groups[k] = opts;
              }
            });
          }
        }
      }

      setState(() {
        _options = groups;
        _status = groups.isEmpty ? 'No options available' : '';
      });
    } catch (ex) {
      setState(() => _status = 'Options load error');
    }
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _status = 'Loading profile...');
      final resp = await widget.api.getMyProfile();
      if (resp.statusCode == 200) {
        final profile = jsonDecode(resp.body);
        // prepare selection values outside setState and avoid awaiting inside setState
        final nameVal = profile['name'] ?? '';
        final descVal = profile['description'] ?? '';
        final cityVal = profile['city'] ?? '';
        final countryVal = profile['country'] ?? '';
        final cid = profile['countryId']?.toString() ?? profile['country_id']?.toString();
        final cityId = profile['cityId']?.toString() ?? profile['city_id']?.toString();

        // Extract profilePictures and musicSamples from the profile response
        List<ProfilePictureDto> pictures = [];
        if (profile['profilePictures'] is List) {
          for (final pic in profile['profilePictures']) {
            if (pic is Map) {
              pictures.add(ProfilePictureDto.fromJson(Map<String, dynamic>.from(pic)));
            }
          }
        }

        List<MusicSampleDto> samples = [];
        if (profile['musicSamples'] is List) {
          for (final sample in profile['musicSamples']) {
            if (sample is Map) {
              samples.add(MusicSampleDto.fromJson(Map<String, dynamic>.from(sample)));
            }
          }
        }

        // Extract band members if present (for band profiles)
        final List<BandMemberDto> members = [];
        if (profile['bandMembers'] is List) {
          for (final m in profile['bandMembers']) {
            if (m is Map) {
              try {
                members.add(BandMemberDto.fromJson(Map<String, dynamic>.from(m)));
              } catch (_) {}
            }
          }
        }

        CountryDto? selCountry;
        if (cid != null && cid.isNotEmpty && _countries.isNotEmpty) {
          selCountry = _countries.firstWhere((c) => c.id == cid, orElse: () => _countries.first);
        } else if (countryVal != null && countryVal.isNotEmpty && _countries.isNotEmpty) {
          selCountry = _countries.firstWhere((c) => c.name == countryVal, orElse: () => _countries.first);
        }

        setState(() {
          _name.text = nameVal;
          _desc.text = descVal;
          _city.text = cityVal;
          _country.text = countryVal;
          _selectedCountry = selCountry;
          _profilePictures = pictures;
          _musicSamples = samples;
          _isBand = profile['isBand'] is bool ? profile['isBand'] as bool : (profile['isBand']?.toString().toLowerCase() == 'true');
          _bandMembers = members;
          // Load user tags - backend returns 'tagsIds' not 'tags'
          if (profile['tagsIds'] is List) {
            _userTagIds = (profile['tagsIds'] as List).map((t) => t.toString()).toList();
          } else if (profile['tags'] is List) {
            _userTagIds = (profile['tags'] as List).map((t) => t.toString()).toList();
          }
          // parse birthDate if provided (server returns yyyy-MM-dd)
          if (profile['birthDate'] != null) {
            final bd = profile['birthDate'].toString();
            final parsed = DateTime.tryParse(bd);
            if (parsed != null) _birthDate = parsed;
          }
          // set selected gender if present and genders loaded later will pick match
          final genderId = profile['genderId']?.toString() ?? profile['gender_id']?.toString();
          if (genderId != null) {
            _selectedGender = _genders.firstWhere((g) => g.id == genderId, orElse: () => GenderDto(id: genderId, name: genderId));
          }
          _status = '';
        });

        if (selCountry != null && cityId != null && cityId.isNotEmpty) {
          await _loadCitiesForSelectedCountry(selCountry.id);
          final selCity = _cities.isNotEmpty ? _cities.firstWhere((c) => c.id == cityId, orElse: () => _cities.first) : null;
          if (selCity != null) {
            setState(() {
              _selectedCity = selCity;
              _city.text = selCity.name; // Update city name for display
            });
          }
        }
        
        // Update country name for display if we have selectedCountry
        if (selCountry != null && _selectedCountry != null) {
          setState(() {
            _country.text = _selectedCountry!.name;
          });
        }
      } else {
        setState(() => _status = 'Failed to load profile: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error loading profile');
    }
  }

  // Merge URLs from profile-pictures endpoint into profile['profilePictures'] items

  Future<void> _loadCitiesForSelectedCountry(String countryId) async {
      if (_citiesLoading) return; // Prevent multiple simultaneous loads
    
      setState(() => _citiesLoading = true);
    try {
      final resp = await widget.api.getCities(countryId);
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<CityDto> list = [];
        if (decoded is List) {
          // clear previous coords for this country
          _cityCoords.clear();
          for (final e in decoded) {
            if (e is Map) {
              final map = Map<String, dynamic>.from(e);
              final city = CityDto.fromJson(map);
              list.add(city);
              // try to parse coordinates from common keys
              double? _toDouble(dynamic v) {
                if (v == null) return null;
                if (v is num) return v.toDouble();
                return double.tryParse(v.toString());
              }
              final lat = _toDouble(map['latitude'] ?? map['lat'] ?? map['Latitude']);
              final lon = _toDouble(map['longitude'] ?? map['lng'] ?? map['lon'] ?? map['Longitude']);
              if (lat != null && lon != null) {
                _cityCoords[city.id] = LatLng(lat, lon);
              }
            }
          }
        }
        setState(() => _cities = list);
      }
    } catch (_) {
      // ignore
      } finally {
        setState(() => _citiesLoading = false);
    }
  }

  // Attempt geocode (OpenStreetMap Nominatim) if backend doesn't supply coords.
  // Does NOT modify CityDto. Respects existing map cache to avoid repeated lookups.
  Future<LatLng?> _geocodeCity(CityDto city) async {
    if (_cityCoords.containsKey(city.id)) return _cityCoords[city.id];
    if (_geocodeCache.containsKey(city.id)) return _geocodeCache[city.id];
    final countryName = _selectedCountry?.name ?? '';
    final query = [city.name, if (countryName.isNotEmpty) countryName].join(', ');
    final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
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
          final lon = double.tryParse(first['lon']?.toString() ?? first['lng']?.toString() ?? '');
          if (lat != null && lon != null) {
            final ll = LatLng(lat, lon);
            _geocodeCache[city.id] = ll; // cache
            return ll;
          }
        }
      }
    } catch (_) {
      // silent failure
    }
    return null;
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'mp3', 'mp4'],
      withData: true,
      allowMultiple: true,
    );
    if (res != null && res.files.isNotEmpty) {
      setState(() => _pickedFiles = res.files);
    }
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

  void _addBandMember() async {
    final result = await _showBandMemberDialog();
    if (result != null) {
      setState(() {
        final newMember = result.copyWith(displayOrder: _bandMembers.length);
        _bandMembers.add(newMember);
      });
    }
  }

  void _editBandMember(BandMemberDto member) async {
    final result = await _showBandMemberDialog(member: member);
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

  Future<void> _showCountryPicker() async {
    if (_countries.isEmpty) return;
    final result = await showDialog<CountryDto>(
      context: context,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = _countries.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
            return AlertDialog(
              title: const Text('Select Country'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search country...',
                      ),
                      onChanged: (v) => setStateDialog(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No results'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final c = filtered[i];
                                return ListTile(
                                  title: Text(c.name),
                                  onTap: () => Navigator.pop(context, c),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ],
            );
          },
        );
      },
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
    if (_selectedCountry == null) return; // country must be selected
    if (_citiesLoading) return; // still loading
    if (_cities.isEmpty) return; // nothing to pick yet
    final result = await showDialog<CityDto>(
      context: context,
      builder: (ctx) {
        String query = '';
        CityDto? hoveredCity;
        LatLng? hoveredLatLng;
        bool geocoding = false; // show subtle progress if fetching
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = _cities.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
            return AlertDialog(
              title: Text('Select City (${_selectedCountry!.name})'),
              content: SizedBox(
                width: 720,
                height: 520,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showSidePreview = constraints.maxWidth >= 560;
                    final listPane = Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          TextField(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search city...',
                            ),
                            onChanged: (v) => setStateDialog(() => query = v),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(child: Text('No results'))
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, i) {
                                      final c = filtered[i];
                                      final coords = _cityCoords[c.id];
                                      return MouseRegion(
                                        onEnter: (_) {
                                          setStateDialog(() {
                                            hoveredCity = c;
                                            hoveredLatLng = coords;
                                          });
                                          if (coords == null) {
                                            geocoding = true;
                                            _geocodeCity(c).then((ll) {
                                              if (ll != null) {
                                                if (mounted) {
                                                  setStateDialog(() {
                                                    // Only update if still hovering same city
                                                    if (hoveredCity?.id == c.id) {
                                                      hoveredLatLng = ll;
                                                    }
                                                    geocoding = false;
                                                  });
                                                }
                                              } else {
                                                if (mounted) setStateDialog(() => geocoding = false);
                                              }
                                            });
                                          }
                                        },
                                        onExit: (_) {
                                          setStateDialog(() {
                                            hoveredCity = null;
                                            hoveredLatLng = null;
                                          });
                                        },
                                        child: ListTile(
                                          title: Text(c.name),
                                          subtitle: coords != null
                                              ? Text(
                                                  'lat ${coords.latitude.toStringAsFixed(3)}, lon ${coords.longitude.toStringAsFixed(3)}',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                )
                                              : null,
                                          trailing: coords == null
                        ? geocoding && hoveredCity?.id == c.id
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : null
                        : Icon(Icons.map, size: 18, color: Colors.purple.shade300),
                                          onTap: () => Navigator.pop(context, c),
                                          onLongPress: () {
                                            // Touch fallback: preview without closing
                                            setStateDialog(() {
                                              hoveredCity = c;
                                              hoveredLatLng = coords;
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                    if (!showSidePreview) {
                      // Mobile / narrow: show list first (full height), map preview below
                      return Column(
                        children: [
                          // List/search region (take available vertical space)
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: 'Search city...',
                                  ),
                                  onChanged: (v) => setStateDialog(() => query = v),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: filtered.isEmpty
                                      ? const Center(child: Text('No results'))
                                      : ListView.builder(
                                          itemCount: filtered.length,
                                          itemBuilder: (context, i) {
                                            final c = filtered[i];
                                            final coords = _cityCoords[c.id];
                                            return MouseRegion(
                                              onEnter: (_) {
                                                setStateDialog(() {
                                                  hoveredCity = c;
                                                  hoveredLatLng = coords;
                                                });
                                                if (coords == null) {
                                                  geocoding = true;
                                                  _geocodeCity(c).then((ll) {
                                                    if (ll != null) {
                                                      if (mounted) {
                                                        setStateDialog(() {
                                                          if (hoveredCity?.id == c.id) {
                                                            hoveredLatLng = ll;
                                                          }
                                                          geocoding = false;
                                                        });
                                                      }
                                                    } else {
                                                      if (mounted) setStateDialog(() => geocoding = false);
                                                    }
                                                  });
                                                }
                                              },
                                              onExit: (_) {
                                                setStateDialog(() {
                                                  hoveredCity = null;
                                                  hoveredLatLng = null;
                                                });
                                              },
                                              child: ListTile(
                                                title: Text(c.name),
                                                subtitle: coords != null
                                                    ? Text(
                                                        'lat ${coords.latitude.toStringAsFixed(3)}, lon ${coords.longitude.toStringAsFixed(3)}',
                                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                                      )
                                                    : null,
                                                trailing: coords == null
                                                    ? geocoding && hoveredCity?.id == c.id
                                                        ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(strokeWidth: 2),
                                                          )
                                                        : null
                                                    : Icon(Icons.map, size: 18, color: Colors.purple.shade300),
                                                onTap: () => Navigator.pop(context, c),
                                                onLongPress: () {
                                                  setStateDialog(() {
                                                    hoveredCity = c;
                                                    hoveredLatLng = coords;
                                                  });
                                                  if (coords == null) {
                                                    geocoding = true;
                                                    _geocodeCity(c).then((ll) {
                                                      if (ll != null) {
                                                        if (mounted) {
                                                          setStateDialog(() {
                                                            if (hoveredCity?.id == c.id) {
                                                              hoveredLatLng = ll;
                                                            }
                                                            geocoding = false;
                                                          });
                                                        }
                                                      } else {
                                                        if (mounted) setStateDialog(() => geocoding = false);
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 140,
                            child: CityMapPreview(center: hoveredLatLng, cityName: hoveredCity?.name, height: 140),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        listPane,
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 320,
                          child: CityMapPreview(center: hoveredLatLng, cityName: hoveredCity?.name),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedCity = result;
        _city.text = result.name;
      });
    }
  }



  Future<void> _save() async {
    final nameErr = validateName(_name.text);
    if (nameErr != null) {
      setState(() => _status = nameErr);
      return;
    }
    final descErr = validateDescription(_desc.text);
    if (descErr != null) {
      setState(() => _status = descErr);
      return;
    }
    final cityValue = _selectedCity?.name ?? _city.text;
    final countryValue = _selectedCountry?.name ?? _country.text;
    final cityErr = validateCityOrCountry(cityValue, 'City');
    if (cityErr != null) {
      setState(() => _status = cityErr);
      return;
    }
    final countryErr = validateCityOrCountry(countryValue, 'Country');
    if (countryErr != null) {
      setState(() => _status = countryErr);
      return;
    }

    setState(() => _status = 'Saving...');

    final allSelected = _selected.values.expand((s) => s).map((v) => v.toString()).toList();

    if (_isBand != true) {
      if (_birthDate == null) {
        setState(() => _status = 'Birth date is required for artists');
        return;
      }
      if (_selectedGender == null) {
        setState(() => _status = 'Gender is required for artists');
        return;
      }
    }

    // Preserve multimedia order
    final picturesOrder = _profilePictures.map((p) => p.id).toList();
    final samplesOrder = _musicSamples.map((s) => s.id).toList();

    if (_isBand == true) {
      final dtoWithTags = UpdateBandProfile(
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
      final resp = await widget.api.updateBandProfile(dtoWithTags, allSelected.isEmpty ? null : allSelected);
      setState(() => _status = 'Profile update: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        await _maybeUploadProfilePhoto();
        // After registration, show profile (no immediate home navigation)
        await _goToProfileView();
      } else {
        return;
      }
    } else {
      final dtoWithTags = UpdateArtistProfile(
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
      final resp = await widget.api.updateArtistProfile(dtoWithTags, allSelected.isEmpty ? null : allSelected);
      setState(() => _status = 'Profile update: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        await _maybeUploadProfilePhoto();
        // After registration, show profile (no immediate home navigation)
        await _goToProfileView();
      } else {
        return;
      }
    }
  }

  Future<void> _maybeUploadProfilePhoto() async {
    if (_pickedProfilePhoto != null && _pickedProfilePhoto!.bytes != null) {
      String uploadName = _pickedProfilePhoto!.name.trim();
      final lower = uploadName.toLowerCase();
      if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
        uploadName = '$uploadName.jpg';
      }
  final streamed = await widget.api.uploadProfilePicture(_pickedProfilePhoto!.bytes!, uploadName);
      if (!mounted) return;
      setState(() => _status += ' ; photo upload: ${streamed.statusCode}');
      await _loadProfileAndTags();
      _pickedProfilePhoto = null;
    }
  }

  Future<void> _goToProfileView() async {
    // Reload full profile and tag data to reflect latest data, then switch to view mode
    await _loadProfileAndTags();
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _currentStep = 1;
    });
  }

  // Welcome dialog removed from flow (registration goes directly to profile view after save)
  
  Future<BandMemberDto?> _showBandMemberDialog({BandMemberDto? member}) async {
  final nameCtrl = TextEditingController(text: member?.name ?? '');
  final ageCtrl = TextEditingController(text: member?.age.toString() ?? '');

  // ✅ preselect current role (if editing)
  BandRoleDto? selectedRole;
  if (member != null && _bandRoles != null && _bandRoles!.isNotEmpty) {
    selectedRole = _bandRoles!.firstWhere(
      (r) => r.id == member.bandRoleId,
      orElse: () => _bandRoles!.first,
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

              // ✅ dropdown for role instead of TextField
              const SizedBox(height: 12),
              DropdownButtonFormField<BandRoleDto>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: _bandRoles!.map(
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
                  bandId: 'TEMP',       // backend overwrites
                  bandRoleId: selectedRole!.id, // 
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


  Future<void> _showTagPicker(String category) async {
    final opts = _options[category];
    if (opts == null || opts.isEmpty) return;

    final current = Set<dynamic>.from(_selected[category] ?? {});
    final result = await showDialog<Set<dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Wybierz: ${_humanize(category)}'),
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
              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Anuluj')),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(current), child: const Text('OK')),
            ],
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        _selected[category] = result;
      });
    }
  }

  String _humanize(String key) {
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  String _bandRoleName(String bandRoleId) {
    if (_bandRoles != null) {
      for (final r in _bandRoles!) {
        if (r.id == bandRoleId) return r.name;
      }
    }
    return bandRoleId;
  }

  IconData _iconForRoleName(String roleName) {
    final n = roleName.toLowerCase();
    // Specific mappings based on provided roles list
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
    // Generic fallbacks
    if (n.contains('producer') || n.contains('production')) return Icons.equalizer;
    if (n.contains('dj')) return Icons.headset;
    if (n.contains('music')) return Icons.music_note;
    return Icons.person;
  }

  Widget _buildTags() {
    if (_options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('Wybierz tagi:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(onPressed: _loadOptions, child: const Text('Załaduj tagi')),
              const SizedBox(width: 12),
              Expanded(child: Text(_status.isEmpty ? '(brak tagów)' : _status)),
            ],
          ),
        ],
      );
    }
    final categories = _options.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Wybierz tagi:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...categories.map((cat) {
          final selectedSet = _selected[cat] ?? {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_humanize(cat), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showTagPicker(cat),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Kliknij, aby wybrać',
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(selectedSet.isEmpty ? '(brak wybranych)' : '${selectedSet.length} wybranych')),
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
                    final found = _options[cat]!.firstWhere((o) => o['value'] == val, orElse: () => {'label': val.toString()});
                    final label = found['label']?.toString() ?? val.toString();
                    return InputChip(
                      label: Text(label),
                      onDeleted: () {
                        setState(() {
                          _selected[cat]?.remove(val);
                        });
                      },
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
Widget _buildBandMembersSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      const Text('Band members', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),

      if (_bandMembers.isEmpty)
        const Text('(no members added)', style: TextStyle(color: Colors.grey)),

      ..._bandMembers.map((m) => ListTile(
        title: Text('${m.name} (${m.age} y/o)'),
        subtitle: Text('Role: ${m.bandRoleId} • Order: ${m.displayOrder}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editBandMember(m)),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeBandMember(m)),
          ],
        ),
      )),

      const SizedBox(height: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add member'),
        onPressed: _addBandMember,
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final showNav = !_isEditing; // hide nav during editing
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _isEditing
          ? AppBar(
              title: Text(widget.isSettingsEdit ? 'Edit Profile' : (_currentStep == 1 ? 'Profile - Step 1' : 'Profile - Step 2')),
              automaticallyImplyLeading: !_isFromRegistration, // No back button during registration
              leading: _currentStep == 2 && !_isFromRegistration
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() => _currentStep = 1);
                      },
                    )
                  : null,
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false, // No back arrow on navbar screens
              title: const Text('Your Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black),
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
      body: _isEditing
          ? _buildEditingView()
          : Stack(
              children: [
                Positioned.fill(child: _buildProfileView()),
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

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture (use first uploaded photo if available)
          Builder(builder: (context) {
            final String? avatarUrl = _profilePictures.isNotEmpty
                ? _profilePictures.first.getAbsoluteUrl(widget.api.baseUrl)
                : null;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                    : null,
              ),
            );
          }),
          const SizedBox(height: 16),
          // Name
          Text(
            _name.text.isEmpty ? 'Your Name' : _name.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Location with icon
          if (_city.text.isNotEmpty || _country.text.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  [
                    if (_city.text.isNotEmpty) _city.text,
                    if (_country.text.isNotEmpty) _country.text,
                  ].join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          const SizedBox(height: 4),
          // Birth Date (for artists)
          if (_birthDate != null)
            Text(
              _birthDate!.toIso8601String().split('T').first.replaceAll('-', '/'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 24),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.purple[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Your Info',
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            color: _selectedTab == 0 ? Colors.purple : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.purple[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Multimedia',
                          style: TextStyle(
                            fontWeight: FontWeight.w600, 
                            color: _selectedTab == 1 ? Colors.purple : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _selectedTab == 0 ? _buildYourInfoTab() : _buildMultimediaTab(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _populateSelectedTags() {
    // Map user tag IDs to _selected for edit mode
    _selected.clear();
    
    for (final tagId in _userTagIds) {
      // Find which category this tag belongs to
      for (final entry in _tagGroups.entries) {
        final tag = entry.value.firstWhere(
          (t) => t.id == tagId,
          orElse: () => TagDto(id: '', name: '', tagCategoryId: ''),
        );
        
        if (tag.id.isNotEmpty) {
          final categoryName = _categoryNames[entry.key];
          if (categoryName != null) {
            _selected.putIfAbsent(categoryName, () => {});
            _selected[categoryName]!.add(tagId);
          }
          break;
        }
      }
    }
    
    // Trigger UI update
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, List<String>> _groupUserTags() {
    if (_userTagIds.isEmpty || _tagGroups.isEmpty) {
      return {};
    }

    final Map<String, List<String>> grouped = {};

    for (final tagId in _userTagIds) {
      String? categoryId;
      String? tagName;

      for (final entry in _tagGroups.entries) {
        final tag = entry.value.firstWhere(
              (t) => t.id == tagId,
          orElse: () => TagDto(id: '', name: '', tagCategoryId: ''),
        );
        if (tag.id.isNotEmpty) {
          categoryId = entry.key;
          tagName = tag.name;
          break;
        }
      }

      if (categoryId != null && tagName != null) {
        final categoryName = _categoryNames[categoryId] ?? 'Other';
        grouped.putIfAbsent(categoryName, () => []);
        grouped[categoryName]!.add(tagName);
      }
    }

    return grouped;
  }

  Widget _buildYourInfoTab() {
    final tagGroups = _groupUserTags();
    final orderedCategories = ['Instruments', 'Genres', 'Activity', 'Collaboration type'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Section
        if (_desc.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ABOUT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _desc.text,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800], height: 1.5),
                ),
              ],
            ),
          ),
        // Tags Section with Edit functionality
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TAGS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                        _currentStep = 2;
                      });
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tagGroups.isEmpty)
                Text(
                  'No tags added yet',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                )
              else
                for (final category in orderedCategories)
                  if (tagGroups.containsKey(category) && tagGroups[category]!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var tagName in tagGroups[category]!)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              tagName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
              const SizedBox(height: 16),
              if (_isBand == true && _bandMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'BAND MEMBERS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ..._bandMembers.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // role icon avatar
                      Builder(builder: (context) {
                        final roleName = _bandRoleName(m.bandRoleId);
                        final icon = _iconForRoleName(roleName);
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: Colors.deepPurple.shade400,
                            size: 20,
                          ),
                        );
                      }),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.name}${m.age > 0 ? ' (${m.age})' : ''}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Role: ${_bandRoleName(m.bandRoleId)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultimediaTab() {
    return Column(
      children: [
                  // Photos Section - Grid with existing pictures + Add button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Photos & Videos',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _profilePictures.length + 1, // +1 for add button
                          itemBuilder: (context, index) {
                            if (index == _profilePictures.length) {
                              // Add button
                              return InkWell(
                                onTap: () async {
                                  await _pick();
                                  if (_pickedFiles.isNotEmpty) {
                                    setState(() => _status = 'Uploading ${_pickedFiles.length} file(s)...');
                                    for (final file in _pickedFiles) {
                                      String uploadName = file.name;
                                      final extMatch = RegExp(r'^(.+?)\.(jpg|jpeg|mp3|mp4)$', caseSensitive: false)
                                          .firstMatch(uploadName);
                                      if (extMatch != null) {
                                        uploadName = extMatch.group(0)!;
                                      } else {
                                        final bytes = file.bytes!;
                                        if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
                                          uploadName = uploadName.trim();
                                          if (!uploadName.toLowerCase().endsWith('.jpg') &&
                                              !uploadName.toLowerCase().endsWith('.jpeg')) {
                                            uploadName = '$uploadName.jpg';
                                          }
                                        } else {
                                          setState(() => _status = 'Invalid file format');
                                          continue;
                                        }
                                      }
                                      final streamed = await widget.api.uploadProfilePicture(file.bytes!, uploadName);
                                      await streamed.stream.bytesToString();
                                      if (!mounted) return;
                                      if (streamed.statusCode == 200) {
                                        setState(() => _status = 'File uploaded successfully!');
                                      } else {
                                        setState(() => _status = 'Upload failed: ${streamed.statusCode}');
                                      }
                                    }
                                    setState(() => _pickedFiles = []);
                                    // Reload full profile to get updated pictures and samples
                                    await _loadProfile();
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, size: 32, color: Colors.grey[600]),
                                      const SizedBox(height: 4),
                                      Text('Add', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Display existing picture
              final picture = _profilePictures[index];
              final url = picture.getAbsoluteUrl(widget.api.baseUrl);
              final fileName = picture.fileUrl.split('/').last;
                            final isVideo = fileName.toLowerCase().endsWith('.mp4') || fileName.toLowerCase().endsWith('.mp3');
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: !isVideo
                                    ? Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Icon(
                                          Icons.videocam,
                                          size: 32,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Welcome Message - show only for new users (coming from registration)
                  if (widget.startInEditMode)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B68EE), Color(0xFF9D7FEE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome to Soundmates!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              children: [
                                const TextSpan(text: 'Make sure to '),
                                const TextSpan(
                                  text: 'add some photos, videos or audio',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(
                                    text:
                                        ' to show them how you rock!\nYou can customize your tags in the '),
                                const TextSpan(
                                  text: 'Your info',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' section too!'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                  _currentStep = 1;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Let's go!"),
                            ),
                          ),
                        ],
                      ),
                    ),
      ],
    );
  }

  Widget _buildEditingView() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Step 1: Basic Info
            if (_currentStep == 1) ...[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              // Artist vs Band selection (only during onboarding)
              if (!widget.isSettingsEdit)
                Row(children: [
                  const Expanded(child: Text('Account type:')),
                  Row(children: [ 
                    Radio<bool?>(
                      value: false, 
                      groupValue: _isBand, 
                      onChanged: (v) {
                        setState(() => _isBand = v);
                        _loadOptions(); // Reload tag categories when changing account type
                      },
                    ),
                    const Text('Artist'),
                    const SizedBox(width: 8),
                    Radio<bool?>(
                      value: true, 
                      groupValue: _isBand,      
                      onChanged: (v) {
                        setState(() => _isBand = v);
                        _loadOptions(); // Reload tag categories when changing account type
                      },
                    ),
                    const Text('Band'),
                  ])
                ]),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCountryPicker,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCountry?.name.isNotEmpty == true ? _selectedCountry!.name : 'Tap to choose',
                          style: TextStyle(color: _selectedCountry == null ? Colors.grey[600] : Colors.black),
                        ),
                      ),
                      const Icon(Icons.search),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showCityPicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'City',
                    border: const OutlineInputBorder(),
                    suffixIcon: _citiesLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedCity?.name.isNotEmpty == true
                              ? _selectedCity!.name
                              : (_selectedCountry == null
                                  ? 'Select country first'
                                  : (_citiesLoading
                                      ? 'Loading cities...'
                                      : (_cities.isEmpty ? 'No cities available' : 'Tap to choose'))),
                          style: TextStyle(
                            color: _selectedCity == null ? Colors.grey[600] : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // (Removed inline city preview by request; no map after selection.)
              // Artist-only fields: birthDate and gender
              if (_isBand != true) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
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
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Birth date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Tap to select date'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                      style: TextStyle(
                        color: _birthDate == null ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedGender?.id,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: _genders
                      .map((g) => DropdownMenuItem<String>(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: (id) => setState(() {
                    if (id == null) {
                      _selectedGender = null;
                    } else {
                      // pick the matching instance from _genders to keep DTOs consistent
                      final match = _genders.firstWhere(
                        (g) => g.id == id,
                        orElse: () => GenderDto(id: id, name: id),
                      );
                      _selectedGender = match;
                    }
                  }),
                ),
              ],
              const SizedBox(height: 12),
              if (widget.isSettingsEdit)
                ElevatedButton(
                  onPressed: () async {
                    final nameErr = validateName(_name.text);
                    if (nameErr != null) return setState(() => _status = nameErr);
                    final cityValue = _selectedCity?.name ?? _city.text;
                    final countryValue = _selectedCountry?.name ?? _country.text;
                    final cityErr = validateCityOrCountry(cityValue, 'City');
                    if (cityErr != null) return setState(() => _status = cityErr);
                    final countryErr = validateCityOrCountry(countryValue, 'Country');
                    if (countryErr != null) return setState(() => _status = countryErr);
                    if (_isBand != true) {
                      if (_birthDate == null) return setState(() => _status = 'Birth date is required for artists');
                      if (_selectedGender == null) return setState(() => _status = 'Gender is required for artists');
                    }
                    await _save();
                  },
                  child: const Text('Save'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    final nameErr = validateName(_name.text);
                    if (nameErr != null) return setState(() => _status = nameErr);
                    final cityValue = _selectedCity?.name ?? _city.text;
                    final countryValue = _selectedCountry?.name ?? _country.text;
                    final cityErr = validateCityOrCountry(cityValue, 'City');
                    if (cityErr != null) return setState(() => _status = cityErr);
                    final countryErr = validateCityOrCountry(countryValue, 'Country');
                    if (countryErr != null) return setState(() => _status = countryErr);
                    if (_isBand != true) {
                      if (_birthDate == null) return setState(() => _status = 'Birth date is required for artists');
                      if (_selectedGender == null) return setState(() => _status = 'Gender is required for artists');
                    }
                    setState(() {
                      _currentStep = 2;
                      _status = '';
                    });
                  },
                  child: const Text('Next'),
                ),
            ],
            // Step 2: Tags, Description, Band Members, Profile Photo
            if (_currentStep == 2) ...[
              TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              _buildTags(),
              if (_isBand == true) _buildBandMembersSection(),
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
                    const Text('Profile photo (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickProfilePhoto,
                          icon: const Icon(Icons.photo),
                          label: const Text('Choose photo'),
                        ),
                        const SizedBox(width: 12),
                        if (_pickedProfilePhoto != null)
                          Expanded(
                            child: Row(
                              children: [
                                if (_pickedProfilePhoto?.bytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _pickedProfilePhoto!.bytes!,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pickedProfilePhoto!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() => _pickedProfilePhoto = null),
                                ),
                              ],
                            ),
                          )
                        else
                          Text('No file selected', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentStep = 1);
                    },
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final descErr = validateDescription(_desc.text);
                        if (descErr != null) return setState(() => _status = descErr);
                        _save();
                      },
                      child: const Text('Complete Profile'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(_status),
          ],
        )
      ),
    );
  }
}
