# Przykłady użycia testów integracyjnych

## Scenariusz 1: Sprawdzenie podstawowej funkcjonalności

```powershell
# Uruchom podstawowe testy aplikacji
flutter test integration_test/app_test.dart -d android
```

**Co jest testowane:**
- ✅ Aplikacja się uruchamia
- ✅ Wyświetla się ekran logowania/rejestracji
- ✅ Nawigacja między ekranami działa
- ✅ Walidacja podstawowych pól

---

## Scenariusz 2: Testowanie walidacji przed deploymentem

```powershell
# Uruchom wszystkie testy walidacji
flutter test integration_test/validation_test.dart -d chrome
```

**Co jest testowane:**
- ✅ Email - format, puste pole, za długi
- ✅ Hasło - długość, złożoność, wymagane znaki
- ✅ Confirm Password - dopasowanie
- ✅ Nazwa - puste pole, za długa
- ✅ Opis - limit 500 znaków, licznik

---

## Scenariusz 3: Weryfikacja flow użytkownika

```powershell
# Testuj cały proces tworzenia profilu
flutter test integration_test/profile_flow_test.dart -d android
```

**Co jest testowane:**
- ✅ Walidacja Step 1 (imię, lokalizacja, data urodzenia)
- ✅ Przełączanie Artist/Band
- ✅ Licznik znaków w opisie
- ✅ Dodawanie tagów
- ✅ Dodawanie członków zespołu (dla Band)

---

## Scenariusz 4: Testowanie Dark Mode

```powershell
# Sprawdź czy dark mode działa
flutter test integration_test/dark_mode_test.dart -d android
```

**Co jest testowane:**
- ✅ Toggle dark mode w ustawieniach
- ✅ Persistencja po restarcie
- ✅ Kolory adapatują się we wszystkich ekranach
- ✅ Pola input są widoczne w dark mode

---

## Scenariusz 5: Testowanie przed pull requestem

```powershell
# Uruchom wszystkie testy
cd integration_test
.\run_tests.ps1
```

**Weryfikuje:**
- ✅ Wszystkie podstawowe funkcje
- ✅ Cała walidacja
- ✅ Flow użytkownika
- ✅ Dark mode
- ✅ Brak regresji

---

## Scenariusz 6: Debug konkretnego problemu

```powershell
# Uruchom z verbose logami
flutter test integration_test/validation_test.dart -d android --verbose

# Lub z debuggerem
flutter run integration_test/validation_test.dart -d android --debug
```

---

## Scenariusz 7: Continuous Integration

```yaml
# .github/workflows/integration_tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 29
          script: |
            flutter pub get
            flutter test integration_test
```

---

## Scenariusz 8: Testowanie na różnych urządzeniach

```powershell
# Lista dostępnych emulatorów
flutter emulators

# Uruchom konkretny emulator (phone)
flutter emulators --launch Pixel_5_API_30

# Uruchom tablet
flutter emulators --launch Tablet_API_30

# Testy na wybranym urządzeniu
flutter test integration_test -d android
```

---

## Scenariusz 9: Wybiórcze uruchamianie testów

```powershell
# Tylko testy dla email
flutter test integration_test/validation_test.dart -d android --plain-name="Email"

# Tylko testy dla hasła
flutter test integration_test/validation_test.dart -d android --plain-name="Password"
```

---

## Scenariusz 10: Generowanie raportu z testów

```powershell
# Uruchom z coverage
flutter test integration_test --coverage -d android

# Zobacz raport
# Otwórz coverage/lcov.info w narzędziu do coverage
```

---

## Najczęstsze kombinacje

### Pre-commit check
```powershell
flutter test integration_test/validation_test.dart -d android
```

### Pre-deploy check
```powershell
.\run_tests.ps1
```

### Quick smoke test
```powershell
flutter test integration_test/app_test.dart -d android
```

### Full regression test
```powershell
flutter test integration_test -d android --verbose
```

---

## Tips & Tricks

1. **Szybsze testy:** Użyj `--no-pub` jeśli zależności są aktualne
2. **Więcej informacji:** Dodaj `--verbose` do każdego polecenia
3. **Konkretny test:** Użyj `--plain-name="test name"` 
4. **Bez headless mode:** Dodaj `--no-headless` aby zobaczyć Chrome
5. **Timeout:** Zwiększ timeout dla wolnych testów: `--timeout=2m`
