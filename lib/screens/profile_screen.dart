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
  // changed: birthDate (ISO yyyy-MM-dd) instead of birth year
  final _birthDate = TextEditingController();
  final _city = TextEditingController(); // will hold cityId or name depending on usage
  final _country = TextEditingController(); // will hold countryId or name depending on usage
  PlatformFile? _picked;
  String _status = '';

  bool _isEditing = false; // Track edit mode
  bool _isBand = false; // new: whether profile is a band
  int _step = 0; // 0 = details (name, birthDate, country, city, isBand), 1 = step2 (tags/about/photo)
  // map categoryName -> set of selected values
  final Map<String, Set<dynamic>> _selected = {};
  Map<String, List<Map<String, dynamic>>> _options = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadProfile(); // Load user profile data on initialization
  }

  Future<void> _loadOptions() async {
    try {
      setState(() => _status = 'Loading options...');
      // Fetch tags and categories separately (no getUserOptions)
      final tagsResp = await widget.api.getTags();
      final catsResp = await widget.api.getTagCategories();

      if (tagsResp.statusCode != 200 && catsResp.statusCode != 200) {
        setState(() => _status = 'Failed to load options: tags ${tagsResp.statusCode}, categories ${catsResp.statusCode}');
        return;
      }

      List<dynamic> tagsList = [];
      List<dynamic> catsList = [];
      try {
        if (tagsResp.statusCode == 200) tagsList = jsonDecode(tagsResp.body) as List<dynamic>;
      } catch (_) {}
      try {
        if (catsResp.statusCode == 200) catsList = jsonDecode(catsResp.body) as List<dynamic>;
      } catch (_) {}

      // build category id -> name map
      final Map<String, String> catNames = {};
      for (final c in catsList) {
        if (c is Map) {
          final id = c['id']?.toString();
          final name = c['name']?.toString();
          if (id != null && name != null) catNames[id] = name;
        }
      }

      // group tags by category name (fallback to 'tags' if unknown)
      final Map<String, List<Map<String, dynamic>>> groups = {};
      for (final t in tagsList) {
        if (t is Map) {
          final cid = t['tagCategoryId']?.toString();
          final label = (t['name'] ?? t['label'] ?? t['value'])?.toString() ?? '';
          final value = (t['id']?.toString() ?? label);
          final categoryName = cid != null ? (catNames[cid] ?? cid) : 'tags';
          groups.putIfAbsent(categoryName, () => []).add({'value': value, 'label': label});
        } else if (t is String) {
          groups.putIfAbsent('tags', () => []).add({'value': t, 'label': t});
        }
      }

      // ensure flat 'tags' group exists if nothing categorized it
      if (!groups.containsKey('tags') && tagsList.isNotEmpty) {
        final List<Map<String, dynamic>> flat = [];
        for (final t in tagsList) {
          if (t is Map) {
            final label = (t['name'] ?? t['label'] ?? t['value'])?.toString() ?? '';
            final value = (t['id']?.toString() ?? label);
            flat.add({'value': value, 'label': label});
          } else if (t is String) {
            flat.add({'value': t, 'label': t});
          }
        }
        if (flat.isNotEmpty) groups['tags'] = flat;
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
        setState(() {
          _name.text = profile['name'] ?? '';
          _desc.text = profile['description'] ?? '';
          // new API returns birthDate (ISO) or null
          _birthDate.text = profile['birthDate'] ?? profile['birth_date'] ?? '';
          // API uses countryId / cityId
          _city.text = profile['cityId'] ?? profile['city'] ?? '';
          _country.text = profile['countryId'] ?? profile['country'] ?? '';
          _isBand = profile['isBand'] == true;
          // populate selected tags if tagsIds exists
          if (profile['tagsIds'] is List) {
            final List t = profile['tagsIds'];
            _selected['tags'] = Set<dynamic>.from(t.where((e) => e != null).map((e) => e.toString()));
          }
          // if profile contains gender id, put into selected under 'genders' for single picker
          if (profile['artistGenderId'] != null) {
            _selected['genders'] = {profile['artistGenderId'].toString()};
          } else if (profile['genderId'] != null) {
            _selected['genders'] = {profile['genderId'].toString()};
          }
          _status = '';
        });
      } else {
        setState(() => _status = 'Failed to load profile: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _status = 'Error loading profile');
    }
  }

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (res != null && res.files.isNotEmpty) {
      setState(() => _picked = res.files.first);
    }
  }

  String? _validateBirthDate(String s) {
    if (s.trim().isEmpty) return null; // optional
    final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!re.hasMatch(s.trim())) return 'Data powinna być w formacie RRRR-MM-DD';
    // optional: basic range check
    final year = int.tryParse(s.trim().split('-').first) ?? 0;
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear) return 'Nieprawidłowy rok';
    return null;
  }

  Future<void> _save() async {
    final nameErr = validateName(_name.text);
    if (nameErr != null) return setState(() => _status = nameErr);
    final descErr = validateDescription(_desc.text);
    if (descErr != null) return setState(() => _status = descErr);
    final birthErr = _validateBirthDate(_birthDate.text);
    if (birthErr != null) return setState(() => _status = birthErr);
    final cityErr = validateCityOrCountry(_city.text, 'City');
    if (cityErr != null) return setState(() => _status = cityErr);
    final countryErr = validateCityOrCountry(_country.text, 'Country');
    if (countryErr != null) return setState(() => _status = countryErr);

    setState(() => _status = 'Saving...');
    // collect tagsIds from selections (flatten all categories, but prefer 'tags' if present)
    final allSelected = _selected.values.expand((s) => s).map((v) => v.toString()).toList();

    // determine gender selection (single)
    String? genderId;
    if (_selected.containsKey('genders') && _selected['genders']!.isNotEmpty) {
      genderId = _selected['genders']!.first.toString();
    }

    final dto = UpdateUserProfileDto(
      userType: _isBand ? 'band' : 'artist',
      birthDate: _birthDate.text.trim().isEmpty ? null : _birthDate.text.trim(),
      genderId: genderId,
      isBand: _isBand,
      name: _name.text.trim(),
      description: _desc.text.trim(),
      countryId: _country.text.trim().isEmpty ? null : _country.text.trim(),
      cityId: _city.text.trim().isEmpty ? null : _city.text.trim(),
      tagsIds: allSelected.isEmpty ? null : allSelected,
      musicSamplesOrder: null,
      profilePicturesOrder: null,
      bandMembers: null,
    );

    final resp = await widget.api.updateUserWithTags(dto, allSelected);
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

  // New: single-choice picker (returns single value)
  Future<dynamic> _showSinglePicker(String category) async {
    final opts = _options[category];
    if (opts == null || opts.isEmpty) return null;
    dynamic current = _selected[category]?.isNotEmpty == true ? _selected[category]!.first : null;
    final result = await showDialog<dynamic>(
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
                    return RadioListTile<dynamic>(
                      value: val,
                      groupValue: current,
                      title: Text(label),
                      onChanged: (v) {
                        setDialogState(() {
                          current = v;
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
        _selected[category] = {result};
      });
    }
    return result;
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
                onTap: () {
                  // for genders we use single picker
                  if (cat.toLowerCase().contains('gender')) {
                    _showSinglePicker(cat);
                  } else {
                    _showTagPicker(cat);
                  }
                },
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
    // Adjusted UI: when editing show multi-step editor, otherwise show read-only view
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
                Text('Birth Date: ${_birthDate.text}', style: const TextStyle(fontSize: 16)),
                Text('City: ${_city.text}', style: const TextStyle(fontSize: 16)),
                Text('Country: ${_country.text}', style: const TextStyle(fontSize: 16)),
                Text('Is Band: ${_isBand ? "Yes" : "No"}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _step = 0; // start at step 1
                    });
                  },
                  child: const Text('Edit Profile'),
                ),
              ] else ...[
                // Step 1 (now step==0): details (name, birthDate, country, city, isBand)
                if (_step == 0) ...[
                  const Text('Step 1 of 2', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: _birthDate, decoration: const InputDecoration(labelText: 'Birth Date (YYYY-MM-DD)')),
                  TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country (id or name)')),
                  TextField(controller: _city, decoration: const InputDecoration(labelText: 'City (id or name)')),
                  // isBand toggle
                  SwitchListTile(
                    title: const Text('Is Band'),
                    value: _isBand,
                    onChanged: (v) => setState(() => _isBand = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // cancel editing and go back to view
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // advance to tags step
                            setState(() => _step = 1);
                          },
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ],
                // Step 2 (now step==1): tags, about, photo and Save
                if (_step == 1) ...[
                  const Text('Step 2 of 2', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildTags(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _desc,
                    decoration: const InputDecoration(labelText: 'About you', hintText: 'Tell us a fun fact about you'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(onPressed: _pick, child: const Text('Pick Photo')),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_picked?.name ?? '(no file)')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // back to previous step (details)
                            setState(() => _step = 0);
                          },
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // finalize and save
                            setState(() => _isEditing = false);
                            _save();
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
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
