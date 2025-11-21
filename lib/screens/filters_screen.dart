import 'package:flutter/material.dart';
import 'package:zpi_test/api/api_client.dart';

import '../api/models.dart';
import '../api/token_store.dart';
import 'dart:convert';

class FiltersScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  const FiltersScreen({super.key, required this.api, required this.tokens});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  bool _isLoading = true;

  bool _showArtists = true;
  bool _showBands = true;
  int? _maxDistance;
  String? _selectedGenderId;
  int? _artistMinAge;
  int? _artistMaxAge;
  int? _bandMinMembersCount;
  int? _bandMaxMembersCount;
  String? _selectedCountryId;
  String? _selectedCityId;
  GenderDto? _selectedGender;

  // New state for tags
  // map categoryName -> list of tags in that category
  final Map<String, List<TagDto>> _tagGroups = {};
  // map categoryName -> set of selected tag IDs
  final Map<String, Set<String>> _selectedTags = {};

  // Data from API
  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  List<GenderDto> _genders = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        widget.api.getCountries(),
        widget.api.getTags(),
        widget.api.getTagCategories(),
        widget.api.getGenders(),
        widget.api.getMatchPreference(),
      ]);

      if (!mounted) return;

      final [countriesRes, tagsRes, categoriesRes, gendersRes, prefsRes] = results;

      // Process countries
      if (countriesRes.statusCode == 200) {
        final data = _decodeBody(countriesRes.body) as List;
        _countries = data.map((e) => CountryDto.fromJson(e)).toList();
      }

      // Process tags
      List<TagDto> allTags = [];
      if (tagsRes.statusCode == 200) {
        final data = _decodeBody(tagsRes.body) as List;
        allTags = data.map((e) => TagDto.fromJson(e)).toList();
      }

      // Process categories
      List<TagCategoryDto> allCategories = [];
      if (categoriesRes.statusCode == 200) {
        final data = _decodeBody(categoriesRes.body) as List;
        allCategories = data.map((e) => TagCategoryDto.fromJson(e)).toList();
      }

      // Process genders
      if (gendersRes.statusCode == 200) {
        var decoded = _decodeBody(gendersRes.body);
        if (decoded is List) {
          _genders = decoded.map((e) => GenderDto.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }

      // Build tag groups
      final Map<String, List<TagDto>> groups = {};
      for (final category in allCategories) {
        final categoryTags = allTags.where((t) => t.tagCategoryId == category.id).toList();
        if (categoryTags.isNotEmpty) {
          groups[category.name] = categoryTags;
        }
      }
      _tagGroups.clear();
      _tagGroups.addAll(groups);

      // Process preferences
      MatchPreferenceDto? prefs;
      if (prefsRes.statusCode == 200) {
        final data = jsonDecode(prefsRes.body);
        prefs = MatchPreferenceDto.fromJson(data);
      }

      // Load cities if country is selected (sequential, but only if needed)
      if (prefs?.countryId != null) {
        try {
          final citiesRes = await widget.api.getCities(prefs!.countryId!);
          if (mounted && citiesRes.statusCode == 200) {
            final cities = (_decodeBody(citiesRes.body) as List)
                .map((data) => CityDto.fromJson(data))
                .toList();
            _cities = cities;
          }
        } catch (e) {
          print('Error loading cities: $e');
        }
      }

      // Apply preferences (single setState)
      if (prefs != null) {
        _showArtists = prefs.showArtists ?? true;
        _showBands = prefs.showBands ?? true;
        _maxDistance = prefs.maxDistance;
        _selectedCountryId = prefs.countryId;
        _selectedCityId = prefs.cityId;
        _artistMinAge = prefs.artistMinAge;
        _artistMaxAge = prefs.artistMaxAge;
        _selectedGenderId = prefs.artistGenderId;
        _bandMinMembersCount = prefs.bandMinMembersCount;
        _bandMaxMembersCount = prefs.bandMaxMembersCount;

        if (prefs.filterTagsIds != null) {
          for (final tagId in prefs.filterTagsIds!) {
            for (final entry in _tagGroups.entries) {
              if (entry.value.any((t) => t.id == tagId)) {
                _selectedTags[entry.key] ??= {};
                _selectedTags[entry.key]!.add(tagId);
                break;
              }
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  dynamic _decodeBody(String body) {
    var decoded = jsonDecode(body);
    if (decoded is String) return jsonDecode(decoded);
    return decoded;
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    try {
      final allSelectedTagIds = _selectedTags.values
          .expand((set) => set)
          .toList();

      final dto = UpdateMatchPreferenceDto(
        showArtists: _showArtists,
        showBands: _showBands,
        maxDistance: _maxDistance,
        countryId: _selectedCountryId,
        cityId: _selectedCityId,
        artistMinAge: _artistMinAge,
        artistMaxAge: _artistMaxAge,
        artistGenderId: _selectedGenderId,
        bandMinMembersCount: _bandMinMembersCount,
        bandMaxMembersCount: _bandMaxMembersCount,
        filterTagsIds: allSelectedTagIds,
      );

      final resp = await widget.api.updateMatchPreference(dto);

      if (!mounted) return;

      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCountryChanged(String? countryId) async {
    if (countryId == null || countryId == _selectedCountryId) return;

    setState(() {
      _selectedCountryId = countryId;
      _selectedCityId = null; // Reset city selection
      _cities = []; // Clear previous cities
      _isLoading = true; // Show loading indicator for cities
    });

    try {
      final res = await widget.api.getCities(countryId);
      if (!mounted) return;

      final cities = (jsonDecode(res.body) as List).map((data) => CityDto.fromJson(data)).toList();
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load cities: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showTagPicker(String category, List<TagDto> options) async {
    final currentSelection = Set<String>.from(_selectedTags[category] ?? {});
    String searchQuery = '';

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final filteredOptions = options.where((tag) {
            return tag.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          final dialogTitle = 'Select ${category == 'Activity' ? 'Who you are looking for' : category}';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
                maxWidth: 900,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE7DBFF),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dialogTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D1B4E),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: Color(0xFF7A5AD7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name...',
                        hintStyle: const TextStyle(color: Color(0xFF8B78C8)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF7A5AD7)),
                        filled: true,
                        fillColor: const Color(0xFFF3ECFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      onChanged: (value) => setDialogState(() => searchQuery = value),
                    ),
                    if (currentSelection.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentSelection.map((tagId) {
                          final tag = options.firstWhere((t) => t.id == tagId, orElse: () => TagDto(id: tagId, name: tagId));
                          return Chip(
                            label: Text(tag.name, style: const TextStyle(color: Color(0xFF2D1B4E))),
                            backgroundColor: const Color(0xFFD7C4FF),
                            deleteIcon: const Icon(Icons.close, size: 16, color: Color(0xFF2D1B4E)),
                            onDeleted: () => setDialogState(() => currentSelection.remove(tagId)),
                          );
                        }).toList(),
                      ),
                    ] else
                      const SizedBox(height: 14),
                    const Divider(height: 32, color: Color(0xFFE2D5FF)),
                    Expanded(
                      child: filteredOptions.isEmpty
                          ? const Center(
                              child: Text(
                                'No matches for your search.',
                                style: TextStyle(color: Color(0xFF7A5AD7), fontWeight: FontWeight.w600),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filteredOptions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) {
                                final tag = filteredOptions[index];
                                final isSelected = currentSelection.contains(tag.id);
                                return InkWell(
                                  onTap: () => setDialogState(() {
                                    if (isSelected) {
                                      currentSelection.remove(tag.id);
                                    } else {
                                      currentSelection.add(tag.id);
                                    }
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFCDB7FF)
                                          : const Color(0xFFF2EBFF),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF5F3BCB) : const Color(0xFFD3C1FF),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                          color: isSelected ? const Color(0xFF5F3BCB) : const Color(0xFFA495D9),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            tag.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: const Color(0xFF1F123A),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.keyboard_arrow_right, color: Color(0xFF6F4BD8)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF5F3BCB), fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F3BCB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(currentSelection),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (result != null) {
      setState(() {
        _selectedTags[category] = result;
      });
    }
  }

  // In _FiltersScreenState class, replace the current build method content with:

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4C9C);
    const backgroundColor = Color(0xFF2D1B4E);
    const cardColor = Color(0xFF3D2C5E);
    const textColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/users'),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _resetPreferences,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
        children: [
          // Main scrollable content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 475),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main card container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header text
                            const Text(
                              'Customize your match preferences',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your potential matches will be suggested based on these preferences.',
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Looking For Section
                            Row(
                              children: [
                                const Icon(Icons.search, color: textColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Looking For',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPurpleButton(
                                    'Artists',
                                    Icons.person,
                                    _showArtists && !_showBands,
                                        () {
                                      setState(() {
                                        _showArtists = true;
                                        _showBands = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPurpleButton(
                                    'Both',
                                    Icons.group,
                                    _showArtists && _showBands,
                                        () {
                                      setState(() {
                                        _showArtists = true;
                                        _showBands = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildPurpleButton(
                                    'Bands',
                                    Icons.groups,
                                    _showBands && !_showArtists,
                                        () {
                                      setState(() {
                                        _showArtists = false;
                                        _showBands = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Maximum Distance Section
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: textColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Maximum Distance',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.3),
                                thumbColor: Colors.white,
                                overlayColor: Colors.white.withOpacity(0.2),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: (_maxDistance ?? 500).toDouble(),
                                min: 0,
                                max: 500,
                                divisions: 50,
                                onChanged: (double value) {
                                  setState(() {
                                    if (value >= 500) {
                                      _maxDistance = null;
                                    } else {
                                      _maxDistance = value.round();
                                    }
                                  });
                                },
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _maxDistance == null ? '500+ km' : '$_maxDistance km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Location Section
                            Row(
                              children: [
                                const Icon(Icons.public, color: textColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Location',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPurpleDropdown(
                              items: _countries
                                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                  .toList(),
                              value: _selectedCountryId,
                              onChanged: (String? value) async {
                                if (value != null) {
                                  await _onCountryChanged(value);
                                } else {
                                  setState(() {
                                    _selectedCountryId = null;
                                    _selectedCityId = null;
                                    _cities = [];
                                  });
                                }
                              },
                              hint: 'Select Country',
                              icon: Icons.public,
                            ),
                            const SizedBox(height: 12),
                            _buildPurpleDropdown(
                              items: _cities
                                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                  .toList(),
                              value: _selectedCityId,
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedCityId = value;
                                });
                              },
                              hint: 'Select City',
                              icon: Icons.location_city,
                            ),
                            const SizedBox(height: 24),

                            // Age Range (if showing artists)
                            if (_showArtists) ...[
                              Row(
                                children: [
                                  const Icon(Icons.cake, color: textColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Age Range',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.2),
                                  trackHeight: 4,
                                ),
                                child: RangeSlider(
                                  values: RangeValues(
                                    (_artistMinAge ?? 18).toDouble(),
                                    (_artistMaxAge ?? 99).toDouble(),
                                  ),
                                  min: 18,
                                  max: 99,
                                  divisions: 81,
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _artistMinAge = values.start.round();
                                      _artistMaxAge = values.end.round();
                                    });
                                  },
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_artistMinAge ?? 18} - ${_artistMaxAge ?? 99} years',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Instruments (if showing artists)
                            if (_showArtists && _tagGroups.containsKey('Instruments'))
                              _buildPurpleTagSection('Instruments', Icons.music_note),

                            // Activity (if showing artists)
                            if (_showArtists && _tagGroups.containsKey('Activity'))
                              _buildPurpleTagSection('Activity', Icons.star),

                            // Band Status (if showing bands)
                            if (_showBands && _tagGroups.containsKey('Band Status'))
                              _buildPurpleTagSection('Band Status', Icons.info_outline),

                            // Band Members (if showing bands)
                            if (_showBands) ...[
                              Row(
                                children: [
                                  const Icon(Icons.groups, color: textColor, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Band Members',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.2),
                                  trackHeight: 4,
                                ),
                                child: RangeSlider(
                                  values: RangeValues(
                                    (_bandMinMembersCount ?? 1).toDouble(),
                                    (_bandMaxMembersCount ?? 10).toDouble(),
                                  ),
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _bandMinMembersCount = values.start.round();
                                      _bandMaxMembersCount = values.end.round();
                                    });
                                  },
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_bandMinMembersCount ?? 1} - ${_bandMaxMembersCount ?? 10} members',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Other tag sections
                            ..._tagGroups.entries
                                .where((entry) =>
                            entry.key != 'Instruments' &&
                                entry.key != 'Activity' &&
                                entry.key != 'Band Status')
                                .map((entry) => _buildPurpleTagSection(entry.key, Icons.label)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Save Button Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text(
                          'Save Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPurpleButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF6A4C9C) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6A4C9C) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurpleDropdown({
    required List<DropdownMenuItem<String>> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    required IconData icon,
  }) {
    final itemsMap = {
      for (var item in items) item.value!: (item.child as Text).data!
    };
    final selectedText = value != null && itemsMap.containsKey(value)
        ? itemsMap[value]
        : null;

    return InkWell(
      onTap: () => _showSearchableDropdown(
        items: itemsMap,
        currentValue: value,
        hint: hint,
        icon: icon,
        onChanged: onChanged,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedText ?? hint,
                style: TextStyle(
                  color: selectedText != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearchableDropdown({
    required Map<String, String> items,
    required String? currentValue,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) async {
    String searchQuery = '';
    String? selectedValue = currentValue;

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Filter items based on search query
            final filteredItems = items.entries.where((entry) {
              return entry.value.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF3D2C5E),
              title: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Select $hint',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Clear selection option
                    if (currentValue != null)
                      ListTile(
                        leading: const Icon(Icons.clear, color: Colors.white70),
                        title: const Text(
                          'Clear selection',
                          style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop('__CLEAR__');
                        },
                      ),
                    const Divider(color: Colors.white24),
                    // List of filtered items
                    Flexible(
                      child: filteredItems.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No results found',
                          style: TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final entry = filteredItems[index];
                          final isSelected = entry.key == selectedValue;

                          return ListTile(
                            title: Text(
                              entry.value,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF6A4C9C) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Color(0xFF6A4C9C))
                                : null,
                            onTap: () {
                              Navigator.of(ctx).pop(entry.key);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      if (result == '__CLEAR__') {
        onChanged(null);
      } else {
        onChanged(result);
      }
    }
  }

  Widget _buildPurpleTagSection(String category, IconData icon) {
    final options = _tagGroups[category] ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    final selectedIds = _selectedTags[category] ?? {};
    final selectedTagObjects = options.where((t) => selectedIds.contains(t.id)).toList();
    final categoryTitle = category == 'Activity' ? 'Who are you looking for?' : category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              categoryTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _showTagPicker(category, options),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedTagObjects.isNotEmpty
                      ? Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: selectedTagObjects.map((tag) {
                      return Chip(
                        label: Text(tag.name, style: const TextStyle(fontSize: 13)),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedTags[category]?.remove(tag.id);
                          });
                        },
                        backgroundColor: Colors.white,
                        deleteIconColor: const Color(0xFF6A4C9C),
                        labelStyle: const TextStyle(color: Color(0xFF6A4C9C)),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  )
                      : Text(
                    'Tap to select',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }


  Future<void> _resetPreferences() async {
    setState(() => _isLoading = true);

    try {
      final dto = UpdateMatchPreferenceDto(
        showArtists: true,
        showBands: true,
        maxDistance: null,
        countryId: null,
        cityId: null,
        artistMinAge: null,
        artistMaxAge: null,
        artistGenderId: null,
        bandMinMembersCount: null,
        bandMaxMembersCount: null,
        filterTagsIds: [],
      );

      final resp = await widget.api.updateMatchPreference(dto);

      if (!mounted) return;

      if (resp.statusCode == 200) {
        // Reset local state
        setState(() {
          _showArtists = true;
          _showBands = true;
          _maxDistance = null;
          _selectedGenderId = null;
          _artistMinAge = null;
          _artistMaxAge = null;
          _bandMinMembersCount = null;
          _bandMaxMembersCount = null;
          _selectedCountryId = null;
          _selectedCityId = null;
          _selectedGender = null;
          _selectedTags.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Filters reset!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${resp.statusCode} ${resp.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

}