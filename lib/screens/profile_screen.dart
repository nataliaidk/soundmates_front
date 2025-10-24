import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api/api_client.dart';
import '../api/token_store.dart';
import '../api/models.dart';
import '../utils/validators.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const ProfileScreen({super.key, required this.api, required this.tokens});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  PlatformFile? _picked;
  String _status = '';

  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  CountryDto? _selectedCountry;
  CityDto? _selectedCity;
  bool? _isBand;

  // artist fields
  DateTime? _birthDate;
  List<GenderDto> _genders = [];
  GenderDto? _selectedGender;

  bool _isEditing = false; // Track edit mode
  Map<String, List<Map<String, dynamic>>> _options = {};
  // map categoryName -> set of selected values
  final Map<String, Set<dynamic>> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadProfile(); // Load user profile data on initialization
    _loadCountries();
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
        for (final c in cats) {
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
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _picked = res.files.first);
    }
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
    // build DTO with IDs below (dtoWithTags)

    final allSelected = _selected.values.expand((s) => s).map((v) => v.toString()).toList();
    // For artists, server requires birthDate and genderId. Validate and include.
    if (_isBand != true) {
      if (_birthDate == null) return setState(() => _status = 'Birth date is required for artists');
      if (_selectedGender == null) return setState(() => _status = 'Gender is required for artists');
    }

    final dtoWithTags = UpdateUserProfileDto(
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
    // DEBUG: print request body
    try {
      final dbg = jsonEncode(dtoWithTags.toJson());
      // ignore: avoid_print
      print('PUT /users/profile BODY: $dbg');
    } catch (_) {}
    final resp = await widget.api.updateUserWithTags(dtoWithTags, allSelected.isEmpty ? null : allSelected);
    try {
      final respBody = resp.body;
      // ignore: avoid_print
      print('PUT /users/profile RESP: ${resp.statusCode} - $respBody');
    } catch (_) {}
    setState(() => _status = 'Profile update: ${resp.statusCode}');
    if (resp.statusCode == 200) {
      if (_picked?.bytes != null) {
        String uploadName = _picked!.name;
        final nameMatch = RegExp(r'^(.+?\.(jpg|jpeg))', caseSensitive: false).firstMatch(uploadName);
        if (nameMatch != null) {
          uploadName = nameMatch.group(1)!;
        } else {
          final bytes = _picked!.bytes!;
          if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
            uploadName = uploadName.trim();
            if (!uploadName.toLowerCase().endsWith('.jpg') && !uploadName.toLowerCase().endsWith('.jpeg')) {
              uploadName = '$uploadName.jpg';
            }
          } else {
            return setState(() => _status = 'Allowed file extensions: .jpeg, .jpg');
          }
        }

        final streamed = await widget.api.uploadProfilePicture(_picked!.bytes!, uploadName);
        final body = await streamed.stream.bytesToString();
        if (!mounted) {
          return;
        }
        setState(() => _status += ' ; upload: ${streamed.statusCode} - $body');
        if (streamed.statusCode == 200) {
          if (!mounted) {
            return;
          }
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (!mounted) {
          return;
        }
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isEditing) ...[
                Text('Name: ${_name.text}', style: const TextStyle(fontSize: 16)),
                Text('Description: ${_desc.text}', style: const TextStyle(fontSize: 16)),
                Text('City: ${_city.text}', style: const TextStyle(fontSize: 16)),
                Text('Country: ${_country.text}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isEditing = true); 
                  },
                  child: const Text('Edit Profile'),
                ),
              ] else ...[
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                // Artist vs Band selection
                Row(children: [
                  Expanded(child: Text('Account type:')),
                  Row(children: [
                    Radio<bool?>(value: false, groupValue: _isBand, onChanged: (v) => setState(() => _isBand = v),),
                    const Text('Artist'),
                    const SizedBox(width: 8),
                    Radio<bool?>(value: true, groupValue: _isBand, onChanged: (v) => setState(() => _isBand = v),),
                    const Text('Band'),
                  ])
                ]),
                const SizedBox(height: 8),
                DropdownButtonFormField<CountryDto>(
                  initialValue: _selectedCountry,
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
                  initialValue: _selectedCity,
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
                    initialValue: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ],
                _buildTags(),
                const SizedBox(height: 8),
                Row(children: [ElevatedButton(onPressed: _pick, child: const Text('Pick Photo')), const SizedBox(width: 8), Text(_picked?.name ?? '(no file)')]),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _save();
                  },
                  child: const Text('Save'),
                ),
              ],
              const SizedBox(height: 12),
              Text(_status),
            ],
          ),
        ),
      ),
    );
  }
}
