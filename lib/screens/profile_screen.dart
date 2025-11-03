import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final bool startInEditMode;
  
  const ProfileScreen({
    super.key, 
    required this.api, 
    required this.tokens,
    this.startInEditMode = false,
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
  String _status = '';

  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  CountryDto? _selectedCountry;
  CityDto? _selectedCity;
  bool? _isBand;
  List<BandMemberDto> _bandMembers = [];
  List<BandRoleDto> ? _bandRoles = [];

  // Profile pictures and music samples
  List<Map<String, dynamic>> _profilePictures = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _musicSamples = [];

  // artist fields
  DateTime? _birthDate;
  List<GenderDto> _genders = [];
  GenderDto? _selectedGender;

  bool _isEditing = false; // Track edit mode
  int _currentStep = 1; // 1 = basic info, 2 = tags/files/description/members
  Map<String, List<Map<String, dynamic>>> _options = {};
  // map categoryName -> set of selected values
  final Map<String, Set<dynamic>> _selected = {};

  @override
  void initState() {
    super.initState();
    _isEditing = widget.startInEditMode; // Start in edit mode if coming from registration
    _loadOptions();
    _loadProfile(); // Load user profile data on initialization
    _loadCountries();
    _loadBandRoles();
    _loadProfilePictures();
  }

  Future<void> _loadProfilePictures() async {
    // This is now handled by _loadProfile() which gets the full profile with pictures and samples
    // Keeping this method for compatibility but it does nothing
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
      
        for (final c in filteredCats) {
          print('Category: ${c.name} (${c.id}) - isForBand: ${c.isForBand}');
          final List<Map<String, dynamic>> opts = [];
          final ctTags = tags.where((t) => t.tagCategoryId == c.id).toList();
          for (final t in ctTags) {
            opts.add({'value': t.id, 'label': t.name});
          }
          if (opts.isNotEmpty) groups[c.name] = opts;
        }
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
        List<Map<String, dynamic>> pictures = [];
        if (profile['profilePictures'] is List) {
          for (final pic in profile['profilePictures']) {
            if (pic is Map) {
              pictures.add(Map<String, dynamic>.from(pic));
            }
          }
        }

        List<Map<String, dynamic>> samples = [];
        if (profile['musicSamples'] is List) {
          for (final sample in profile['musicSamples']) {
            if (sample is Map) {
              samples.add(Map<String, dynamic>.from(sample));
            }
          }
        }

        CountryDto? selCountry;
        if (cid != null && cid.isNotEmpty && _countries.isNotEmpty) {
          selCountry = _countries.firstWhere((c) => c.id == cid, orElse: () => _countries.first);
        } else if (countryVal != null && countryVal.isNotEmpty && _countries.isNotEmpty) {
          selCountry = _countries.firstWhere((c) => c.name == countryVal, orElse: () => _countries.first);
        }

        // enrich picture objects with usable URLs if backend returned only id/file
        pictures = await _enrichPicturesWithUrls(pictures);

        setState(() {
          _name.text = nameVal;
          _desc.text = descVal;
          _city.text = cityVal;
          _country.text = countryVal;
          _selectedCountry = selCountry;
          _profilePictures = pictures;
          _musicSamples = samples;
          _isBand = profile['isBand'] is bool ? profile['isBand'] as bool : (profile['isBand']?.toString().toLowerCase() == 'true');
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
            });
          }
        }
      } else {
        setState(() => _status = 'Failed to load profile: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error loading profile');
    }
  }

  // Merge URLs from profile-pictures endpoint into profile['profilePictures'] items
  Future<List<Map<String, dynamic>>> _enrichPicturesWithUrls(List<Map<String, dynamic>> pics) async {
    try {
      // Build an ID->url map from the dedicated endpoint which is known to return URL
      final resp = await widget.api.getProfilePictures(limit: 100, offset: 0);
      final urlById = <String, String>{};
      if (resp.statusCode == 200) {
        var dec = jsonDecode(resp.body);
        if (dec is String) dec = jsonDecode(dec);
        if (dec is List) {
          for (final e in dec) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e);
              final id = m['id']?.toString();
              final url = m['url']?.toString();
              if (id != null && url != null && url.isNotEmpty) urlById[id] = url;
            }
          }
        }
      }

      // Produce enriched list
      return pics.map((p) {
        final m = Map<String, dynamic>.from(p);
        final id = m['id']?.toString();
        final file = m['file']?.toString();
        // Prefer existing url
        var url = m['url']?.toString();
        // If not present, try to derive from file or lookup by id
        url ??= (file != null && file.startsWith('http')) ? file : null;
        if (url == null && id != null && urlById.containsKey(id)) {
          url = urlById[id];
        }
        // Fallback heuristic: common REST pattern to fetch file by id
        if (url == null && id != null) {
          url = Uri.parse(widget.api.baseUrl).resolve('profile-pictures/file/$id').toString();
        }
        m['url'] = url;
        // Normalize fileName for UI hints
        if (m['fileName'] == null && file != null) m['fileName'] = file.split('/').last;
        return m;
      }).toList();
    } catch (_) {
      // On any error, just return the original list
      return pics;
    }
  }

  Future<void> _loadCitiesForSelectedCountry(String countryId) async {
    try {
      final resp = await widget.api.getCities(countryId);
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<CityDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(CityDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        setState(() => _cities = list);
      }
    } catch (_) {
      // ignore
    }
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



  Future<void> _save() async {
    final nameErr = validateName(_name.text);
    if (nameErr != null) return setState(() => _status = nameErr);
    final descErr = validateDescription(_desc.text);
    if (descErr != null) return setState(() => _status = descErr);
    final cityValue = _selectedCity?.name ?? _city.text;
    final countryValue = _selectedCountry?.name ?? _country.text;
    final cityErr = validateCityOrCountry(cityValue, 'City');
    if (cityErr != null) return setState(() => _status = cityErr);
    final countryErr = validateCityOrCountry(countryValue, 'Country');
    if (countryErr != null) return setState(() => _status = countryErr);

    setState(() => _status = 'Saving...');
    final allSelected = _selected.values.expand((s) => s).map((v) => v.toString()).toList();
    if (_isBand != true) {
      if (_birthDate == null) return setState(() => _status = 'Birth date is required for artists');
      if (_selectedGender == null) return setState(() => _status = 'Gender is required for artists');
    }

  if (_isBand == true) {
      final dtoWithTags = UpdateBandProfile(
        isBand: _isBand,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        countryId: _selectedCountry?.id ?? '',
        cityId: _selectedCity?.id ?? '',
        tagsIds: allSelected,
        musicSamplesOrder: const [],
        profilePicturesOrder: const [],
        bandMembers: _bandMembers,
      );
      final resp = await widget.api.updateBandProfile(dtoWithTags, allSelected.isEmpty ? null : allSelected);
      setState(() => _status = 'Profile update: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        if (_pickedFiles.isNotEmpty) {
          for (final file in _pickedFiles) {
            String uploadName = file.name;
            final extMatch = RegExp(r'^(.+?)\.(jpg|jpeg|mp3|mp4)$', caseSensitive: false).firstMatch(uploadName);
            if (extMatch != null) {
              uploadName = extMatch.group(0)!;
            } else {
              final bytes = file.bytes!;
              // JPEG magic number
              if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
                uploadName = uploadName.trim();
                if (!uploadName.toLowerCase().endsWith('.jpg') && !uploadName.toLowerCase().endsWith('.jpeg')) {
                  uploadName = '$uploadName.jpg';
                }
              } else {
                setState(() => _status = 'Allowed file extensions: .jpeg, .jpg, .mp3, .mp4');
                continue;
              }
            }
            final streamed = await widget.api.uploadProfilePicture(file.bytes!, uploadName);
            final body = await streamed.stream.bytesToString();
            if (!mounted) return;
            setState(() => _status += ' ; upload: ${streamed.statusCode} - $body');
          }
          await _goToProfileView();
        } else {
          if (!mounted) return;
          await _goToProfileView();
        }
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
        musicSamplesOrder: const [],
        profilePicturesOrder: const [],
      );
      final resp = await widget.api.updateArtistProfile(dtoWithTags, allSelected.isEmpty ? null : allSelected);
      setState(() => _status = 'Profile update: ${resp.statusCode}');
      if (resp.statusCode == 200) {
        if (_pickedFiles.isNotEmpty) {
          for (final file in _pickedFiles) {
            String uploadName = file.name;
            final extMatch = RegExp(r'^(.+?)\.(jpg|jpeg|mp3|mp4)$', caseSensitive: false).firstMatch(uploadName);
            if (extMatch != null) {
              uploadName = extMatch.group(0)!;
            } else {
              final bytes = file.bytes!;
              if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
                uploadName = uploadName.trim();
                if (!uploadName.toLowerCase().endsWith('.jpg') && !uploadName.toLowerCase().endsWith('.jpeg')) {
                  uploadName = '$uploadName.jpg';
                }
              } else {
                setState(() => _status = 'Allowed file extensions: .jpeg, .jpg, .mp3, .mp4');
                continue;
              }
            }
            final streamed = await widget.api.uploadProfilePicture(file.bytes!, uploadName);
            final body = await streamed.stream.bytesToString();
            if (!mounted) return;
            setState(() => _status += ' ; upload: ${streamed.statusCode} - $body');
          }
          await _goToProfileView();
        } else {
          if (!mounted) return;
          await _goToProfileView();
        }
      } else {
        return;
      }
    }
  }

  Future<void> _goToProfileView() async {
    // Reload full profile to reflect latest data, then switch to view mode
    await _loadProfile();
    if (!mounted) return;
    setState(() {
      _isEditing = false;
      _currentStep = 1;
    });
  }
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
                  displayOrder: member?.displayOrder ?? 0,
                  bandId: 'TEMP',       // backend overwrites
                  bandRoleId: selectedRole!.id, // ✅ roleId taken from dropdown
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

  Widget _buildTags() {
    // if not loaded yet, show button to reload
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _isEditing
          ? AppBar(
              title: Text(_currentStep == 1 ? 'Profile - Step 1' : 'Profile - Step 2'),
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Your Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _currentStep = 1;
                    });
                  },
                ),
              ],
            ),
      body: _isEditing ? _buildEditingView() : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Picture
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple, width: 3),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _name.text.isEmpty ? 'Your Name' : _name.text,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // Location
          Text(
            '${_city.text.isEmpty ? 'City' : _city.text}, ${_country.text.isEmpty ? 'Country' : _country.text}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], letterSpacing: 1.2),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Your Info',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Multimedia',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
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
              child: Column(
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
              final url = (picture['url'] as String?) ?? (picture['file'] is String && (picture['file'] as String).startsWith('http') ? picture['file'] as String : null) ?? (picture['id'] != null ? Uri.parse(widget.api.baseUrl).resolve('profile-pictures/file/${picture['id']}').toString() : null);
              final fileName = (picture['fileName'] as String?) ?? (picture['file'] as String?);
                            final isVideo = fileName != null && 
                                (fileName.toLowerCase().endsWith('.mp4') || fileName.toLowerCase().endsWith('.mp3'));
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: url != null && !isVideo
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
                                          isVideo ? Icons.videocam : Icons.image,
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
                  if (_name.text.isEmpty || _desc.text.isEmpty)
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
                  // Description Section
                  if (_desc.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _desc.text,
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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
              // Artist vs Band selection
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
              DropdownButtonFormField<CountryDto>(
                value: _selectedCountry,
                decoration: const InputDecoration(labelText: 'Country', border: OutlineInputBorder()),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) async {
                  setState(() {
                    _selectedCountry = v;
                    _selectedCity = null;
                    _cities = [];
                    _country.text = v?.name ?? '';
                  });
                  if (v != null) await _loadCitiesForSelectedCountry(v.id);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<CityDto>(
                value: _selectedCity,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCity = v;
                    _city.text = v?.name ?? '';
                  });
                },
              ),
              // Artist-only fields: birthDate and gender
              if (_isBand != true) ...[
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Birth date', border: OutlineInputBorder()),
                  child: Row(children: [
                    Expanded(child: Text(_birthDate == null ? '(not set)' : _birthDate!.toIso8601String().split('T').first)),
                    TextButton(onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(context: context, initialDate: _birthDate ?? DateTime(now.year - 20), firstDate: DateTime(1900), lastDate: now);
                      if (picked != null) setState(() => _birthDate = picked);
                    }, child: const Text('Pick'))
                  ]),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<GenderDto>(
                  value: _selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ],
              const SizedBox(height: 12),
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
            // Step 2: Tags, Files, Description, Band Members
            if (_currentStep == 2) ...[
              TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              _buildTags(),
              if (_isBand == true) _buildBandMembersSection(),
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(onPressed: _pick, child: const Text('Pick Photo(s)')),
                const SizedBox(width: 8),
                if (_pickedFiles.isEmpty)
                  const Text('(no files)')
                else
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: _pickedFiles.map((f) => Chip(label: Text(f.name))).toList(),
                    ),
                  ),
              ]),
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
                        setState(() => _isEditing = false);
                        _save();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
