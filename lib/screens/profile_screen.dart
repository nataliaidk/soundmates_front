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
  final _year = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  PlatformFile? _picked;
  String _status = '';

  bool _isEditing = false; // Track edit mode
  Map<String, List<Map<String, dynamic>>> _options = {};
  // map categoryName -> set of selected values
  final Map<String, Set<dynamic>> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
    _loadProfile(); // Load user profile data on initialization
  }

  Future<void> _loadOptions() async {
    try {
      setState(() => _status = 'Loading options...');
      final resp = await widget.api.getUserOptions();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }

        final Map<String, List<Map<String, dynamic>>> groups = {};

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
          if (groups.isEmpty) {
            final keysToCheck = ['options', 'data', 'items', 'tags', 'result', 'activityTypes', 'genres', 'instruments'];
            for (final k in keysToCheck) {
              if (decoded.containsKey(k) && decoded[k] is List) {
                final v = decoded[k] as List;
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
            }
          }
        }
        if (decoded is List && decoded.isNotEmpty) {
          final List<Map<String, dynamic>> opts = [];
          for (final e in decoded) {
            if (e is String) {
              opts.add({'value': e, 'label': e});
            } else if (e is Map) {
              final label = e['name'] ?? e['label'] ?? e['text'] ?? e['value'];
              final value = e['value'] ?? label;
              if (label != null) opts.add({'value': value, 'label': label.toString()});
            }
          }
          if (opts.isNotEmpty) groups['tags'] = opts;
        }

        setState(() {
          _options = groups;
          _status = groups.isEmpty ? 'No options available' : '';
        });
      } else {
        setState(() => _status = 'Failed to load options: ${resp.statusCode}');
      }
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
          _year.text = profile['birthYear']?.toString() ?? '';
          _city.text = profile['city'] ?? '';
          _country.text = profile['country'] ?? '';
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

  Future<void> _save() async {
    final nameErr = validateName(_name.text);
    if (nameErr != null) return setState(() => _status = nameErr);
    final descErr = validateDescription(_desc.text);
    if (descErr != null) return setState(() => _status = descErr);
    final yearErr = validateBirthYear(_year.text);
    if (yearErr != null) return setState(() => _status = yearErr);
    final cityErr = validateCityOrCountry(_city.text, 'City');
    if (cityErr != null) return setState(() => _status = cityErr);
    final countryErr = validateCityOrCountry(_country.text, 'Country');
    if (countryErr != null) return setState(() => _status = countryErr);

    setState(() => _status = 'Saving...');
    final dto = UpdateUserProfileDto(
      name: _name.text.trim(),
      description: _desc.text.trim(),
      birthYear: int.parse(_year.text.trim()),
      city: _city.text.trim(),
      country: _country.text.trim(),
    );

    final allSelected = _selected.values.expand((s) => s).map((v) => v.toString()).toList();
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
        }).toList(),
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
                Text('Birth Year: ${_year.text}', style: const TextStyle(fontSize: 16)),
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
                TextField(controller: _year, decoration: const InputDecoration(labelText: 'Birth Year'), keyboardType: TextInputType.number),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
                TextField(controller: _country, decoration: const InputDecoration(labelText: 'Country')),
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
