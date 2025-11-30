# 🚀 Szybki Start - Integration Tests na Android

## ⚠️ Przed uruchomieniem

### Krok 1: Uruchom emulator Android

```powershell
# Zobacz dostępne emulatory
flutter emulators

# Uruchom wybrany emulator
flutter emulators --launch <emulator_id>

# Sprawdź czy działa
flutter devices
```

### Krok 2: PowerShell Execution Policy (jeśli potrzebne)

Jeśli dostajesz błąd "running scripts is disabled":

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

---

## 🎯 Uruchomienie testów

### Opcja 1: PowerShell skrypt (ZALECANE)
```powershell
cd integration_test
.\run_tests.ps1
```

### Opcja 2: Flutter CLI bezpośrednio
```powershell
flutter test integration_test -d android
```

### Opcja 3: Konkretny test
```powershell
.\run_test.ps1 validation
```

---

## ✅ Szybkie uruchomienie (ZARAZ TERAZ)

Wpisz te komendy:

```powershell
# 1. Pozwól na uruchamianie skryptów w tej sesji
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 2. Uruchom testy
.\run_tests.ps1
```

Lub po prostu:

```powershell
flutter test integration_test -d chrome
```

---

## Co robi każda opcja?

| Opcja | Zasięg | Bezpieczeństwo | Trwałość |
|-------|--------|----------------|----------|
| `-Scope Process` | Tylko ta sesja PowerShell | ✅ Bezpieczne | ❌ Tymczasowe |
| `-Scope CurrentUser` | Wszystkie sesje tego użytkownika | ⚠️ Uważaj na skrypty | ✅ Trwałe |
| `Bypass -File` | Tylko ten plik | ✅ Bezpieczne | ❌ Za każdym razem |
| Flutter CLI | Nie dotyczy | ✅ Bezpieczne | ✅ Zawsze działa |

---

## Polecam: Użyj `-Scope Process`

To najbezpieczniejsza opcja - pozwala uruchamiać skrypty tylko w tej sesji PowerShell.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Potem normalne uruchomienie:
```powershell
.\run_tests.ps1
```
