# Quick Start - Integration Tests

## ⚠️ Przed pierwszym uruchomieniem

Jeśli dostajesz błąd "running scripts is disabled", wpisz:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Szczegóły: Zobacz **RUN_TESTS_FIRST.md**

---

## Uruchomienie testów (3 sposoby)

### 1. PowerShell Skrypt - Wszystkie testy
```powershell
cd integration_test
.\run_tests.ps1
```

### 2. PowerShell Skrypt - Wybrane testy
```powershell
cd integration_test
.\run_test.ps1 validation    # Tylko testy walidacji
.\run_test.ps1 profile       # Tylko testy profilu
.\run_test.ps1 app           # Tylko podstawowe testy
.\run_test.ps1 darkmode      # Tylko testy dark mode
```

### 3. Bezpośrednio przez Flutter CLI
```bash
# Z głównego katalogu projektu
flutter test integration_test -d chrome

# Pojedynczy plik
flutter test integration_test/validation_test.dart -d chrome
```

## Dostępne testy

| Plik | Opis | Co testuje |
|------|------|------------|
| `app_test.dart` | Podstawowe testy aplikacji | Uruchamianie, nawigacja, podstawowe funkcje |
| `profile_flow_test.dart` | Flow tworzenia profilu | Step 1, Step 2, Artist/Band, walidacja |
| `validation_test.dart` | Walidacja formularzy | Email, hasło, nazwa, opis, liczniki znaków |
| `dark_mode_test.dart` | Tryb ciemny | Toggle, persistencja, kolory w UI |

## Wymagania

- ✅ Flutter SDK zainstalowany
- ✅ Android Studio zainstalowany
- ✅ Android SDK zainstalowany
- ✅ Emulator Android uruchomiony
- ✅ Zależności zainstalowane (`flutter pub get` - już wykonane)

## Przykładowy output

```
Running all integration tests...
00:01 +0: SoundMates App Integration Tests App launches and shows login/register screen
00:03 +1: SoundMates App Integration Tests Navigation to register screen works
00:05 +2: SoundMates App Integration Tests Email validation works on login screen
...
All tests passed successfully!
```

## Debugging

Jeśli test failuje, sprawdź:
1. Czy emulator Android jest uruchomiony (`flutter devices`)
2. Czy aplikacja działa lokalnie (`flutter run -d android`)
3. Czy wszystkie zależności są zainstalowane
4. Logi w konsoli - uruchom z `--verbose`
5. Czy emulator ma wystarczająco RAM (min 2GB)

## Continuous Integration

Testy można dodać do CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Run Integration Tests
  uses: reactivecircus/android-emulator-runner@v2
  with:
    api-level: 29
    script: flutter test integration_test
```

## Next Steps

1. Uruchom emulator: `flutter emulators --launch <id>`
2. Sprawdź czy działa: `flutter devices`
3. Uruchom testy: `.\run_tests.ps1`
4. Sprawdź wyniki w konsoli
5. Jeśli wszystko działa - gotowe! ✅
6. Jeśli są błędy - zobacz sekcję Troubleshooting w README.md
