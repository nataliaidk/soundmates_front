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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.accentPurple,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCard(BuildContext context, bool isDark, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getAdaptiveSurface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildToggleOption(
    BuildContext context,
    bool isDark, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentPurple : AppTheme.getAdaptiveGrey(context, lightShade: 300, darkShade: 600),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.getAdaptiveText(context),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerTile(
    BuildContext context,
    bool isDark, {
    required String label,
    String? value,
    required String placeholder,
    required IconData icon,
    bool hasError = false,
    bool isLoading = false,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600)
                  : AppColors.accentPurple,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value?.isNotEmpty == true ? value! : placeholder,
                    style: TextStyle(
                      color: value?.isNotEmpty == true
                          ? AppTheme.getAdaptiveText(context)
                          : AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                      fontSize: 16,
                      fontWeight: value?.isNotEmpty == true ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accentPurple,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - Basic Info
        _buildSectionHeader('BASIC INFO'),
        const SizedBox(height: 12),

        // Name field in card
        _buildCard(
          context,
          isDark,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextFormField(
              controller: nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) => validateName(value ?? ''),
              style: TextStyle(
                color: AppTheme.getAdaptiveText(context),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(
                  color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                  fontSize: 14,
                ),
                hintText: 'How do they call you?',
                hintStyle: TextStyle(
                  color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                ),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.accentPurple,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Artist vs Band selection (only during onboarding)
        if (!isSettingsEdit) ...[
          _buildSectionHeader('PROFILE TYPE'),
          const SizedBox(height: 12),
          _buildCard(
            context,
            isDark,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleOption(
                      context,
                      isDark,
                      label: 'Artist',
                      icon: Icons.person,
                      isSelected: isBand == false,
                      onTap: () => onIsBandChanged(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToggleOption(
                      context,
                      isDark,
                      label: 'Band',
                      icon: Icons.groups,
                      isSelected: isBand == true,
                      onTap: () => onIsBandChanged(true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Location section
        _buildSectionHeader('LOCATION'),
        const SizedBox(height: 12),
        _buildCard(
          context,
          isDark,
          child: Column(
            children: [
              // Country picker
              _buildPickerTile(
                context,
                isDark,
                label: 'Country',
                value: selectedCountry?.name,
                placeholder: 'Select country',
                icon: Icons.public,
                hasError: selectedCountry == null,
                onTap: onShowCountryPicker,
              ),
              Divider(
                height: 1,
                indent: 56,
                color: AppTheme.getAdaptiveGrey(context, lightShade: 200, darkShade: 800),
              ),
              // City picker
              _buildPickerTile(
                context,
                isDark,
                label: 'City',
                value: selectedCity?.name,
                placeholder: selectedCountry == null
                    ? 'Select country first'
                    : (citiesLoading
                        ? 'Loading cities...'
                        : (cities.isEmpty ? 'No cities available' : 'Select city')),
                icon: Icons.location_city,
                hasError: selectedCity == null && selectedCountry != null,
                isLoading: citiesLoading,
                isDisabled: selectedCountry == null || citiesLoading,
                onTap: selectedCountry != null && !citiesLoading ? onShowCityPicker : null,
              ),
            ],
          ),
        ),

        // Artist-only fields: birthDate and gender
        if (isBand != true) ...[
          const SizedBox(height: 24),
          _buildSectionHeader('PERSONAL DETAILS'),
          const SizedBox(height: 12),
          _buildCard(
            context,
            isDark,
            child: Column(
              children: [
                // Birth date picker
                _buildPickerTile(
                  context,
                  isDark,
                  label: 'Date of Birth',
                  value: birthDate != null
                      ? '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}'
                      : null,
                  placeholder: 'Select your birth date',
                  icon: Icons.cake_outlined,
                  hasError: birthDate == null,
                  onTap: onPickBirthDate,
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: AppTheme.getAdaptiveGrey(context, lightShade: 200, darkShade: 800),
                ),
                // Gender picker
                InkWell(
                  onTap: () {
                    // Show gender selection
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: selectedGender?.id,
                      validator: (value) => value == null ? 'Gender is required' : null,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                        color: AppTheme.getAdaptiveText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      dropdownColor: AppTheme.getAdaptiveSurface(context),
                      icon: Icon(
                        Icons.chevron_right,
                        color: AppTheme.getAdaptiveGrey(context, lightShade: 400, darkShade: 600),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(
                          color: AppTheme.getAdaptiveGrey(context, lightShade: 600, darkShade: 400),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.wc_outlined,
                          color: AppColors.accentPurple,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),

        // Next/Save button
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
              backgroundColor: AppColors.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSettingsEdit ? 'Save Changes' : 'Continue',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isSettingsEdit) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          ),
        ),
        
        if (status.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D1F1F) : const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFFE57373) : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: isDark ? const Color(0xFFE57373) : Colors.red.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFFCDD2) : Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
