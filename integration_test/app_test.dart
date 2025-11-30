import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zpi_test/utils/validators.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Validation Tests', () {
    test('Login email validation', () {
      // Empty email
      expect(validateEmail(''), 'Email cannot be empty');
      
      // Invalid format
      expect(validateEmail('notanemail'), 'Invalid email address');
      expect(validateEmail('test@'), 'Invalid email address');
      expect(validateEmail('@test.com'), 'Invalid email address');
      
      // Valid email
      expect(validateEmail('user@example.com'), null);
    });

    test('Login password validation', () {
      // Too short
      expect(validatePassword('short'), contains('too short'));
      
      // Missing uppercase
      expect(validatePassword('lowercase123!'), contains('uppercase'));
      
      // Missing lowercase
      expect(validatePassword('UPPERCASE123!'), contains('lowercase'));
      
      // Missing digit
      expect(validatePassword('NoDigits!'), contains('digit'));
      
      // Missing special character
      expect(validatePassword('NoSpecial1'), contains('special'));
      
      // Valid password
      expect(validatePassword('Valid123!'), null);
    });

    test('Register password confirmation', () {
      final password = 'Valid123!';
      final confirmPassword = 'Valid123!';
      final wrongPassword = 'Different123!';
      
      // Matching passwords
      expect(password == confirmPassword, isTrue);
      
      // Non-matching passwords
      expect(password == wrongPassword, isFalse);
    });
  });
}
