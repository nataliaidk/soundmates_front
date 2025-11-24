import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import 'profile_edit_step1.dart';
import '../../widgets/city_map_preview.dart';
import '../../theme/app_design_system.dart';

/// Screen for editing basic profile information (Step 1 fields) from Settings
class ProfileEditBasicInfoScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;

  const ProfileEditBasicInfoScreen({
    super.key,
    required this.api,
    required this.tokens,
  });

  @override
  State<ProfileEditBasicInfoScreen> createState() =>
      _ProfileEditBasicInfoScreenState();
}

class _ProfileEditBasicInfoScreenState
    extends State<ProfileEditBasicInfoScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

  bool? _isBand;
  CountryDto? _selectedCountry;
  CityDto? _selectedCity;
  DateTime? _birthDate;
  GenderDto? _selectedGender;

  List<CountryDto> _countries = [];
  List<CityDto> _cities = [];
  List<GenderDto> _genders = [];
  List<ProfilePictureDto> _profilePictures = [];
  List<MusicSampleDto> _musicSamples = [];

  bool _citiesLoading = false;
  String _status = '';
  bool _loading = true;
  final Map<String, LatLng> _cityCoords = {};
  final Map<String, LatLng> _geocodeCache = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _loading = true);

    // Load countries and genders
    final countriesResp = await widget.api.getCountries();
    final gendersResp = await widget.api.getGenders();

    if (countriesResp.statusCode == 200) {
      final decoded = jsonDecode(countriesResp.body);
      if (decoded is List) {
        _countries = decoded.map((c) => CountryDto.fromJson(c)).toList();
      }
    }

    if (gendersResp.statusCode == 200) {
      final decoded = jsonDecode(gendersResp.body);
      if (decoded is List) {
        _genders = decoded.map((g) => GenderDto.fromJson(g)).toList();
      }
    }

    // Load profile
    await _loadProfile();

    setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    final resp = await widget.api.getMyProfile();
    if (resp.statusCode != 200) {
      setState(() => _status = 'Failed to load profile');
      return;
    }

    final profile = jsonDecode(resp.body);

    setState(() {
      // Load basic info
      _name.text = profile['name']?.toString() ?? '';
      _isBand = profile['isBand'] as bool?;

      // Load birth date for artists
      if (profile['birthDate'] != null) {
        try {
          _birthDate = DateTime.parse(profile['birthDate'].toString());
        } catch (_) {}
      }

      // Set country
      final countryId = profile['countryId']?.toString();
      if (countryId != null && countryId.isNotEmpty) {
        _selectedCountry = _countries.firstWhere(
          (c) => c.id == countryId,
          orElse: () => CountryDto(id: countryId, name: ''),
        );
        _country.text = _selectedCountry?.name ?? '';

        // Load cities for this country
        if (_selectedCountry != null) {
          _loadCitiesForCountry(_selectedCountry!.id);
        }
      }

      // Set city - will be set after cities are loaded
      final cityId = profile['cityId']?.toString();
      if (cityId != null && cityId.isNotEmpty) {
        // We'll set the city after loading cities for the country
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _selectedCity = _cities.firstWhere(
                (c) => c.id == cityId,
                orElse: () =>
                    CityDto(id: cityId, name: '', countryId: countryId),
              );
              _city.text = _selectedCity?.name ?? '';
            });
            if (_selectedCity != null) {
              _geocodeCity(_selectedCity!);
            }
          }
        });
      }

      // Set gender for artists
      final genderId = profile['genderId']?.toString();
      if (genderId != null && genderId.isNotEmpty && _genders.isNotEmpty) {
        _selectedGender = _genders.firstWhere(
          (g) => g.id == genderId,
          orElse: () => _genders.first,
        );
      }

      // Load pictures and samples for order
      if (profile['profilePictures'] is List) {
        _profilePictures = (profile['profilePictures'] as List)
            .map((p) => ProfilePictureDto.fromJson(p))
            .toList();
      }
      if (profile['musicSamples'] is List) {
        _musicSamples = (profile['musicSamples'] as List)
            .map((s) => MusicSampleDto.fromJson(s))
            .toList();
      }
    });
  }

  Future<void> _loadCitiesForCountry(String countryId) async {
    setState(() {
      _citiesLoading = true;
      _cities = [];
      _selectedCity = null;
      _cityCoords.clear();
    });

    final resp = await widget.api.getCities(countryId);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        final List<CityDto> parsed = [];
        for (final entry in decoded) {
          if (entry is Map) {
            final map = Map<String, dynamic>.from(entry);
            final city = CityDto.fromJson(map);
            parsed.add(city);
            final lat = _toDouble(
              map['latitude'] ?? map['lat'] ?? map['Latitude'],
            );
            final lon = _toDouble(
              map['longitude'] ?? map['lng'] ?? map['Longitude'],
            );
            if (lat != null && lon != null) {
              _cityCoords[city.id] = LatLng(lat, lon);
            }
          }
        }
        setState(() {
          _cities = parsed;
          _citiesLoading = false;
        });
      }
    } else {
      setState(() => _citiesLoading = false);
    }
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<LatLng?> _geocodeCity(CityDto city) async {
    if (_cityCoords.containsKey(city.id)) return _cityCoords[city.id];
    if (_geocodeCache.containsKey(city.id)) return _geocodeCache[city.id];
    final countryName = _selectedCountry?.name ?? '';
    final query = [
      city.name,
      if (countryName.isNotEmpty) countryName,
    ].join(', ');
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
    );
    try {
      final resp = await http.get(
        uri,
        headers: const {
          'User-Agent': 'soundmates_front/1.0 (profile settings map preview)',
          'Accept': 'application/json',
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(
            first['lon']?.toString() ?? first['lng']?.toString() ?? '',
          );
          if (lat != null && lon != null) {
            final coords = LatLng(lat, lon);
            _geocodeCache[city.id] = coords;
            return coords;
          }
        }
      }
    } catch (_) {
      // ignore errors; preview will remain placeholder
    }
    return null;
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Country'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _countries.length,
            itemBuilder: (context, index) {
              final country = _countries[index];
              return ListTile(
                title: Text(country.name),
                onTap: () {
                  setState(() {
                    _selectedCountry = country;
                    _country.text = country.name;
                    _selectedCity = null;
                    _city.text = '';
                  });
                  _loadCitiesForCountry(country.id);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCityPicker() {
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a country first')),
      );
      return;
    }

    if (_cities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cities available for this country')),
      );
      return;
    }

    showDialog<CityDto>(
      context: context,
      builder: (ctx) {
        String query = '';
        CityDto? hoveredCity = _selectedCity;
        LatLng? hoveredLatLng = hoveredCity != null
            ? (_cityCoords[hoveredCity.id] ?? _geocodeCache[hoveredCity.id])
            : null;
        bool geocoding = false;

        Future<void> updateHover(
          CityDto city,
          StateSetter setDialogState,
        ) async {
          setDialogState(() {
            hoveredCity = city;
            hoveredLatLng = _cityCoords[city.id] ?? _geocodeCache[city.id];
          });
          if (hoveredLatLng == null) {
            setDialogState(() => geocoding = true);
            final coords = await _geocodeCity(city);
            if (!mounted) return;
            setDialogState(() {
              if (hoveredCity?.id == city.id && coords != null) {
                hoveredLatLng = coords;
              }
              geocoding = false;
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = _cities
                .where(
                  (c) => c.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();

            Widget buildListTile(CityDto city) {
              final coords = _cityCoords[city.id] ?? _geocodeCache[city.id];
              final subtitle = coords != null
                  ? Text(
                      'lat ${coords.latitude.toStringAsFixed(3)}, lon ${coords.longitude.toStringAsFixed(3)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  : null;
              final tile = ListTile(
                title: Text(city.name),
                subtitle: subtitle,
                trailing:
                    coords == null && geocoding && hoveredCity?.id == city.id
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (coords != null
                          ? Icon(
                              Icons.map,
                              size: 18,
                              color: AppColors.accentPurpleSoft,
                            )
                          : null),
                onTap: () {
                  setState(() {
                    _selectedCity = city;
                    _city.text = city.name;
                  });
                  Navigator.pop(ctx, city);
                },
                onLongPress: () => updateHover(city, setStateDialog),
              );

              return MouseRegion(
                onEnter: (_) => updateHover(city, setStateDialog),
                child: tile,
              );
            }

            final listPane = Expanded(
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search city...',
                    ),
                    onChanged: (value) => setStateDialog(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('No results'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) =>
                                buildListTile(filtered[index]),
                          ),
                  ),
                ],
              ),
            );

            final preview = SizedBox(
              width: 320,
              child: Stack(
                children: [
                  CityMapPreview(
                    center: hoveredLatLng,
                    cityName: hoveredCity?.name,
                    placeholderMessage: 'Hover a city to preview',
                  ),
                  if (geocoding)
                    const Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            );

            return AlertDialog(
              title: Text('Select City (${_selectedCountry!.name})'),
              content: SizedBox(
                width: 720,
                height: 520,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showSidePreview = constraints.maxWidth >= 560;
                    if (showSidePreview) {
                      return Row(
                        children: [
                          listPane,
                          const SizedBox(width: 16),
                          preview,
                        ],
                      );
                    }
                    return Column(
                      children: [
                        listPane,
                        const SizedBox(height: 12),
                        SizedBox(height: 180, child: preview),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    ).then((picked) {
      if (picked != null) {
        setState(() {
          _selectedCity = picked;
          _city.text = picked.name;
        });
      }
    });
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _status = 'Saving...');

    final picturesOrder = _profilePictures.map((p) => p.id).toList();
    final samplesOrder = _musicSamples.map((s) => s.id).toList();

    http.Response resp;
    if (_isBand == true) {
      // For bands, we need to get current band members and tags
      final profileResp = await widget.api.getMyProfile();
      if (profileResp.statusCode != 200) {
        setState(() => _status = 'Failed to load profile data');
        return;
      }

      final profile = jsonDecode(profileResp.body);
      final bandMembers =
          (profile['bandMembers'] as List?)
              ?.map((m) => BandMemberDto.fromJson(m))
              .toList() ??
          [];
      final tagsIds =
          (profile['tagsIds'] as List?)?.map((t) => t.toString()).toList() ??
          [];
      final description = profile['description']?.toString() ?? '';

      final dto = UpdateBandProfile(
        isBand: true,
        name: _name.text.trim(),
        description: description,
        countryId: _selectedCountry?.id ?? '',
        cityId: _selectedCity?.id ?? '',
        tagsIds: tagsIds,
        musicSamplesOrder: samplesOrder,
        profilePicturesOrder: picturesOrder,
        bandMembers: bandMembers,
      );
      resp = await widget.api.updateBandProfile(dto);
    } else {
      // For artists, we need to get current tags and description
      final profileResp = await widget.api.getMyProfile();
      if (profileResp.statusCode != 200) {
        setState(() => _status = 'Failed to load profile data');
        return;
      }

      final profile = jsonDecode(profileResp.body);
      final tagsIds =
          (profile['tagsIds'] as List?)?.map((t) => t.toString()).toList() ??
          [];
      final description = profile['description']?.toString() ?? '';

      final dto = UpdateArtistProfile(
        isBand: false,
        name: _name.text.trim(),
        description: description,
        countryId: _selectedCountry?.id ?? '',
        cityId: _selectedCity?.id ?? '',
        birthDate: _birthDate,
        genderId: _selectedGender?.id,
        tagsIds: tagsIds,
        musicSamplesOrder: samplesOrder,
        profilePicturesOrder: picturesOrder,
      );
      resp = await widget.api.updateArtistProfile(dto);
    }

    if (resp.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() => _status = 'Failed to save: ${resp.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        title: const Text(
          'Edit Basic Information',
          style: TextStyle(
            color: AppColors.textPrimaryAlt,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimaryAlt),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ProfileEditStep1(
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
                isSettingsEdit: true,
                onShowCountryPicker: _showCountryPicker,
                onShowCityPicker: _showCityPicker,
                onIsBandChanged: (val) {
                  // Cannot change account type after registration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot change account type')),
                  );
                },
                onPickBirthDate: _pickBirthDate,
                onGenderChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedGender = _genders.firstWhere(
                        (g) => g.id == id,
                        orElse: () => _genders.first,
                      );
                    });
                  }
                },
                onNext: () {}, // Not used in settings edit
                onSave: _save,
                status: _status,
              ),
            ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    super.dispose();
  }
}
