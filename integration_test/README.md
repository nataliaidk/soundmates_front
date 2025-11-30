# Integration Tests

Testy integracyjne dla aplikacji SoundMates.

## Struktura testów

- `app_test.dart` - Podstawowe testy aplikacji (uruchamianie, nawigacja)
- `profile_flow_test.dart` - Testy procesu tworzenia profilu
- `validation_test.dart` - Testy walidacji formularzy
- `dark_mode_test.dart` - Testy trybu ciemnego

## Uruchamianie testów

### Android Emulator

```bash
flutter test integration_test/app_test.dart -d android
flutter test integration_test/profile_flow_test.dart -d android
flutter test integration_test/validation_test.dart -d android
flutter test integration_test/dark_mode_test.dart -d android
```

### Wszystkie testy na raz

```bash
flutter test integration_test -d android
```

### Android z konkretnym urządzeniem

```bash
# Lista dostępnych urządzeń
flutter devices

# Uruchom na konkretnym emulatorze
flutter test integration_test -d emulator-5554
```

### Android z logami

```bash
flutter test integration_test -d android --verbose
```

## Wymagania

1. Android Studio zainstalowany
2. Android SDK zainstalowany
3. Emulator Android uruchomiony
4. Flutter SDK zainstalowany
5. Pakiet `integration_test` dodany do `pubspec.yaml`

## Przygotowanie

1. Zainstaluj zależności:
```bash
flutter pub get
```

2. Uruchom emulator Android:
```bash
# Lista dostępnych emulatorów
flutter emulators

# Uruchom emulator
flutter emulators --launch <emulator_id>

# Lub uruchom przez Android Studio
```

3. Sprawdź czy emulator działa:
```bash
flutter devices
```

## Debugowanie testów

### Z logami konsoli

```bash
flutter test integration_test -d chrome --verbose
```

### Z breakpointami

Użyj `debugger()` w kodzie testu i uruchom z:
```bash
flutter run integration_test/app_test.dart -d chrome --debug
```

## Wyniki testów

Wyniki testów będą wyświetlane w konsoli. Możesz również wygenerować raport:

```bash
flutter test integration_test --coverage
```

## Dodawanie nowych testów

1. Stwórz nowy plik w katalogu `integration_test/`
2. Zaimportuj niezbędne pakiety:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zpi_test/main.dart' as app;
```

3. Dodaj testy w grupie:
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('My Tests', () {
    testWidgets('My test', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      // ... test code
    });
  });
}
```

## Najlepsze praktyki

1. Używaj `pumpAndSettle()` po każdej akcji aby poczekać na animacje
2. Sprawdzaj czy element istnieje przed interakcją: `if (finder.evaluate().isNotEmpty)`
3. Dodawaj opóźnienia dla złożonych operacji: `await tester.pumpAndSettle(const Duration(seconds: 2))`
4. Grupuj powiązane testy używając `group()`
5. Używaj opisowych nazw testów
6. Testuj zarówno happy path jak i error cases

## Troubleshooting

### Problem: Emulator Android nie uruchamia się
**Rozwiązanie**: 
- Sprawdź Android Studio i SDK
- Uruchom emulator ręcznie przez Android Studio
- Sprawdź `flutter emulators` i `flutter devices`

### Problem: Testy timeout
**Rozwiązanie**: 
- Zwiększ timeout lub dodaj więcej `pumpAndSettle()` po akcjach
- Emulator może być wolny - dodaj opóźnienia

### Problem: Element nie znaleziony
**Rozwiązanie**: Użyj `finder.evaluate().isNotEmpty` aby sprawdzić dostępność przed akcją

### Problem: Animacje powodują niestabilność
**Rozwiązanie**: Wyłącz animacje: `await tester.pumpAndSettle()`

### Problem: "No connected devices"
**Rozwiązanie**: Upewnij się, że emulator Android jest uruchomiony przed testami
