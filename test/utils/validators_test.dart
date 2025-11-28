import 'package:flutter_test/flutter_test.dart';
import 'package:zpi_test/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('should return null for valid email', () {
      expect(validateEmail('test@example.com'), isNull);
      expect(validateEmail('user.name@domain.co.uk'), isNull);
      expect(validateEmail('test+tag@example.org'), isNull);
    });

    test('should return error for empty email', () {
      expect(validateEmail(''), equals('Email cannot be empty'));
      expect(validateEmail('   '), equals('Email cannot be empty'));
    });

    test('should return error for email too long', () {
      final longEmail = '${'a' * 90}@example.com';
      expect(validateEmail(longEmail), equals('Email too long (max 100 characters)'));
    });

    test('should return error for invalid email format', () {
      expect(validateEmail('notanemail'), equals('Invalid email address'));
      expect(validateEmail('@example.com'), equals('Invalid email address'));
      expect(validateEmail('test@'), equals('Invalid email address'));
      expect(validateEmail('test @example.com'), equals('Invalid email address'));
    });
  });

  group('validatePassword', () {
    test('should return null for valid password', () {
      expect(validatePassword('ValidPass1!'), isNull);
      expect(validatePassword('Str0ng#Pass'), isNull);
      expect(validatePassword('MyP@ssw0rd'), isNull);
    });

    test('should return error for password too short', () {
      expect(validatePassword('Short1!'), equals('Password too short (min 8 characters)'));
      expect(validatePassword('Ab1!'), equals('Password too short (min 8 characters)'));
    });

    test('should return error for password too long', () {
      final longPass = '${'a' * 20}A1!${'x' * 20}';
      expect(validatePassword(longPass), equals('Password too long (max 32 characters)'));
    });

    test('should return error for password without lowercase', () {
      expect(validatePassword('UPPERCASE1!'), equals('Password must contain at least one lowercase letter'));
    });

    test('should return error for password without uppercase', () {
      expect(validatePassword('lowercase1!'), equals('Password must contain at least one uppercase letter'));
    });

    test('should return error for password without digit', () {
      expect(validatePassword('NoDigits!Abc'), equals('Password must contain at least one digit'));
    });

    test('should return error for password without special character', () {
      expect(validatePassword('NoSpecial1Abc'), equals('Password must contain at least one special character'));
    });

    test('should return error for non-printable ASCII characters', () {
      expect(validatePassword('Test123!\n'), equals('Password must contain only printable ASCII characters'));
    });
  });

  group('validateMessage', () {
    test('should return null for valid message', () {
      expect(validateMessage('Hello!'), isNull);
      expect(validateMessage(''), isNull);
      expect(validateMessage('A' * 4000), isNull);
    });

    test('should return error for message too long', () {
      final longMessage = 'A' * 4001;
      expect(validateMessage(longMessage), equals('Message too long (max 4000 characters)'));
    });
  });

  group('validateName', () {
    test('should return null for valid name', () {
      expect(validateName('John Doe'), isNull);
      expect(validateName('Alice'), isNull);
      expect(validateName('Band Name'), isNull);
    });

    test('should return error for empty name', () {
      expect(validateName(''), equals('Name cannot be empty'));
      expect(validateName('   '), equals('Name cannot be empty'));
    });

    test('should return error for name too long', () {
      final longName = 'A' * 51;
      expect(validateName(longName), equals('Name too long (max 50 characters)'));
    });
  });

  group('validateDescription', () {
    test('should return null for valid description', () {
      expect(validateDescription('This is a description'), isNull);
      expect(validateDescription(''), isNull);
      expect(validateDescription('   '), isNull);
      expect(validateDescription('A' * 500), isNull);
    });

    test('should return error for description too long', () {
      final longDesc = 'A' * 501;
      expect(validateDescription(longDesc), equals('Description too long (max 500 characters)'));
    });
  });

  group('validateCityOrCountry', () {
    test('should return null for valid city or country', () {
      expect(validateCityOrCountry('Warsaw', 'City'), isNull);
      expect(validateCityOrCountry('Poland', 'Country'), isNull);
    });

    test('should return error for empty value', () {
      expect(validateCityOrCountry('', 'City'), equals('City cannot be empty'));
      expect(validateCityOrCountry('   ', 'Country'), equals('Country cannot be empty'));
    });

    test('should return error for value too long', () {
      final longValue = 'A' * 101;
      expect(validateCityOrCountry(longValue, 'City'), equals('City too long (max 100 characters)'));
    });
  });

  group('validateBirthYear', () {
    test('should return null for valid birth year', () {
      expect(validateBirthYear('1990'), isNull);
      expect(validateBirthYear('2000'), isNull);
      expect(validateBirthYear('1950'), isNull);
    });

    test('should return error for empty birth year', () {
      expect(validateBirthYear(''), equals('Birth year cannot be empty'));
      expect(validateBirthYear('   '), equals('Birth year cannot be empty'));
    });

    test('should return error for invalid birth year format', () {
      expect(validateBirthYear('abc'), equals('Invalid birth year'));
      expect(validateBirthYear('19.5'), equals('Invalid birth year'));
    });

    test('should return error for birth year before 1900', () {
      expect(validateBirthYear('1899'), equals('Birth year cannot be earlier than 1900'));
      expect(validateBirthYear('1500'), equals('Birth year cannot be earlier than 1900'));
    });

    test('should return error for birth year in the future', () {
      final futureYear = (DateTime.now().year + 1).toString();
      expect(validateBirthYear(futureYear), equals('Birth year cannot be in the future'));
    });
  });
}
