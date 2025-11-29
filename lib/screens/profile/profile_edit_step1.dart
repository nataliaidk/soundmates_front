import 'package:flutter/material.dart';
import '../../api/models.dart';
import '../../theme/app_design_system.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderSide = isDark 
        ? BorderSide.none 
        : BorderSide(color: AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700));
    
    return Column(
      children: [
        // Name field
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'How do they call you?',
            filled: true,
            fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: borderSide,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: borderSide,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: borderSide.copyWith(color: AppColors.accentPurple),
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
              color: AppTheme.getAdaptiveGrey(context, lightShade: 50, darkShade: 850),
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
                            color: isBand == false ? AppColors.accentPurple : AppTheme.getAdaptiveSurface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBand == false ? AppColors.accentPurple : AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Artist',
                              style: TextStyle(
                                color: isBand == false ? Colors.white : AppTheme.getAdaptiveText(context),
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
                            color: isBand == true ? AppColors.accentPurple : AppTheme.getAdaptiveSurface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isBand == true ? AppColors.accentPurple : AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Band',
                              style: TextStyle(
                                color: isBand == true ? Colors.white : AppTheme.getAdaptiveText(context),
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
                  color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(30),
                  border: isDark ? null : Border.all(color: AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700)),
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
                            color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedCountry?.name.isNotEmpty == true
                              ? selectedCountry!.name
                              : 'Select country',
                          style: TextStyle(
                            color: selectedCountry == null ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppTheme.getAdaptiveText(context),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_drop_down, color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
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
                  color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(30),
                  border: isDark ? null : Border.all(color: AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700)),
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
                              color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
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
                              color: selectedCity == null ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppTheme.getAdaptiveText(context),
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
                          color: AppColors.accentPurple,
                        ),
                      )
                    else
                      Icon(Icons.arrow_drop_down, color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
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
                color: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(30),
                border: isDark ? null : Border.all(color: AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 700)),
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
                          color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        birthDate == null
                            ? 'dd/mm/yyyy'
                            : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                        style: TextStyle(
                          color: birthDate == null ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppTheme.getAdaptiveText(context),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down, color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Gender dropdown
          DropdownButtonFormField<String>(
            value: selectedGender?.id,
            decoration: InputDecoration(
              labelText: 'Gender',
              filled: true,
              fillColor: isDark ? AppColors.surfaceDarkAlt : AppColors.surfaceWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: borderSide,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: borderSide,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: borderSide.copyWith(color: AppColors.accentPurple),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
