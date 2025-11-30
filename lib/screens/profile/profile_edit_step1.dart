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
    
    return Column(
      children: [
        // Name field
        TextFormField(
          controller: nameController,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => validateName(value ?? ''),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.accentPurple,
            ),
            hintText: 'How do they call you?',
            hintStyle: TextStyle(
              color: isDark ? AppColors.textWhite.withOpacity(0.5) : AppColors.accentPurple.withOpacity(0.5),
            ),
            filled: true,
            fillColor: isDark ? AppColors.surfaceDarkAlt : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.accentPurple, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
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
                  color: isDark ? AppColors.surfaceDarkAlt : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selectedCountry == null
                        ? (isDark ? const Color(0xFFE57373) : Colors.red.shade300)
                        : (isDark ? Colors.transparent : AppColors.accentPurple),
                    width: selectedCountry == null ? 1.5 : (isDark ? 0 : 1.5),
                  ),
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
                            color: isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400) : AppColors.accentPurple.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedCountry?.name.isNotEmpty == true
                              ? selectedCountry!.name
                              : 'Select country',
                          style: TextStyle(
                            color: selectedCountry == null 
                                ? (isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppColors.accentPurple.withOpacity(0.5))
                                : (isDark ? AppTheme.getAdaptiveText(context) : AppColors.accentPurple),
                            fontSize: 16,
                            fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
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
                  color: isDark ? AppColors.surfaceDarkAlt : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selectedCity == null && selectedCountry != null
                        ? (isDark ? const Color(0xFFE57373) : Colors.red.shade300)
                        : (isDark ? Colors.transparent : AppColors.accentPurple),
                    width: (selectedCity == null && selectedCountry != null) ? 1.5 : (isDark ? 0 : 1.5),
                  ),
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
                              color: isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400) : AppColors.accentPurple.withOpacity(0.7),
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
                              color: selectedCity == null 
                                  ? (isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppColors.accentPurple.withOpacity(0.5))
                                  : (isDark ? AppTheme.getAdaptiveText(context) : AppColors.accentPurple),
                              fontSize: 16,
                              fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
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
                color: isDark ? AppColors.surfaceDarkAlt : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: birthDate == null
                      ? (isDark ? const Color(0xFFE57373) : Colors.red.shade300)
                      : (isDark ? Colors.transparent : AppColors.accentPurple),
                  width: birthDate == null ? 1.5 : (isDark ? 0 : 1.5),
                ),
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
                          color: isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400) : AppColors.accentPurple.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        birthDate == null
                            ? 'dd/mm/yyyy'
                            : '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                        style: TextStyle(
                          color: birthDate == null 
                              ? (isDark ? AppTheme.getAdaptiveGrey(context, lightShade: 500, darkShade: 500) : AppColors.accentPurple.withOpacity(0.5))
                              : (isDark ? AppTheme.getAdaptiveText(context) : AppColors.accentPurple),
                          fontSize: 16,
                          fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
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
            validator: (value) => value == null ? 'Gender is required for artists' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
              color: isDark ? AppColors.textWhite : AppColors.accentPurple,
              fontSize: 16,
              fontWeight: isDark ? FontWeight.normal : FontWeight.w600,
            ),
            dropdownColor: isDark ? AppColors.surfaceDarkAlt : Colors.white,
            decoration: InputDecoration(
              labelText: 'Gender',
              labelStyle: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.accentPurple,
              ),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDarkAlt : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.accentPurple, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: isDark ? BorderSide.none : BorderSide(color: AppColors.accentPurple, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.accentPurple, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: isDark ? const Color(0xFFE57373) : Colors.red, width: 2),
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
