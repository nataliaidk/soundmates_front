# Testy Jednostkowe - SoundMates Frontend

## Przegląd

Projekt został wyposażony w kompleksową suite testów jednostkowych pokrywających kluczowe komponenty aplikacji.

## Struktura Testów

### 📂 test/api/
Testy dla warstwy komunikacji z API:

- **`api_client_test.dart`** - 20 testów
  - Normalizacja URL
  - Zarządzanie tokenami
  - Parsowanie odpowiedzi z tokenami
  - Serializacja DTO
  - Konfiguracja klienta API

- **`event_hub_service_test.dart`** - 15 testów
  - Połączenia SignalR
  - Zarządzanie listenerami wiadomości
  - Obsługa callbacków zdarzeń
  - Zarządzanie aktywną konwersacją
  - Obsługa scenariuszy błędów

- **`models_test.dart`** - 14 testów
  - Serializacja/deserializacja LoginDto, RegisterDto, SwipeDto
  - Obsługa SendMessageDto, PasswordDto, ChangePasswordDto
  - ProfilePictureDto i MusicSampleDto z obsługą URL
  - UpdateUserProfileDto dla artystów i zespołów
  - UpdateArtistProfile i UpdateBandProfile

- **`token_store_test.dart`** - 9 testów
  - Zapisywanie i odczyt access token
  - Zapisywanie i odczyt refresh token
  - Usuwanie pojedynczych tokenów
  - Czyszczenie wszystkich tokenów
  - Nadpisywanie istniejących tokenów

### 📂 test/state/
Testy dla zarządzania stanem:

- **`auth_notifier_test.dart`** - 12 testów
  - Ładowanie tokenów z storage
  - Ustawianie i aktualizacja tokenów
  - Czyszczenie stanu autentykacji
  - Powiadamianie listenerów
  - Scenariusze integracyjne (login, logout, refresh, restart aplikacji)

### 📂 test/utils/
Testy dla narzędzi pomocniczych:

- **`validators_test.dart`** - 47 testów
  - `validateEmail`: format, długość, puste wartości
  - `validatePassword`: złożoność, długość, znaki specjalne
  - `validateMessage`: limit długości
  - `validateName`: wymagane pole, długość
  - `validateDescription`: opcjonalne pole, długość
  - `validateCityOrCountry`: walidacja lokalizacji
  - `validateBirthYear`: zakres dat, format

- **`audio_notifier_test.dart`** - 11 testów
  - Singleton pattern
  - Preładowanie dźwięków
  - Odtwarzanie powiadomień (match, wiadomości)
  - Zarządzanie zasobami
  - Obsługa błędów

### 📂 test/widgets/
Testy widgetów:

- **`app_bottom_nav_test.dart`** - 10 testów
  - Renderowanie przycisków nawigacji
  - Podświetlanie aktywnej zakładki
  - Nawigacja między ekranami
  - Obsługa kliknięć
  - Tooltips i stylowanie

- **`widget_test.dart`** (istniejący) - 2 testy
  - CityMapPreview z placeholderem
  - CityMapPreview z koordynata mi

## Uruchamianie Testów

### Wszystkie testy
```powershell
flutter test
```

### Konkretny plik testowy
```powershell
flutter test test/utils/validators_test.dart
```

### Testy z coverage
```powershell
flutter test --coverage
```

## Statystyki Pokrycia

| Moduł | Liczba Testów | Komponenty |
|-------|--------------|------------|
| **API** | 58 | ApiClient, EventHubService, Models, TokenStore |
| **State** | 12 | AuthNotifier |
| **Utils** | 58 | Validators, AudioNotifier |
| **Widgets** | 12 | AppBottomNav, CityMapPreview |
| **RAZEM** | **140** | |

## Kluczowe Wzorce Testowe

### 1. Mock Objects
```dart
class MockTokenStore extends TokenStore {
  final Map<String, String?> _mockStorage = {};
  // ... implementacja mocka
}
```

### 2. Setup i Teardown
```dart
setUp(() {
  mockTokenStore = MockTokenStore();
  eventHubService = EventHubService(tokenStore: mockTokenStore);
});

tearDown(() async {
  await eventHubService.disconnect();
});
```

### 3. Inicjalizacja Flutter Binding
```dart
setUpAll(() {
  TestWidgetsFlutterBinding.ensureInitialized();
});
```

### 4. Widget Tests
```dart
testWidgets('should render navigation buttons', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: AppBottomNav(...)));
  expect(find.byIcon(Icons.person_outline), findsOneWidget);
});
```

## Zależności Testowe

Projekt używa standardowych zależności testowych Flutter:
- `flutter_test`: framework testowy
- `flutter_dotenv`: konfiguracja środowiskowa w testach
- `flutter_secure_storage`: mockowane w testach TokenStore

## Uwagi Implementacyjne

### TokenStore
- Testy integracyjne wymagające Flutter binding
- W produkcji rozważ stworzenie mockowalnej wersji secure storage

### AudioNotifier
- Wymaga inicjalizacji Flutter binding dla platform channels
- Testy gracefully handleują brak plików audio w środowisku testowym

### EventHubService
- Wymaga konfiguracji dotenv
- Testy nie wymagają faktycznego połączenia SignalR

### ApiClient
- Testy jednostkowe skupione na logice, bez faktycznych żądań HTTP
- Do testów HTTP requestów można rozważyć dodanie mocka http package

## Rekomendacje

### Dodatkowe Obszary do Przetestowania
1. **Screens** - testy integracyjne dla głównych ekranów
2. **Navigation** - flow nawigacji między ekranami
3. **Error Handling** - scenariusze błędów API
4. **Offline Mode** - zachowanie bez połączenia
5. **Performance** - testy wydajności dla większych list

### Ulepsz enia
- [ ] Dodać testy golden dla kluczowych widgetów
- [ ] Implementować testy E2E dla krytycznych ścieżek
- [ ] Zwiększyć coverage dla edge cases
- [ ] Dodać testy performance dla dużych zbiorów danych
- [ ] Mockować HTTP requests w testach ApiClient

## Troubleshooting

### Problem: "Binding has not yet been initialized"
**Rozwiązanie:** Dodaj `TestWidgetsFlutterBinding.ensureInitialized()` w `setUpAll()`

### Problem: "dotenv not initialized"
**Rozwiązanie:** Użyj `dotenv.testLoad()` w `setUpAll()` z konfiguracją testową

### Problem: Testy platform-specific features
**Rozwiązanie:** Używaj mocków dla platform channels lub oznacz testy jako `@Tags(['integration'])`

## Continuous Integration

Przykładowa konfiguracja GitHub Actions:
```yaml
- name: Run Tests
  run: flutter test --coverage
  
- name: Upload Coverage
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

---

**Ostatnia aktualizacja:** 25 listopada 2025
**Wersja:** 1.0.0
