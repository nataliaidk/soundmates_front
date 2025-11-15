import 'package:flutter/material.dart';
import '../../api/models.dart';
import '../../utils/validators.dart';

/// Step 1 of profile editing: Basic information (name, type, location, birthdate, gender)
class ProfileEditStep1 extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController cityController;
  final TextEditingController countryController;
  final bool? isBand;
  final CountryDto? selectedCountry;
  final CityDto? selectedCity;
  final DateTime? birthDate;
  final GenderDto? selectedGender;
  final List<CountryDto> countries;
  final List<CityDto> cities;
  final List<GenderDto> genders;
  final bool citiesLoading;
  final bool isSettingsEdit;
  final VoidCallback onShowCountryPicker;
  final VoidCallback onShowCityPicker;
  final ValueChanged<bool?> onIsBandChanged;
  final VoidCallback onPickBirthDate;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onNext;
  final VoidCallback? onSave;
  final String status;

  const ProfileEditStep1({
    super.key,
    required this.nameController,
    required this.cityController,
    required this.countryController,
    required this.isBand,
    required this.selectedCountry,
    required this.selectedCity,
    required this.birthDate,
    required this.selectedGender,
    required this.countries,
    required this.cities,
    required this.genders,
    required this.citiesLoading,
    required this.isSettingsEdit,
    required this.onShowCountryPicker,
    required this.onShowCityPicker,
    required this.onIsBandChanged,
    required this.onPickBirthDate,
    required this.onGenderChanged,
    required this.onNext,
    this.onSave,
    required this.status,
  });

  bool _validate(BuildContext context, Function(String) setStatus) {
    final nameErr = validateName(nameController.text);
    if (nameErr != null) {
      setStatus(nameErr);
      return false;
    }
    final cityValue = selectedCity?.name ?? cityController.text;
    final countryValue = selectedCountry?.name ?? countryController.text;
    final cityErr = validateCityOrCountry(cityValue, 'City');
    if (cityErr != null) {
      setStatus(cityErr);
      return false;
    }
    final countryErr = validateCityOrCountry(countryValue, 'Country');
    if (countryErr != null) {
      setStatus(countryErr);
      return false;
    }
    if (isBand != true) {
      if (birthDate == null) {
        setStatus('Birth date is required for artists');
        return false;
      }
      if (selectedGender == null) {
        setStatus('Gender is required for artists');
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        const SizedBox(height: 8),
        
        // Artist vs Band selection (only during onboarding)
        if (!isSettingsEdit)
          Row(
            children: [
              const Expanded(child: Text('Account type:')),
              Row(
                children: [
                  Radio<bool?>(
                    value: false,
                    groupValue: isBand,
                    onChanged: onIsBandChanged,
                  ),
                  const Text('Artist'),
                  const SizedBox(width: 8),
                  Radio<bool?>(
                    value: true,
                    groupValue: isBand,
                    onChanged: onIsBandChanged,
                  ),
                  const Text('Band'),
                ],
              )
            ],
          ),
        const SizedBox(height: 8),
        
        // Country picker
        InkWell(
          onTap: onShowCountryPicker,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Country',
              border: OutlineInputBorder(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCountry?.name.isNotEmpty == true
                        ? selectedCountry!.name
                        : 'Tap to choose',
                    style: TextStyle(
                      color: selectedCountry == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
                const Icon(Icons.search),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // City picker
        InkWell(
          onTap: onShowCityPicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'City',
              border: const OutlineInputBorder(),
              suffixIcon: citiesLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCity?.name.isNotEmpty == true
                        ? selectedCity!.name
                        : (selectedCountry == null
                            ? 'Select country first'
                            : (citiesLoading
                                ? 'Loading cities...'
                                : (cities.isEmpty ? 'No cities available' : 'Tap to choose'))),
                    style: TextStyle(
                      color: selectedCity == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Artist-only fields: birthDate and gender
        if (isBand != true) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onPickBirthDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birth date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                birthDate == null
                    ? 'Tap to select date'
                    : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                style: TextStyle(
                  color: birthDate == null ? Colors.grey[600] : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedGender?.id,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: genders
                .map((g) => DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(g.name),
                    ))
                .toList(),
            onChanged: onGenderChanged,
          ),
        ],
        const SizedBox(height: 12),
        
        // Save or Next button
        if (isSettingsEdit && onSave != null)
          ElevatedButton(
            onPressed: () {
              if (_validate(context, (msg) {
                // Status will be handled by parent
              })) {
                onSave!();
              }
            },
            child: const Text('Save'),
          )
        else
          ElevatedButton(
            onPressed: () {
              if (_validate(context, (msg) {
                // Status will be handled by parent
              })) {
                onNext();
              }
            },
            child: const Text('Next'),
          ),
        
        if (status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            status,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ],
    );
  }
}
