import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:soundmates/utils/validators.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Validation Tests', () {
    test('Name validation for profile', () {
      expect(validateName(''), 'Name cannot be empty');
      expect(validateName('AB'), null);
      expect(validateName('Valid Name'), null);
      expect(validateName('a' * 51), contains('too long'));
    });

    test('Birth year validation for profile', () {
      final currentYear = DateTime.now().year;
      expect(validateBirthYear(''), 'Birth year cannot be empty');
      expect(validateBirthYear('abc'), 'Invalid birth year');
      expect(validateBirthYear('1899'), contains('earlier than 1900'));
      expect(validateBirthYear('${currentYear + 1}'), contains('future'));
      expect(validateBirthYear('${currentYear - 25}'), null);
    });

    test('Description validation for profile', () {
      expect(validateDescription(''), null);
      expect(validateDescription('Short bio'), null);
      expect(validateDescription('a' * 500), null);
      expect(validateDescription('a' * 501), contains('too long'));
    });

    test('Band member name validation', () {
      expect(validateBandMemberName(''), 'Member name cannot be empty');
      expect(validateBandMemberName('John Doe'), null);
      expect(validateBandMemberName('a' * 51), contains('too long'));
    });

    test('Band member age validation', () {
      expect(validateBandMemberAge(''), 'Age cannot be empty');
      expect(validateBandMemberAge('abc'), 'Invalid age');
      expect(validateBandMemberAge('12'), contains('at least 13'));
      expect(validateBandMemberAge('125'), 'Invalid age');
      expect(validateBandMemberAge('25'), null);
    });
  });
}
