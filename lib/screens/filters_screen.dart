import 'package:flutter/material.dart';
import 'package:zpi_test/api/api_client.dart';

import '../api/models.dart';
import '../api/token_store.dart';
import 'dart:convert';

extension LetExtension<T> on T {
  R let<R>(R Function(T) transform) => transform(this);
}

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

  final Map<String, List<TagDto>> _tagGroups = {};
  final Map<String, Set<String>> _selectedTags = {};

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
          final categoryTags = allTags.where((t) => t.tagCategoryId == category.id).toList();
          if (categoryTags.isNotEmpty) {
            groups[category.name] = categoryTags;
          }
        }
      } else if (allTags.isNotEmpty) {
        groups['Tags'] = allTags;
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

          if (prefs.filterTagsIds != null) {
            for (final tagId in prefs.filterTagsIds!) {
              for (final entry in _tagGroups.entries) {
                final tag = entry.value.firstWhere(
                      (t) => t.id == tagId,
                  orElse: () => TagDto(id: '', name: '', tagCategoryId: ''),
                );
                if (tag.id.isNotEmpty) {
                  _selectedTags.putIfAbsent(entry.key, () => {}).add(tagId);
                  break;
                }
              }
            }
          }
        });

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
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    try {
      final allSelectedTagIds = _selectedTags.values.expand((set) => set).toList();

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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Preferences saved!', style: TextStyle(fontSize: 16)),
              ],
            ),
            backgroundColor: const Color(0xFF6A4C9C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
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
      _selectedCityId = null;
      _cities = [];
      _isLoading = true;
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
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          final filteredOptions = options.where((tag) {
            return tag.name.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getIconForCategory(category), color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select $category',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2C5E),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF6A4C9C)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4C9C)),
                      filled: true,
                      fillColor: const Color(0xFFF8F5FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF6A4C9C).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF6A4C9C).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF6A4C9C),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: filteredOptions.isEmpty
                        ? const Center(
                      child: Text(
                        'No results found',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 14,
                        ),
                      ),
                    )
                        : ListView(
                      shrinkWrap: true,
                      children: filteredOptions.map((tag) {
                        final isSelected = currentSelection.contains(tag.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isSelected) {
                                    currentSelection.remove(tag.id);
                                  } else {
                                    currentSelection.add(tag.id);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF6A4C9C).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6A4C9C)
                                        : const Color(0xFF6A4C9C).withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? const Color(0xFF6A4C9C) : const Color(0xFF9E9E9E),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        tag.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? const Color(0xFF6A4C9C) : const Color(0xFF3D2C5E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, currentSelection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A4C9C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Done', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
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


  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'genre':
        return Icons.music_note;
      case 'instrument':
        return Icons.piano;
      case 'activity':
        return Icons.directions_run;
      default:
        return Icons.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildLookingForCard(),
                  const SizedBox(height: 20),
                  _buildDistanceCard(),
                  const SizedBox(height: 20),
                  _buildLocationCard(),
                  const SizedBox(height: 20),
                  _buildAgeRangeCard(),
                  const SizedBox(height: 20),
                  _buildGenderCard(),
                  const SizedBox(height: 20),
                  _buildBandMembersCard(),
                  for (final category in _tagGroups.keys)
                    _buildTagCard(category, _getIconForCategory(category)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePreferences,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A4C9C),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      'Save Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Artist Gender', Icons.wc),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (_genders.isEmpty) return;
              final result = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  String searchQuery = '';
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      final filtered = _genders.where((g) => g.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.wc, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Select Artist Gender',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3D2C5E),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, color: Color(0xFF6A4C9C)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search...',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4C9C)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8F5FF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF6A4C9C).withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF6A4C9C).withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    borderSide: BorderSide(
                                      color: Color(0xFF6A4C9C),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (v) => setDialogState(() => searchQuery = v),
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: filtered.map((g) {
                                    final isSelected = _selectedGenderId == g.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.pop(context, g.id),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF6A4C9C).withOpacity(0.1)
                                                  : const Color(0xFFF8F5FF),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF6A4C9C)
                                                    : const Color(0xFF6A4C9C).withOpacity(0.2),
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    g.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      color: isSelected ? const Color(0xFF6A4C9C) : const Color(0xFF3D2C5E),
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(Icons.check_circle, color: Color(0xFF6A4C9C), size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (result != null) {
                setState(() => _selectedGenderId = result);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF6A4C9C).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.wc, color: Color(0xFF6A4C9C), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _selectedGenderId != null
                          ? (_genders.firstWhere((g) => g.id == _selectedGenderId, orElse: () => _genders.first).name)
                          : 'Select Artist Gender',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedGenderId != null ? const Color(0xFF3D2C5E) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF6A4C9C)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4C9C).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match Preferences',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2C5E),
                    ),
                  ),
                  Text(
                    'Customize your perfect match',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMasterpieceCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAF8FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A4C9C).withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            spreadRadius: -5,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6A4C9C).withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }

  Widget _buildCardTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF6A4C9C), size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3D2C5E),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLookingForCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Looking For', Icons.search),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6A4C9C).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                _buildSegmentButton('Artists', 'artists', Icons.person),
                const SizedBox(width: 8),
                _buildSegmentButton('Bands', 'bands', Icons.groups),
                const SizedBox(width: 8),
                _buildSegmentButton('Both', 'both', Icons.people),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, String value, IconData icon) {
    final isSelected = (value == 'artists' && _showArtists && !_showBands) ||
        (value == 'bands' && _showBands && !_showArtists) ||
        (value == 'both' && _showArtists && _showBands);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showArtists = value == 'artists' || value == 'both';
            _showBands = value == 'bands' || value == 'both';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
              colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
            )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: const Color(0xFF6A4C9C).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistanceCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Maximum Distance', Icons.near_me),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF6A4C9C),
              inactiveTrackColor: const Color(0xFF6A4C9C).withOpacity(0.15),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFF6A4C9C).withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: Slider(
              value: (_maxDistance ?? 0).toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: (value) => setState(() => _maxDistance = value.round()),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A4C9C).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_maxDistance ?? 0} km',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4C9C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Age Range', Icons.cake),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF6A4C9C),
              inactiveTrackColor: const Color(0xFF6A4C9C).withOpacity(0.15),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 4,
              ),
              overlayColor: const Color(0xFF6A4C9C).withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: RangeSlider(
              values: RangeValues(
                (_artistMinAge ?? 18).toDouble(),
                (_artistMaxAge ?? 99).toDouble(),
              ),
              min: 18,
              max: 99,
              divisions: 81,
              onChanged: (values) {
                setState(() {
                  _artistMinAge = values.start.round();
                  _artistMaxAge = values.end.round();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A4C9C).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_artistMinAge ?? 18} - ${_artistMaxAge ?? 99} years',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4C9C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandMembersCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Band Members', Icons.groups),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: const Color(0xFF6A4C9C),
              inactiveTrackColor: const Color(0xFF6A4C9C).withOpacity(0.15),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 4,
              ),
              overlayColor: const Color(0xFF6A4C9C).withOpacity(0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            ),
            child: RangeSlider(
              values: RangeValues(
                (_bandMinMembersCount ?? 1).toDouble(),
                (_bandMaxMembersCount ?? 10).toDouble(),
              ),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (values) {
                setState(() {
                  _bandMinMembersCount = values.start.round();
                  _bandMaxMembersCount = values.end.round();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A4C9C).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_bandMinMembersCount ?? 1} - ${_bandMaxMembersCount ?? 10} members',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A4C9C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(String category, IconData icon) {
    final options = _tagGroups[category] ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    final selectedIds = _selectedTags[category] ?? {};
    final selectedTagObjects = options.where((t) => selectedIds.contains(t.id)).toList();
    final categoryTitle = category == 'Activity' ? 'Who are you looking for?' : category;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _buildMasterpieceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardTitle(categoryTitle, icon),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showTagPicker(category, options),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F5FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF6A4C9C).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: selectedTagObjects.isEmpty
                      ? Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: const Color(0xFF6A4C9C).withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Text(
                        'Select $categoryTitle',
                        style: TextStyle(
                          color: const Color(0xFF6A4C9C).withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                      : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: selectedTagObjects.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6A4C9C).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          tag.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return _buildMasterpieceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTitle('Location', Icons.location_on),
          const SizedBox(height: 20),
          _buildSearchableDropdown(
            items: _countries,
            value: _selectedCountryId,
            onChanged: (value) async {
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
            getName: (country) => country.name,
            getId: (country) => country.id,
          ),
          const SizedBox(height: 16),
          _buildSearchableDropdown(
            items: _cities,
            value: _selectedCityId,
            onChanged: (value) => setState(() => _selectedCityId = value),
            hint: 'Select City',
            icon: Icons.location_city,
            getName: (city) => city.name,
            getId: (city) => city.id,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown<T>({
    required List<T> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    required String hint,
    required IconData icon,
    required String Function(T) getName,
    required String Function(T) getId,
  }) {
    return GestureDetector(
      onTap: () async {
        if (items.isEmpty) return;

        final result = await showDialog<String>(
          context: context,
          builder: (ctx) {
            String searchQuery = '';
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final filteredItems = items.where((item) {
                  return getName(item).toLowerCase().contains(searchQuery.toLowerCase());
                }).toList();

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6A4C9C), Color(0xFF8B6BB7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hint,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2C5E),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Color(0xFF6A4C9C)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF6A4C9C)),
                            filled: true,
                            fillColor: const Color(0xFFF8F5FF),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFF6A4C9C).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: const Color(0xFF6A4C9C).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFF6A4C9C),
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: filteredItems.isEmpty
                              ? const Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 16,
                              ),
                            ),
                          )
                              : ListView(
                            shrinkWrap: true,
                            children: filteredItems.map((item) {
                              final itemId = getId(item);
                              final isSelected = value == itemId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context, itemId);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6A4C9C).withOpacity(0.1)
                                            : const Color(0xFFF8F5FF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6A4C9C)
                                              : const Color(0xFF6A4C9C).withOpacity(0.2),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              getName(item),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? const Color(0xFF6A4C9C)
                                                    : const Color(0xFF3D2C5E),
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF6A4C9C),
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

        if (result != null) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF6A4C9C).withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F5FF), Color(0xFFEDE7F6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF6A4C9C), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                value != null
                    ? items.firstWhere((item) => getId(item) == value, orElse: () => items.first).let((item) => getName(item))
                    : hint,
                style: TextStyle(
                  fontSize: 16,
                  color: value != null ? const Color(0xFF3D2C5E) : const Color(0xFF9E9E9E),
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: const Color(0xFF6A4C9C),
            ),
          ],
        ),
      ),
    );
  }
}
