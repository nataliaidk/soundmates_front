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
        // Name field
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'How do they call you?',
            filled: true,
            fillColor: Colors.deepPurple.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
        ),
        const SizedBox(height: 16),
        
        // Artist vs Band selection (only during onboarding)
        if (!isSettingsEdit)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you a band?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => onIsBandChanged(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isBand == false ? Colors.deepPurple.shade400 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBand == false ? Colors.deepPurple.shade400 : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Artist',
                              style: TextStyle(
                                color: isBand == false ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => onIsBandChanged(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isBand == true ? Colors.deepPurple.shade400 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBand == true ? Colors.deepPurple.shade400 : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Band',
                              style: TextStyle(
                                color: isBand == true ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (!isSettingsEdit) const SizedBox(height: 16),
        
        // Location section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            // Country picker
            InkWell(
              onTap: onShowCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Country',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedCountry?.name.isNotEmpty == true
                              ? selectedCountry!.name
                              : 'Select country',
                          style: TextStyle(
                            color: selectedCountry == null ? Colors.grey.shade500 : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // City picker
            InkWell(
              onTap: selectedCountry != null && !citiesLoading ? onShowCityPicker : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedCity?.name.isNotEmpty == true
                                ? selectedCity!.name
                                : (selectedCountry == null
                                    ? 'Select country first'
                                    : (citiesLoading
                                        ? 'Loading cities...'
                                        : (cities.isEmpty ? 'No cities available' : 'Select city'))),
                            style: TextStyle(
                              color: selectedCity == null ? Colors.grey.shade500 : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (citiesLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple.shade400,
                        ),
                      )
                    else
                      Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Artist-only fields: birthDate and gender
        if (isBand != true) ...[
          const SizedBox(height: 16),
          // Birth date picker
          InkWell(
            onTap: onPickBirthDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of birth',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        birthDate == null
                            ? 'dd/mm/yyyy'
                            : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                        style: TextStyle(
                          color: birthDate == null ? Colors.grey.shade500 : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Gender dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(30),
            ),
            child: DropdownButtonFormField<String>(
              value: selectedGender?.id,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                labelText: 'Gender',
                labelStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              items: genders
                  .map((g) => DropdownMenuItem<String>(
                        value: g.id,
                        child: Text(g.name),
                      ))
                  .toList(),
              onChanged: onGenderChanged,
            ),
          ),
        ],
        const SizedBox(height: 24),
        
        // Save or Next button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (_validate(context, (msg) {
                // Status will be handled by parent
              })) {
                if (isSettingsEdit && onSave != null) {
                  onSave!();
                } else {
                  onNext();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              isSettingsEdit ? 'Save' : 'Next',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        if (status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
