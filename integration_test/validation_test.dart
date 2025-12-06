import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundmates/utils/validators.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Validator Unit Tests', () {
    test('Email validator works correctly', () {
      // Empty email
      expect(validateEmail(''), 'Email cannot be empty');
      
      // Invalid format
      expect(validateEmail('invalid'), 'Invalid email address');
      expect(validateEmail('test@'), 'Invalid email address');
      expect(validateEmail('@test.com'), 'Invalid email address');
      
      // Valid email
      expect(validateEmail('test@example.com'), null);
      expect(validateEmail('user.name+tag@example.co.uk'), null);
    });

    test('Password validator works correctly', () {
      // Empty password (too short)
      expect(validatePassword(''), contains('too short'));
      
      // Too short
      expect(validatePassword('Ab1!'), contains('min 8 characters'));
      
      // Missing uppercase
      expect(validatePassword('abc12345!'), contains('uppercase letter'));
      
      // Missing lowercase
      expect(validatePassword('ABC12345!'), contains('lowercase letter'));
      
      // Missing digit
      expect(validatePassword('Abcdefgh!'), contains('digit'));
      
      // Missing special character
      expect(validatePassword('Abcd1234'), contains('special character'));
      
      // Valid password
      expect(validatePassword('Test1234!'), null);
      expect(validatePassword('MyP@ssw0rd'), null);
    });

    test('Name validator works correctly', () {
      // Empty name
      expect(validateName(''), 'Name cannot be empty');
      
      // Single character is valid
      expect(validateName('A'), null);
      
      // Valid names
      expect(validateName('John'), null);
      expect(validateName('Mary Jane'), null);
      expect(validateName('Jean-Pierre'), null);
    });

    test('Description validator works correctly', () {
      // Empty description is valid
      expect(validateDescription(''), null);
      
      // Too long
      final longText = 'a' * 501;
      expect(validateDescription(longText), contains('500 characters'));
      
      // Valid descriptions
      expect(validateDescription('Short bio'), null);
      expect(validateDescription('a' * 500), null);
    });

    test('Age validator works correctly', () {
      // Null age
      expect(validateAge(null), 'Age is required');
      
      // Too young
      expect(validateAge(12), contains('at least 13'));
      
      // Too old
      expect(validateAge(125), contains('Invalid age'));
      
      // Valid ages
      expect(validateAge(18), null);
      expect(validateAge(25), null);
      expect(validateAge(65), null);
    });

    test('Birth year validator works correctly', () {
      final currentYear = DateTime.now().year;
      
      // Empty year
      expect(validateBirthYear(''), 'Birth year cannot be empty');
      
      // Non-numeric
      expect(validateBirthYear('abcd'), 'Invalid birth year');
      
      // Future year
      expect(validateBirthYear('${currentYear + 1}'), contains('cannot be in the future'));
      
      // Too old (before 1900)
      expect(validateBirthYear('1899'), contains('earlier than 1900'));
      
      // Valid years (validator only checks range, not age)
      expect(validateBirthYear('${currentYear - 10}'), null);
      expect(validateBirthYear('${currentYear - 20}'), null);
      expect(validateBirthYear('${currentYear - 50}'), null);
      expect(validateBirthYear('1950'), null);
    });

    test('City/Country validator works correctly', () {
      // Empty
      expect(validateCityOrCountry('', 'City'), 'City cannot be empty');
      expect(validateCityOrCountry('', 'Country'), 'Country cannot be empty');
      
      // Too long
      expect(validateCityOrCountry('a' * 101, 'City'), contains('too long'));
      
      // Valid locations
      expect(validateCityOrCountry('Warsaw', 'City'), null);
      expect(validateCityOrCountry('New York', 'City'), null);
      expect(validateCityOrCountry('São Paulo', 'Country'), null);
    });

    test('Band member name validator works correctly', () {
      // Empty name
      expect(validateBandMemberName(''), 'Member name cannot be empty');
      
      // Single character is valid
      expect(validateBandMemberName('A'), null);
      
      // Valid names
      expect(validateBandMemberName('John'), null);
      expect(validateBandMemberName('Mary Jane'), null);
    });

    test('Band member age validator works correctly', () {
      // Empty age
      expect(validateBandMemberAge(''), 'Age cannot be empty');
      
      // Non-numeric
      expect(validateBandMemberAge('abc'), 'Invalid age');
      
      // Too young
      expect(validateBandMemberAge('5'), contains('at least 13'));
      
      // Too old
      expect(validateBandMemberAge('125'), 'Invalid age');
      
      // Valid ages
      expect(validateBandMemberAge('18'), null);
      expect(validateBandMemberAge('45'), null);
    });
  });
}
