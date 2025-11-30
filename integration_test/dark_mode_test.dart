import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Tests', () {
    test('ThemeMode enum has all values', () {
      expect(ThemeMode.values.length, 3);
      expect(ThemeMode.values, contains(ThemeMode.light));
      expect(ThemeMode.values, contains(ThemeMode.dark));
      expect(ThemeMode.values, contains(ThemeMode.system));
    });

    test('ThemeData can be created', () {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();
      
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('Colors are defined for light and dark mode', () {
      final lightColors = ColorScheme.light();
      final darkColors = ColorScheme.dark();
      
      expect(lightColors.brightness, Brightness.light);
      expect(darkColors.brightness, Brightness.dark);
      expect(lightColors.surface != darkColors.surface, isTrue);
    });
  });
}
