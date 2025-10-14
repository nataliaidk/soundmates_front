String? validateEmail(String email) {
  final s = email.trim();
  if (s.isEmpty) return 'Email nie może być pusty';
  if (s.length > 100) return 'Email za długi (max 100 znaków)';
  final re = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+");
  if (!re.hasMatch(s)) return 'Nieprawidłowy adres email';
  return null;
}

String? validatePassword(String p) {
  if (p.length < 8) return 'Za krótkie hasło (min 8 znaków)';
  if (p.length > 32) return 'Za długie hasło (max 32 znaki)';
  if (!RegExp(r'^[\x20-\x7E]+$').hasMatch(p)) return 'Hasło musi zawierać tylko drukowalne znaki ASCII';
  if (!RegExp(r'[a-z]').hasMatch(p)) return 'Hasło musi zawierać co najmniej jedną małą literę';
  if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Hasło musi zawierać co najmniej jedną wielką literę';
  if (!RegExp(r'[0-9]').hasMatch(p)) return 'Hasło musi zawierać co najmniej jedną cyfrę';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) return 'Hasło musi zawierać co najmniej jeden znak specjalny';
  return null;
}

String? validateMessage(String msg) {
  if (msg.length > 4000) return 'Wiadomość za długa (max 4000 znaków)';
  return null;
}

String? validateName(String name) {
  if (name.trim().isEmpty) return 'Imię nie może być puste';
  if (name.trim().length > 50) return 'Imię za długie (max 50 znaków)';
  return null;
}

String? validateDescription(String desc) {
  if (desc.trim().isEmpty) return null; 
  if (desc.trim().length > 500) return 'Opis za długi (max 500 znaków)';
  return null;
}

String? validateCityOrCountry(String s, String label) {
  if (s.trim().isEmpty) return '$label nie może być puste';
  if (s.trim().length > 100) return '$label za długi (max 100 znaków)';
  return null;
}

String? validateBirthYear(String yearText) {
  if (yearText.trim().isEmpty) return 'Rok urodzenia nie może być pusty';
  final y = int.tryParse(yearText);
  if (y == null) return 'Nieprawidłowy rok urodzenia';
  final current = DateTime.now().year;
  if (y < 1900) return 'Rok urodzenia nie może być wcześniej niż 1900';
  if (y > current) return 'Rok urodzenia nie może być w przyszłości';
  return null;
}
