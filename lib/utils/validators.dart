String? validateEmail(String email) {
  final s = email.trim();
  if (s.isEmpty) return 'Email cannot be empty';
  if (s.length > 100) return 'Email too long (max 100 characters)';
  final re = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
  if (!re.hasMatch(s)) return 'Invalid email address';
  return null;
}

String? validatePassword(String p) {
  if (p.length < 8) return 'Password too short (min 8 characters)';
  if (p.length > 32) return 'Password too long (max 32 characters)';
  if (!RegExp(r'^[\x20-\x7E]+$').hasMatch(p)) return 'Password must contain only printable ASCII characters';
  if (!RegExp(r'[a-z]').hasMatch(p)) return 'Password must contain at least one lowercase letter';
  if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Password must contain at least one uppercase letter';
  if (!RegExp(r'[0-9]').hasMatch(p)) return 'Password must contain at least one digit';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) return 'Password must contain at least one special character';
  return null;
}

String? validateMessage(String msg) {
  if (msg.length > 4000) return 'Message too long (max 4000 characters)';
  return null;
}

String? validateName(String name) {
  if (name.trim().isEmpty) return 'Name cannot be empty';
  if (name.trim().length > 50) return 'Name too long (max 50 characters)';
  return null;
}

String? validateDescription(String desc) {
  if (desc.trim().isEmpty) return null; 
  if (desc.trim().length > 500) return 'Description too long (max 500 characters)';
  return null;
}

String? validateCityOrCountry(String s, String label) {
  if (s.trim().isEmpty) return '$label cannot be empty';
  if (s.trim().length > 100) return '$label too long (max 100 characters)';
  return null;
}

String? validateBirthYear(String yearText) {
  if (yearText.trim().isEmpty) return 'Birth year cannot be empty';
  final y = int.tryParse(yearText);
  if (y == null) return 'Invalid birth year';
  final current = DateTime.now().year;
  if (y < 1900) return 'Birth year cannot be earlier than 1900';
  if (y > current) return 'Birth year cannot be in the future';
  return null;
}

String? validateAge(int? age) {
  if (age == null) return 'Age is required';
  if (age < 13) return 'You must be at least 13 years old';
  if (age > 100) return 'Age must be 100 or less';
  return null;
}

String? validateBandMemberName(String name) {
  if (name.trim().isEmpty) return 'Member name cannot be empty';
  if (name.trim().length > 50) return 'Member name too long (max 50 characters)';
  return null;
}

String? validateBandMemberAge(String ageText) {
  if (ageText.trim().isEmpty) return 'Age cannot be empty';
  final age = int.tryParse(ageText);
  if (age == null) return 'Invalid age';
  if (age < 13) return 'Member must be at least 13 years old';
  if (age > 100) return 'Age must be 100 or less';
  return null;
}
