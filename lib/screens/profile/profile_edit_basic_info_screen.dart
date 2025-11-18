import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api/api_client.dart';
import '../../api/token_store.dart';
import '../../api/models.dart';
import 'profile_edit_step1.dart';

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
  State<ProfileEditBasicInfoScreen> createState() => _ProfileEditBasicInfoScreenState();
}

class _ProfileEditBasicInfoScreenState extends State<ProfileEditBasicInfoScreen> {
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
                orElse: () => CityDto(id: cityId, name: '', countryId: countryId),
              );
              _city.text = _selectedCity?.name ?? '';
            });
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
    });

    final resp = await widget.api.getCities(countryId);
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        setState(() {
          _cities = decoded.map((c) => CityDto.fromJson(c)).toList();
          _citiesLoading = false;
        });
      }
    } else {
      setState(() => _citiesLoading = false);
    }
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select City'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _cities.length,
            itemBuilder: (context, index) {
              final city = _cities[index];
              return ListTile(
                title: Text(city.name),
                onTap: () {
                  setState(() {
                    _selectedCity = city;
                    _city.text = city.name;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
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
      final bandMembers = (profile['bandMembers'] as List?)
          ?.map((m) => BandMemberDto.fromJson(m))
          .toList() ?? [];
      final tagsIds = (profile['tagsIds'] as List?)
          ?.map((t) => t.toString())
          .toList() ?? [];
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
      final tagsIds = (profile['tagsIds'] as List?)
          ?.map((t) => t.toString())
          .toList() ?? [];
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Basic Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
