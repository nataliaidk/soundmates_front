import 'package:flutter/material.dart';
import 'package:zpi_test/api/api_client.dart';
import 'package:dropdown_search/dropdown_search.dart';


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
    _loadFilterData();
    _loadCurrentPreferences();
    _loadGenders();
  }

  Future<void> _loadFilterData() async {
    try {
      final [countriesRes, tagsRes, categoriesRes] = await Future.wait([
        widget.api.getCountries(),
        widget.api.getTags(),
        widget.api.getTagCategories(),
      ]);

      if (!mounted) return;

      dynamic decodeBody(String body) {
        var decoded = jsonDecode(body);
        if (decoded is String) return jsonDecode(decoded);
        return decoded;
      }

      if (countriesRes.statusCode == 200) {
        final data = decodeBody(countriesRes.body) as List;
        _countries = data.map((e) => CountryDto.fromJson(e)).toList();
      }

      List<TagDto> allTags = [];
      if (tagsRes.statusCode == 200) {
        final data = decodeBody(tagsRes.body) as List;
        allTags = data.map((e) => TagDto.fromJson(e)).toList();
      }

      List<TagCategoryDto> allCategories = [];
      if (categoriesRes.statusCode == 200) {
        final data = decodeBody(categoriesRes.body) as List;
        allCategories = data.map((e) => TagCategoryDto.fromJson(e)).toList();
      }

      final Map<String, List<TagDto>> groups = {};
      if (allCategories.isNotEmpty && allTags.isNotEmpty) {
        for (final category in allCategories) {
          print('Processing category: ${category.name} : ${category.id}'); // Debug print
          final categoryTags = allTags.where((t) => t.tagCategoryId == category.id).toList();
          if (categoryTags.isNotEmpty) {
            groups[category.name] = categoryTags;
          }
        }
      } else if (allTags.isNotEmpty) {
        groups['Tags'] = allTags; // Fallback if no categories
      }

      setState(() {
        _tagGroups.clear();
        _tagGroups.addAll(groups);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading filter data: $e')),
        );
      }
    }
  }

  Future<void> _loadCurrentPreferences() async {
    try {
      final resp = await widget.api.getMatchPreference();

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('Loaded preferences: $data'); // Debug print

        final prefs = MatchPreferenceDto.fromJson(data);

        setState(() {
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

          // Load selected tags into groups
          if (prefs.filterTagsIds != null) {
            for (final tagId in prefs.filterTagsIds!) {
              // Find which category this tag belongs to
              for (final entry in _tagGroups.entries) {
                if (entry.value.any((t) => t.id == tagId)) {
                  _selectedTags[entry.key] ??= {};
                  _selectedTags[entry.key]!.add(tagId);
                  break;
                }
              }
            }
          }

        });

        // Load cities if country is selected
        if (prefs.countryId != null) {
          await _onCountryChanged(prefs.countryId);
        }
      }
    } catch (e) {
      print('Error loading current preferences: $e');
    }
  }

  Future<void> _loadGenders() async {
    try {
      final resp = await widget.api.getGenders();
      if (resp.statusCode == 200) {
        var decoded = jsonDecode(resp.body);
        if (decoded is String) decoded = jsonDecode(decoded);
        final List<GenderDto> list = [];
        if (decoded is List) {
          for (final e in decoded) {
            if (e is Map) list.add(GenderDto.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        setState(() => _genders = list);
      }
    } catch (_) {
      // ignore
    }
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
          // Filter options based on search query
          final filteredOptions = options.where((tag) {
            return tag.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            title: Text('Select ${category == 'Activity' ? 'Who you are looking for' : category}'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                  // List of filtered tags
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: filteredOptions.map((tag) {
                          final isSelected = currentSelection.contains(tag.id);
                          return CheckboxListTile(
                            title: Text(tag.name),
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setDialogState(() {
                                if (selected == true) {
                                  currentSelection.add(tag.id);
                                } else {
                                  currentSelection.remove(tag.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(currentSelection), child: const Text('OK')),
            ],
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

  Widget _buildTagSection(String category) {
    final options = _tagGroups[category] ?? [];
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedIds = _selectedTags[category] ?? {};
    final selectedTagObjects = options.where((t) => selectedIds.contains(t.id)).toList();

    // The category 'Looking for' is named 'Activity' in profile_screen
    final categoryTitle = category == 'Activity' ? 'Who are you looking for?' : category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(categoryTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showTagPicker(category, options),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.all(12.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: selectedTagObjects.isNotEmpty
                      ? Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: selectedTagObjects.map((tag) {
                      return InputChip(
                        label: Text(tag.name),
                        onDeleted: () {
                          setState(() {
                            _selectedTags[category]?.remove(tag.id);
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.all(2.0),
                      );
                    }).toList(),
                  )
                      : const Text('Select...'),
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // In _FiltersScreenState class, replace the current build method content with:

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4C9C);
    const backgroundColor = Color(0xFFF8F4FF);
    const textColor = Color(0xFF3D2C5E);
    const cardColor = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _resetPreferences,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset',
          ),
          TextButton.icon(
            onPressed: _savePreferences,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _savePreferences,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Save Filters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'Customize your match preferences',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your potential matches will be suggested based on these preferences.',
              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Artist/Band Selector Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('Looking For', Icons.search),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPillButton('Artists', Icons.person, _showArtists && !_showBands, primaryColor, () {
                        setState(() {
                          _showArtists = true;
                          _showBands = false;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildPillButton('Both', Icons.group, _showArtists && _showBands, primaryColor, () {
                        setState(() {
                          _showArtists = true;
                          _showBands = true;
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildPillButton('Bands', Icons.groups, _showBands && !_showArtists, primaryColor, () {
                        setState(() {
                          _showArtists = false;
                          _showBands = true;
                        });
                      }),
                    ],
                  ),



                ],
              ),
            ),
            const SizedBox(height: 16),

            // Distance Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('Maximum Distance', Icons.location_on),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: (_maxDistance ?? 500).toDouble(),
                          min: 0,
                          max: 500,
                          divisions: 50, // 10 km increments
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withOpacity(0.2),
                          onChanged: (double value) {
                            setState(() {
                              // Set to null if at maximum (500), otherwise use 350 as max actual value
                              if (value >= 500) {
                                _maxDistance = null;
                              } else {
                                _maxDistance = value.round();
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          _maxDistance == null ? '500+ km' : '${_maxDistance} km',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Location Card
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardTitle('Location', Icons.map),
                  const SizedBox(height: 16),
                  _buildEnhancedDropdown(
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
                  _buildEnhancedDropdown(
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Artist-specific filters
            if (_showArtists) ...[
              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTitle('Age Range', Icons.cake),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                        (_artistMinAge ?? 18).toDouble(),
                        (_artistMaxAge ?? 99).toDouble(),
                      ),
                      min: 18,
                      max: 99,
                      divisions: 81,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _artistMinAge = values.start.round();
                          _artistMaxAge = values.end.round();
                        });
                      },
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_artistMinAge ?? 18} - ${_artistMaxAge ?? 99} years',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_tagGroups.containsKey('Instruments'))
                _buildTagCard('Instruments', Icons.music_note),

              if (_tagGroups.containsKey('Activity'))
                _buildTagCard('Activity', Icons.star),
            ],

            // Band-specific filters
            if (_showBands) ...[
              if (_tagGroups.containsKey('Band Status'))
                _buildTagCard('Band Status', Icons.info_outline),

              const SizedBox(height: 16),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardTitle('Band Members', Icons.groups),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(
                        (_bandMinMembersCount ?? 1).toDouble(),
                        (_bandMaxMembersCount ?? 10).toDouble(),
                      ),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: primaryColor,
                      inactiveColor: primaryColor.withOpacity(0.2),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _bandMinMembersCount = values.start.round();
                          _bandMaxMembersCount = values.end.round();
                        });
                      },
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_bandMinMembersCount ?? 1} - ${_bandMaxMembersCount ?? 10} members',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Other tag sections
            ..._tagGroups.entries
                .where((entry) =>
            entry.key != 'Instruments' &&
                entry.key != 'Activity' &&
                entry.key != 'Band Status')
                .map((entry) => _buildTagCard(entry.key, Icons.label)),

            // Location Card
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: child,
    );
  }

  Widget _buildCardTitle(String title, IconData icon) {
    const primaryColor = Color(0xFF6A4C9C);
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTagCard(String category, IconData icon) {
    final options = _tagGroups[category] ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    final selectedIds = _selectedTags[category] ?? {};
    final selectedTagObjects = options.where((t) => selectedIds.contains(t.id)).toList();
    final categoryTitle = category == 'Activity' ? 'Who are you looking for?' : category;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(categoryTitle, icon),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showTagPicker(category, options),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
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
                            backgroundColor: const Color(0xFF6A4C9C).withOpacity(0.1),
                            deleteIconColor: const Color(0xFF6A4C9C),
                            labelStyle: const TextStyle(color: Color(0xFF6A4C9C)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      )
                          : Text(
                        'Tap to select',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDropdown({
    required List<DropdownMenuItem<String>> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    required IconData icon,
  }) {
    const primaryColor = Color(0xFF6A4C9C);
    const textColor = Color(0xFF3D2C5E);

    // Convert DropdownMenuItem to Map for easier lookup
    final itemsMap = {
      for (var item in items) item.value!: (item.child as Text).data!
    };

    // Ensure the selected value exists in the items map
    final safeValue = value != null && itemsMap.containsKey(value) ? value : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownSearch<String>(
              items: itemsMap.keys.toList(),
              selectedItem: safeValue,
              onChanged: onChanged,
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              dropdownBuilder: (context, selectedItem) {
                if (selectedItem == null || !itemsMap.containsKey(selectedItem)) {
                  return Text(
                    hint,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  );
                }
                return Text(
                  itemsMap[selectedItem]!,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Text(
                      itemsMap[item] ?? '',
                      style: TextStyle(
                        color: isSelected ? primaryColor : textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 15,
                      ),
                    ),
                  );
                },
              ),
              dropdownButtonProps: const DropdownButtonProps(
                icon: Icon(Icons.keyboard_arrow_down, color: primaryColor),
              ),
              itemAsString: (item) => itemsMap[item] ?? '',
            ),
          ),
        ],
      ),
    );
  }








  Widget _buildSectionTitle(String title, Color color) {
    return Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildChoiceChipGroup(
      {required List<String> options, required String? selectedValue, required Function(String) onSelected, required Color primaryColor}) {
    return Wrap(
      spacing: 8.0,
      children: options.map((option) {
        return ChoiceChip(
          label: Text(option),
          selected: selectedValue == option,
          onSelected: (selected) {
            if (selected) onSelected(option);
          },
          selectedColor: primaryColor.withOpacity(0.2),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(color: selectedValue == option ? primaryColor : Colors.black),
          shape: StadiumBorder(side: BorderSide(color: primaryColor.withOpacity(0.3))),
        );
      }).toList(),
    );
  }


  Widget _buildDropdown(
      {required List<DropdownMenuItem<String>> items,
        required String? value,
        required ValueChanged<String?> onChanged,
        required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.0), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items,
          onChanged: onChanged,
          hint: Text(hint),
        ),
      ),
    );
  }

  Widget _buildPillButton(String label, IconData icon, bool isSelected, Color primaryColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : primaryColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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