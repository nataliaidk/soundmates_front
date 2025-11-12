# Rozdzielenie Widoku i Edycji Profilu - Dokumentacja

## Przegląd Zmian

Rozdzielono widok profilu od edycji na osobne ścieżki nawigacji:

- **`/profile`** - widok profilu (tylko przeglądanie)
- **`/profile/edit`** - edycja profilu
- Po rejestracji użytkownik jest przekierowywany do `/profile/edit` i zaczyna od Step 1

## Przepływ Użytkownika

### 1. Nowy Użytkownik (Po Rejestracji)
```
Rejestracja → `/profile/edit` (isFromRegistration=true)
              → Step 1 (podstawowe info)
              → Step 2 (tagi, opis, zdjęcia)
              → Zapis → `/profile` (widok profilu)
```

### 2. Istniejący Użytkownik - Przeglądanie Profilu
```
Nawigacja → `/profile` (startInEditMode=false)
            → Widok profilu z zakładkami (Your Info, Multimedia)
```

### 3. Istniejący Użytkownik - Edycja Profilu
```
`/profile` → Kliknięcie "Edit" → `/profile/edit` (isFromRegistration=false)
                                  → Step 2 (bezpośrednia edycja tagów/opisu)
                                  → Zapis → `/profile`
```

### 4. Dodawanie Multimediów
```
`/profile` → Zakładka Multimedia → "Add Media" → `/profile/edit`
                                                  → Step 2
                                                  → Upload zdjęcia
                                                  → Zapis → `/profile`
```

## Zmiany w Kodzie

### 1. `lib/main.dart` - Routing

**Przed:**
```dart
'/register': (c) => RegisterScreen(..., onRegistered: () => Navigator.pushReplacementNamed(c, '/profile')),
'/profile': (c) => profile_new.ProfileScreen(api: api, tokens: tokens),
'/profile/edit': (c) => profile_new.ProfileScreen(..., startInEditMode: true, isSettingsEdit: true),
```

**Po:**
```dart
'/register': (c) => RegisterScreen(..., onRegistered: () => Navigator.pushReplacementNamed(c, '/profile/edit')),
'/profile': (c) => profile_new.ProfileScreen(api: api, tokens: tokens, startInEditMode: false),
'/profile/edit': (c) => profile_new.ProfileScreen(api: api, tokens: tokens, startInEditMode: true, isFromRegistration: true),
```

**Efekt:**
- Rejestracja przekierowuje do `/profile/edit`
- `/profile` zawsze pokazuje widok (nie edycję)
- `/profile/edit` zawsze pokazuje edycję z flagą `isFromRegistration`

---

### 2. `profile_screen_new.dart` - Parametr `isFromRegistration`

**Dodano nowy parametr do konstruktora:**
```dart
class ProfileScreen extends StatefulWidget {
  final ApiClient api;
  final TokenStore tokens;
  final bool startInEditMode;
  final bool isSettingsEdit;
  final bool isFromRegistration; // NOWY

  const ProfileScreen({
    super.key,
    required this.api,
    required this.tokens,
    this.startInEditMode = false,
    this.isSettingsEdit = false,
    this.isFromRegistration = false, // NOWY
  });
}
```

---

### 3. `initState()` - Inicjalizacja Stanu

**Przed:**
```dart
_isEditing = false; // Always start in view mode
_isFromRegistration = widget.startInEditMode && !widget.isSettingsEdit;
```

**Po:**
```dart
_isEditing = widget.startInEditMode;
_isFromRegistration = widget.isFromRegistration;
```

**Efekt:** Stan edycji i flaga rejestracji są bezpośrednio przekazywane z routingu.

---

### 4. `_initialize()` - Logika Kroków

**Przed:**
```dart
if (_isFromRegistration && _shouldForceEditMode()) {
  setState(() {
    _isEditing = true;
    _currentStep = 1;
  });
}
```

**Po:**
```dart
// If coming from registration, always start at Step 1
if (_isFromRegistration) {
  setState(() {
    _isEditing = true;
    _currentStep = 1;
  });
}
// If editing from /profile/edit but not from registration, go to Step 2
else if (widget.startInEditMode && !_isFromRegistration) {
  setState(() {
    _isEditing = true;
    _currentStep = 2;
  });
}
```

**Efekt:**
- Po rejestracji: zawsze Step 1 (wypełnij podstawowe info)
- Z przycisku "Edit": zawsze Step 2 (edytuj tagi/opis)

---

### 5. `onEditProfile` Callback - Nawigacja

**Przed:**
```dart
onEditProfile: () {
  setState(() {
    _isEditing = true;
    _currentStep = 2;
  });
},
```

**Po:**
```dart
onEditProfile: () {
  Navigator.pushNamed(context, '/profile/edit');
},
```

**Efekt:** Przycisk "Edit" nawiguje do `/profile/edit` zamiast zmiany lokalnego stanu.

---

### 6. `_goToProfileView()` - Powrót do Widoku

**Przed:**
```dart
Future<void> _goToProfileView() async {
  await _loadProfileAndTags();
  if (!mounted) return;
  setState(() {
    _isEditing = false;
    _currentStep = 1;
  });
}
```

**Po:**
```dart
Future<void> _goToProfileView() async {
  if (!mounted) return;
  // Navigate to profile view route
  Navigator.pushReplacementNamed(context, '/profile');
}
```

**Efekt:** Po zapisie użytkownik jest przekierowywany do `/profile` (osobna route).

---

### 7. AppBar - Przycisk Cofania

**Przed:**
```dart
automaticallyImplyLeading: !_isFromRegistration,
leading: _currentStep == 2 && !_isFromRegistration
    ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _currentStep = 1),
      )
    : null,
```

**Po:**
```dart
automaticallyImplyLeading: true,
leading: _currentStep == 2 && _isFromRegistration
    ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => setState(() => _currentStep = 1),
      )
    : IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
      ),
```

**Efekt:**
- W Step 2 podczas rejestracji: cofnij do Step 1
- W innych przypadkach: cofnij do `/profile`

---

### 8. Usunięta Metoda

Usunięto nieużywaną metodę `_shouldForceEditMode()`, ponieważ logika została przeniesiona do `_initialize()`.

---

## Korzyści

1. **Czytelniejszy routing**: `/profile` vs `/profile/edit` jest bardziej intuicyjne
2. **Lepsza separacja**: widok i edycja to osobne ekrany
3. **Deep linking**: można bezpośrednio linkować do edycji profilu
4. **Historia nawigacji**: użytkownik może cofnąć się przyciskiem "Back" w systemie
5. **Spójność**: podobne podejście jak w innych aplikacjach (np. Instagram - profil vs edycja profilu)

---

## Testowanie

### Scenariusze do Przetestowania

- [ ] **Rejestracja nowego użytkownika**
  - Wypełnij formularz rejestracji
  - Kliknij "Register"
  - Powinno przekierować do `/profile/edit` z Step 1
  - Wypełnij Step 1 → Next
  - Wypełnij Step 2 → Save
  - Powinno przekierować do `/profile` (widok)

- [ ] **Przeglądanie profilu**
  - Nawiguj do `/profile` z bottom nav
  - Powinien pokazać widok profilu (nie edycję)
  - Sprawdź zakładki: Your Info, Multimedia

- [ ] **Edycja profilu**
  - W widoku profilu kliknij "Edit"
  - Powinno przekierować do `/profile/edit` z Step 2
  - Edytuj tagi/opis
  - Kliknij "Save"
  - Powinno wrócić do `/profile`

- [ ] **Przycisk cofania w edycji**
  - Otwórz `/profile/edit` (nie z rejestracji)
  - Kliknij przycisk cofania w AppBar
  - Powinno wrócić do `/profile`

- [ ] **Przycisk cofania podczas rejestracji**
  - W Step 2 podczas rejestracji
  - Kliknij przycisk cofania
  - Powinno wrócić do Step 1

- [ ] **Dodawanie multimediów**
  - W `/profile` przejdź do zakładki Multimedia
  - Kliknij "Add Media"
  - Powinno przekierować do `/profile/edit` Step 2
  - Wybierz zdjęcie → Save
  - Powinno wrócić do `/profile` z nowym zdjęciem

---

## Pliki Zmodyfikowane

1. `lib/main.dart` - routing
2. `lib/screens/profile/profile_screen_new.dart` - logika nawigacji i stanów

---

## Następne Kroki (Opcjonalne)

1. **Animations**: Dodać animacje przejść między `/profile` a `/profile/edit`
2. **State Management**: Rozważyć użycie Provider/Riverpod do zarządzania stanem profilu
3. **Optimistic Updates**: Pokazać zmiany natychmiast przed wysłaniem do API
4. **Offline Support**: Cache profilu lokalnie
5. **Deep Linking**: Skonfigurować URL-e dla aplikacji webowej/mobilnej
