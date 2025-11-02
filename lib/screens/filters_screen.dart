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

  // State variables to hold filter values
  double _distance = 50.0;
  RangeValues _ageRange = const RangeValues(21, 37);
  String? _selectedCountryId;
  String? _selectedCityId;

  // New state for tags
  // map categoryName -> list of tags in that category
  final Map<String, List<TagDto>> _tagGroups = {};
  // map categoryName -> set of selected tag IDs
  final Map<String, Set<String>> _selectedTags = {};

  // Data from API
  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];

  // Placeholder data for "Looking for"
  final List<String> _lookingForOptions = ['Musician', 'Band', 'Producer', 'Vocalist'];


  @override
  void initState() {
    super.initState();
    _loadFilterData();
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

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Select ${category == 'Activity' ? 'Who you are looking for' : category}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((tag) {
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

  @override
  Widget build(BuildContext context) {
    // Define colors from the mockup for reusability
    const primaryColor = Color(0xFF6A4C9C);
    const backgroundColor = Color(0xFFF8F4FF);
    const textColor = Color(0xFF3D2C5E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 30),
            onPressed: () {
              // TODO: Implement save logic
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your potential matches will be suggested based on those preferences.',
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Distance Slider
            _buildSectionTitle('Distance', textColor),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _distance,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: '${_distance.round()} km',
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    onChanged: (double value) {
                      setState(() {
                        _distance = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${_distance.round()} km', style: const TextStyle(color: textColor)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Age Range Slider
            _buildSectionTitle('Age', textColor),
            RangeSlider(
              values: _ageRange,
              min: 18,
              max: 99,
              divisions: 81,
              labels: RangeLabels(
                _ageRange.start.round().toString(),
                _ageRange.end.round().toString(),
              ),
              activeColor: primaryColor,
              inactiveColor: primaryColor.withOpacity(0.3),
              onChanged: (RangeValues values) {
                setState(() {
                  _ageRange = values;
                });
              },
            ),
            const SizedBox(height: 30),

            // Dynamically build tag sections
            ..._tagGroups.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: _buildTagSection(entry.key),
              );
            }),

            // Country Dropdown
            _buildSectionTitle('Country', textColor),
            _buildDropdown(
                items: _countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                value: _selectedCountryId,
                onChanged: _onCountryChanged,
                hint: 'Select Country'),
            const SizedBox(height: 30),

            // City Dropdown
            _buildSectionTitle('City', textColor),
            _buildDropdown(
                items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                value: _selectedCityId,
                onChanged: (val) => setState(() => _selectedCityId = val),
                hint: 'Select City'),
          ],
        ),
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
}
