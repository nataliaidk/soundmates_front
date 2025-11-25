# Scenariusze Testów Manualnych - SoundMates

## Spis Treści
1. [Autentykacja i Rejestracja](#autentykacja-i-rejestracja)
2. [Profil Użytkownika](#profil-użytkownika)
3. [Przeglądanie Profili (Swipe)](#przeglądanie-profili-swipe)
4. [Matching](#matching)
5. [Czat i Wiadomości](#czat-i-wiadomości)
6. [Nawigacja](#nawigacja)
7. [Audio i Multimedia](#audio-i-multimedia)
8. [Obsługa Błędów](#obsługa-błędów)
9. [Performance i UX](#performance-i-ux)

---

## Autentykacja i Rejestracja

### TC-AUTH-001: Rejestracja Artysty - Happy Path
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Aplikacja zainstalowana
- Brak aktywnej sesji użytkownika
- Połączenie z internetem

**Kroki:**
1. Uruchom aplikację
2. Kliknij "Zarejestruj się"
3. Wybierz typ konta: "Artysta"
4. Wypełnij formularz:
   - Email: `testartist@example.com`
   - Hasło: `Test123!@#`
   - Powtórz hasło: `Test123!@#`
6. Kliknij "Zarejestruj"
7. Wypełnij profil artysty:
   - Imię: "Jan"
   - Nazwa artystyczna: "DJ Test"
   - Miasto: "Warszawa"
   - Rok urodzenia: 1990
   - Płeć: Mężczyzna
   - Gatunki: Hip-Hop, Electronic
   - Instrumenty: Drums, Bass Guitar
   - Bio: "Testowy artysta"
8. Dodaj zdjęcie profilowe
9. Dodaj próbkę muzyczną (plik MP3 oraz plik MP4)
10. Kliknij "Zapisz profil"

**Oczekiwany rezultat:**
- Konto zostało utworzone
- Użytkownik jest zalogowany
- Przekierowanie do ekranu głównego (swipe)
- Profil jest kompletny

**Dane do weryfikacji:**
- [ ] Zdjęcie profilowe wyświetla się poprawnie
- [ ] Próbka muzyczna jest dostępna do odtworzenia
- [ ] Wszystkie dane profilu są zapisane

---

### TC-AUTH-002: Rejestracja Zespołu - Happy Path
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Aplikacja zainstalowana
- Brak aktywnej sesji użytkownika
- Połączenie z internetem

**Kroki:**
1. Uruchom aplikację
2. Kliknij "Zarejestruj się"
3. Wybierz typ konta: "Zespół"
4. Wypełnij formularz podstawowy (jak w TC-AUTH-001, email: testband@example.com)
5. Wypełnij profil zespołu:
   - Nazwa zespołu: "Test Band"
   - Miasto: "Kraków"
   - Rok założenia: 2020
   - Gatunki: Rock, Alternative
   - Liczba członków: 4
        - 1: Anna, 20, Vocalist
        - 2: Beata, 22, Guitarist
        - 3: Celina, 21, Vocalist
        - 4: Dorota, 24, Drummer
   - Bio zespołu: "Testowy zespół rockowy"
6. Dodaj zdjęcie zespołu
7. Dodaj próbkę utworu zespołu
8. Kliknij "Zapisz profil"

**Oczekiwany rezultat:**
- Konto zespołu utworzone pomyślnie
- Profil zespołu wyświetla się z wszystkimi danymi
- Przekierowanie do ekranu głównego

---

### TC-AUTH-003: Logowanie - Happy Path
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma utworzone konto
- Aplikacja jest wylogowana
- Poprawne dane logowania: `testuser@example.com` / `Test123!@#`

**Kroki:**
1. Uruchom aplikację
2. Kliknij "Zaloguj się"
3. Wprowadź email: `testuser@example.com`
4. Wprowadź hasło: `Test123!@#`
5. Kliknij "Zaloguj"

**Oczekiwany rezultat:**
- Logowanie pomyślne
- Przekierowanie do ekranu głównego
- Token zapisany w secure storage
- Stan autentykacji zaktualizowany

**Weryfikacja:**
- [ ] Brak błędów podczas logowania
- [ ] Użytkownik widzi swój profil w zakładce "Profil"
- [ ] Możliwe jest przeglądanie innych profili

---

### TC-AUTH-004: Logowanie - Nieprawidłowe Hasło
**Priorytet:** Wysoki  
**Typ:** Negatywny

**Warunki wstępne:**
- Istniejące konto: `testuser@example.com`
- Aplikacja wylogowana

**Kroki:**
1. Otwórz ekran logowania
2. Wprowadź email: `testuser@example.com`
3. Wprowadź błędne hasło: `WrongPassword123`
4. Kliknij "Zaloguj"

**Oczekiwany rezultat:**
- Wyświetlenie komunikatu błędu: "Nieprawidłowy email lub hasło"
- Użytkownik pozostaje na ekranie logowania
- Pola formularza nie są wyczyszczone
- Możliwość ponownej próby logowania

---

### TC-AUTH-005: Logowanie - Brak Połączenia z Internetem
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Wyłączone WiFi i dane mobilne
- Aplikacja wylogowana

**Kroki:**
1. Wyłącz połączenie internetowe na urządzeniu
2. Otwórz aplikację
3. Wprowadź poprawne dane logowania
4. Kliknij "Zaloguj"

**Oczekiwany rezultat:**
- Komunikat: "Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie."
- Przycisk "Spróbuj ponownie"
- Aplikacja nie zawiesza się

---

### TC-AUTH-006: Wylogowanie
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany

**Kroki:**
1. Przejdź do zakładki "Profil"
2. Przewiń na dół ekranu
3. Kliknij "Wyloguj się"
4. Potwierdź wylogowanie w dialogu

**Oczekiwany rezultat:**
- Użytkownik wylogowany
- Tokeny usunięte z secure storage
- Przekierowanie do ekranu logowania
- Brak dostępu do chronionych zasobów

---

### TC-AUTH-007: Zmiana Hasła
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Aktualne hasło: `OldPassword123!`

**Kroki:**
1. Przejdź do "Profil" → "Ustawienia"
2. Kliknij "Zmień hasło"
3. Wprowadź:
   - Aktualne hasło: `OldPassword123!`
   - Nowe hasło: `NewPassword123!`
   - Potwierdź nowe hasło: `NewPassword123!`
4. Kliknij "Zapisz"
5. Wyloguj się
6. Zaloguj ponownie z nowym hasłem

**Oczekiwany rezultat:**
- Hasło zmienione pomyślnie
- Komunikat: "Hasło zostało zmienione"
- Możliwość zalogowania nowym hasłem
- Stare hasło nie działa

---

### TC-AUTH-008: Walidacja Pól Rejestracji
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Ekran rejestracji otwarty

**Kroki testowe i oczekiwane rezultaty:**

| Pole | Wartość | Oczekiwany rezultat |
|------|---------|---------------------|
| Email | `invalid-email` | "Nieprawidłowy format email" |
| Email | `test@` | "Nieprawidłowy format email" |
| Email | *(puste)* | "Email jest wymagany" |
| Hasło | `abc` | "Hasło musi mieć minimum 8 znaków" |
| Hasło | `password` | "Hasło musi zawierać cyfry i znaki specjalne" |
| Hasło | *(puste)* | "Hasło jest wymagane" |
| Powtórz hasło | `different` | "Hasła muszą być identyczne" |

---

## Profil Użytkownika

### TC-PROFILE-001: Edycja Profilu Artysty
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Zalogowany jako artysta
- Profil ma zapisane dane

**Kroki:**
1. Przejdź do zakładki "Profil"
2. Kliknij ikonę edycji (ołówek)
3. Zmień następujące pola:
   - Nazwa artystyczna: "DJ Test Updated"
   - Miasto: "Gdańsk"
   - Bio: "Zaktualizowane bio artysty"
   - Gatunki: Dodaj "Jazz", usuń "Electronic"
4. Kliknij "Zapisz zmiany"
5. Wróć do widoku profilu

**Oczekiwany rezultat:**
- Wszystkie zmiany zostały zapisane
- Zaktualizowane dane wyświetlają się w profilu
- Brak komunikatów błędów
- Profil pozostaje kompletny

**Weryfikacja:**
- [ ] Nazwa artystyczna zmieniona na "DJ Test Updated"
- [ ] Miasto wyświetla się jako "Gdańsk"
- [ ] Bio jest zaktualizowane
- [ ] Gatunki muzyczne odzwierciedlają zmiany

---

### TC-PROFILE-002: Dodanie Zdjęcia Profilowego
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Dostęp do galerii/kamery urządzenia
- Przygotowany plik obrazu (JPG/PNG, max 5MB)

**Kroki:**
1. Przejdź do "Profil" → "Edytuj"
2. Kliknij na avatar/zdjęcie profilowe
3. Wybierz "Wybierz z galerii"
4. Wybierz przygotowany obraz
5. (Opcjonalnie) Przytnij obraz
6. Potwierdź wybór
7. Kliknij "Zapisz profil"

**Oczekiwany rezultat:**
- Zdjęcie zostało przesłane
- Miniatura wyświetla się w profilu
- Pełny rozmiar wyświetla się po kliknięciu
- Inne użytkownicy widzą nowe zdjęcie

**Weryfikacja:**
- [ ] Zdjęcie wyświetla się w dobrej jakości
- [ ] Proporcje obrazu są zachowane
- [ ] Loading indicator podczas przesyłania
- [ ] Upload nie trwa dłużej niż 10s (przy dobrej sieci)

---

### TC-PROFILE-003: Dodanie Próbki Muzycznej
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Zalogowany jako artysta/zespół
- Przygotowany plik MP3 (max 10MB, min 30s)

**Kroki:**
1. Przejdź do "Profil" → "Edytuj"
2. Przewiń do sekcji "Próbka muzyczna"
3. Kliknij "Dodaj próbkę" lub "Zmień próbkę"
4. Wybierz plik MP3 z urządzenia
5. Opcjonalnie: Wprowadź tytuł utworu
6. Poczekaj na upload
7. Kliknij "Zapisz profil"

**Oczekiwany rezultat:**
- Plik został przesłany
- Wyświetla się player z próbką
- Możliwość odtworzenia próbki
- Inne użytkownicy mogą odtworzyć próbkę w twoim profilu

**Weryfikacja:**
- [ ] Progress bar podczas uploadu
- [ ] Audio player funkcjonuje (play/pause/seek)
- [ ] Długość utworu wyświetla się poprawnie
- [ ] Jakość dźwięku jest zachowana

---

### TC-PROFILE-004: Usunięcie Zdjęcia Profilowego
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma ustawione zdjęcie profilowe

**Kroki:**
1. Przejdź do "Profil" → "Edytuj"
2. Kliknij na zdjęcie profilowe
3. Wybierz "Usuń zdjęcie"
4. Potwierdź usunięcie
5. Zapisz profil

**Oczekiwany rezultat:**
- Zdjęcie zostało usunięte
- Wyświetla się domyślny avatar
- Profil nadal jest widoczny dla innych

---

### TC-PROFILE-005: Edycja Lokalizacji z Mapą
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Dostęp do lokalizacji urządzenia (opcjonalny)

**Kroki:**
1. Przejdź do "Profil" → "Edytuj"
2. Kliknij pole "Miasto/Lokalizacja"
3. Wpisz: "Wrocław"
4. Wybierz z listy sugestii: "Wrocław, Polska"
5. Zweryfikuj na mapce (jeśli wyświetla się)
6. Zapisz zmiany

**Oczekiwany rezultat:**
- Lokalizacja zapisana jako "Wrocław"
- Mapa (jeśli dostępna) pokazuje Wrocław
- Współrzędne geograficzne są poprawne
- Inne użytkownicy widzą lokalizację

**Alternatywny scenariusz:**
- Kliknij "Użyj mojej lokalizacji"
- Potwierdź uprawnienia do lokalizacji
- Miasto zostaje automatycznie uzupełnione

---

### TC-PROFILE-006: Przeglądanie Własnego Profilu
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Profil ma wszystkie dane

**Kroki:**
1. Przejdź do zakładki "Profil"
2. Przewiń przez cały profil
3. Sprawdź wszystkie sekcje:
   - Zdjęcie profilowe
   - Nazwa/nazwa artystyczna
   - Lokalizacja (z mapką)
   - Wiek
   - Gatunki muzyczne
   - Instrumenty (dla artystów)
   - Biografia
   - Próbka muzyczna

**Oczekiwany rezultat:**
- Wszystkie dane są czytelne
- Zdjęcia ładują się poprawnie
- Mapa wyświetla się (jeśli dostępna)
- Audio player działa
- Brak błędów w konsoli

---

## Przeglądanie Profili (Swipe)

### TC-SWIPE-001: Swipe Right (Polubienie)
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Dostępne profile do przeglądania
- Ekran główny (swipe) otwarty

**Kroki:**
1. Przeglądaj wyświetlony profil
2. Przeczytaj bio
3. Odtwórz próbkę muzyczną (jeśli dostępna)
4. Wykonaj swipe w prawo (lub kliknij ikonę serca)
5. Obserwuj animację

**Oczekiwany rezultat:**
- Animacja swipe right
- Profil znika z ekranu
- Wyświetla się następny profil
- W przypadku matcha: Wyświetla się notyfikacja "It's a match!"
- Lubi zostaje zapisany w bazie

**Weryfikacja:**
- [ ] Animacja jest płynna
- [ ] Brak opóźnień
- [ ] Licznik swipe'ów aktualizuje się
- [ ] Nie można cofnąć przypadkowego swipe (bez premium)

---

### TC-SWIPE-002: Swipe Left (Odrzucenie)
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik na ekranie swipe
- Dostępne profile

**Kroki:**
1. Przeglądaj wyświetlony profil
2. Wykonaj swipe w lewo (lub kliknij X)

**Oczekiwany rezultat:**
- Animacja swipe left
- Profil znika
- Następny profil się wyświetla
- Brak notyfikacji
- Odrzucenie zapisane w bazie

---

### TC-SWIPE-003: Odtworzenie Próbki Muzycznej
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Przeglądany profil ma próbkę muzyczną

**Kroki:**
1. Na ekranie swipe wyświetl profil z próbką
2. Kliknij przycisk "Play" na audio playerze
3. Słuchaj przez 10 sekund
4. Kliknij "Pause"
5. Przewiń do środka utworu (seek)
6. Kliknij "Play" ponownie
7. Wykonaj swipe (prawo/lewo)

**Oczekiwany rezultat:**
- Audio odtwarza się natychmiast po kliknięciu
- Pause zatrzymuje odtwarzanie
- Seek działa prawidłowo
- Po swipe audio zatrzymuje się automatycznie
- Jakość dźwięku jest dobra

**Weryfikacja:**
- [ ] Brak opóźnień w odtwarzaniu
- [ ] Kontrolki responzywne
- [ ] Pasek postępu aktualizuje się płynnie
- [ ] Czas wyświetla się poprawnie

---

### TC-SWIPE-004: Przeglądanie Zdjęć (Galeria)
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Profil ma wiele zdjęć (2+)

**Kroki:**
1. Wyświetl profil z wieloma zdjęciami
2. Kliknij na zdjęcie profilowe
3. Przejdź do trybu pełnoekranowego
4. Przesuń palcem w prawo → poprzednie zdjęcie
5. Przesuń palcem w lewo → następne zdjęcie
6. Kliknij X lub back → powrót do profilu

**Oczekiwany rezultat:**
- Galeria otwiera się w pełnym ekranie
- Możliwość przewijania między zdjęciami
- Płynne przejścia
- Wskaźnik aktualnego zdjęcia (1/5, 2/5 itd.)
- Zoom in/out na zdjęciach (opcjonalnie)

---

### TC-SWIPE-005: Filtrowanie Profili
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik zalogowany
- Dostępne różnorodne profile

**Kroki:**
1. Na ekranie swipe kliknij ikonę filtrów
2. Ustaw filtry:
   - Wiek: 25-35
   - Odległość: max 50 km
   - Gatunki: Rock, Jazz
   - Typ: Tylko artyści
3. Zastosuj filtry
4. Przeglądaj profile

**Oczekiwany rezultat:**
- Wyświetlane profile spełniają kryteria filtrów
- Liczba dostępnych profili może się zmniejszyć
- Filtry są zapamiętywane do następnej sesji
- Możliwość wyczyszczenia filtrów

**Weryfikacja:**
- [ ] Wszystkie profile w zakresie 25-35 lat
- [ ] Odległość nie przekracza 50 km
- [ ] Tylko wybrane gatunki muzyczne
- [ ] Tylko artyści (brak zespołów)

---

### TC-SWIPE-006: Brak Dostępnych Profili
**Priorytet:** Średni  
**Typ:** Graniczny

**Warunki wstępne:**
- Wszystkie profile zostały przeswiped
- Lub zbyt restrykcyjne filtry

**Kroki:**
1. Swipuj do momentu wyczerpania profili
2. Obserwuj komunikat

**Oczekiwany rezultat:**
- Wyświetla się komunikat: "Brak nowych profili. Sprawdź później lub zmień filtry."
- Przycisk "Dostosuj filtry"
- Grafika/ilustracja pustego stanu
- Możliwość odświeżenia

---

### TC-SWIPE-007: Swipe podczas Braku Internetu
**Priorytet:** Wysoki  
**Typ:** Negatywny

**Warunki wstępne:**
- Użytkownik na ekranie swipe
- Dostępne profile w cache

**Kroki:**
1. Wyświetl kilka profili (aby były w cache)
2. Wyłącz połączenie internetowe
3. Wykonaj swipe right/left
4. Spróbuj załadować następne profile

**Oczekiwany rezultat:**
- Profile z cache nadal działają
- Swipe'y są zapisywane lokalnie
- Komunikat: "Brak internetu. Synchronizacja nastąpi po przywróceniu połączenia."
- Po przywróceniu internetu: Automatyczna synchronizacja

---

## Matching

### TC-MATCH-001: Otrzymanie Matcha
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik A swipnął right na użytkownika B
- Użytkownik B swipuje right na użytkownika A

**Kroki:**
1. Zaloguj się jako Użytkownik B
2. Przejdź do ekranu swipe
3. Znajdź profil Użytkownika A
4. Wykonaj swipe right

**Oczekiwany rezultat:**
- Wyświetla się ekran "It's a Match!"
- Zdjęcia obu użytkowników
- Animacja confetti/fajerwerków
- Przyciski:
  - "Wyślij wiadomość"
  - "Kontynuuj przeglądanie"
- Dźwięk powiadomienia (jeśli włączony)
- Match dodany do listy "Matches"

**Weryfikacja:**
- [ ] Oba konta mają match w liście
- [ ] Możliwość rozpoczęcia konwersacji
- [ ] Notyfikacja push (jeśli włączona)

---

### TC-MATCH-002: Lista Matchów
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma co najmniej 3 matche

**Kroki:**
1. Przejdź do zakładki "Matches"
2. Przewiń listę matchów
3. Obserwuj:
   - Zdjęcia profilowe
   - Nazwy użytkowników
   - Ostatnia wiadomość (jeśli istnieje)
   - Czas ostatniej aktywności
4. Kliknij na jeden match

**Oczekiwany rezultat:**
- Lista wyświetla wszystkie matche
- Sortowanie: Najnowsze na górze
- Podgląd ostatniej wiadomości
- Odznaki dla nieprzeczytanych wiadomości
- Możliwość przejścia do chatu

---

### TC-MATCH-003: Unmatch (Usunięcie Matcha)
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma aktywny match

**Kroki:**
1. Przejdź do listy matchów
2. Long press na wybranym matchu (lub swipe left)
3. Wybierz "Unmatch"
4. Potwierdź akcję w dialogu:
   - "Czy na pewno chcesz usunąć ten match?"
   - "Nie będziecie już mogli rozmawiać"
5. Kliknij "Potwierdź"

**Oczekiwany rezultat:**
- Match zostaje usunięty z listy
- Konwersacja zostaje usunięta
- Użytkownik może ponownie pojawić się w swipe (opcjonalnie)
- Komunikat: "Match został usunięty"

---

### TC-MATCH-004: Zgłoszenie Użytkownika
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma match lub przegląda profil

**Kroki:**
1. Otwórz profil użytkownika (z matcha lub swipe)
2. Kliknij menu (⋮)
3. Wybierz "Zgłoś użytkownika"
4. Wybierz powód:
   - Nieodpowiednie zdjęcia
   - Spam
   - Oszustwo
   - Molestowanie
   - Inne
5. (Opcjonalnie) Dodaj opis
6. Kliknij "Wyślij zgłoszenie"

**Oczekiwany rezultat:**
- Zgłoszenie zostało wysłane
- Komunikat: "Dziękujemy za zgłoszenie. Sprawdzimy to."
- Użytkownik zostaje automatycznie unmatchowany
- Profil nie wyświetla się ponownie

---

## Czat i Wiadomości

### TC-CHAT-001: Wysłanie Pierwszej Wiadomości
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik ma nowy match
- Brak poprzednich wiadomości

**Kroki:**
1. Przejdź do listy matchów
2. Kliknij na nowy match
3. W polu tekstowym wpisz: "Cześć! Świetna muzyka!"
4. Kliknij "Wyślij" (ikonę samolotu)

**Oczekiwany rezultat:**
- Wiadomość pojawia się w oknie chatu
- Wyświetla się po prawej stronie (twoja wiadomość)
- Status: "Wysłano" → "Doręczono" → "Przeczytano"
- Timestamp (czas wysłania)
- Druga osoba otrzymuje notyfikację

**Weryfikacja:**
- [ ] Wiadomość widoczna natychmiast
- [ ] Brak opóźnień (< 1s)
- [ ] Możliwość scrollowania
- [ ] Pole tekstowe wyczyszczone po wysłaniu

---

### TC-CHAT-002: Odbieranie Wiadomości w Czasie Rzeczywistym
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Dwa urządzenia/emulatory z dwoma zalogowanymi użytkownikami (A i B)
- Użytkownicy mają match

**Kroki:**
1. Urządzenie A: Otwórz chat z użytkownikiem B
2. Urządzenie B: Otwórz chat z użytkownikiem A
3. Urządzenie B: Wyślij wiadomość: "Hej, jak leci?"
4. Obserwuj Urządzenie A

**Oczekiwany rezultat:**
- Wiadomość pojawia się natychmiast na Urządzeniu A (< 2s)
- Wyświetla się po lewej stronie
- Notyfikacja dźwiękowa (jeśli włączona)
- Status "Przeczytano" aktualizuje się na Urządzeniu B

---

### TC-CHAT-003: Wysyłanie Wielu Wiadomości
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Kroki:**
1. Otwórz chat
2. Wyślij szybko 5 wiadomości jedną po drugiej:
   - "Wiadomość 1"
   - "Wiadomość 2"
   - "Wiadomość 3"
   - "Wiadomość 4"
   - "Wiadomość 5"

**Oczekiwany rezultat:**
- Wszystkie wiadomości wysłane w kolejności
- Brak duplikatów
- Brak zgubień
- Timestamps odzwierciedlają kolejność
- Scrollowanie automatyczne do najnowszej

---

### TC-CHAT-004: Wysyłanie Emoji
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Kroki:**
1. Otwórz chat
2. Kliknij ikonę emoji
3. Wybierz kilka emoji: 🎵🎸😊🎤
4. Wyślij wiadomość

**Oczekiwany rezultat:**
- Emoji wyświetlają się poprawnie
- Rozmiar emoji odpowiedni
- Brak problemów z renderowaniem
- Odbiorca widzi te same emoji

---

### TC-CHAT-005: Długa Wiadomość
**Priorytet:** Średni  
**Typ:** Graniczny

**Kroki:**
1. Otwórz chat
2. Wpisz bardzo długi tekst (500+ znaków):
   ```
   Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
   Sed do eiusmod tempor incididunt ut labore et dolore magna 
   aliqua. Ut enim ad minim veniam, quis nostrud exercitation 
   ullamco laboris nisi ut aliquip ex ea commodo consequat...
   [kontynuuj do 500+ znaków]
   ```
3. Wyślij

**Oczekiwany rezultat:**
- Wiadomość wysłana pomyślnie
- Tekst zawijany w bąbelku wiadomości
- Możliwość scrollowania w długiej wiadomości
- Brak przekroczenia limitu znaków (jeśli istnieje)
- Alternatywnie: Walidacja max długości przed wysłaniem

---

### TC-CHAT-006: Scrollowanie Historii Wiadomości
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Konwersacja ma 50+ wiadomości

**Kroki:**
1. Otwórz chat z długą historią
2. Scroll do góry (starsze wiadomości)
3. Kontynuuj scrollowanie aż do początku
4. Scroll z powrotem na dół

**Oczekiwany rezultat:**
- Płynne scrollowanie
- Lazy loading starszych wiadomości (po 20-50 na raz)
- Loading indicator podczas ładowania
- Możliwość szybkiego przejścia na dół (przycisk)
- Brak lagów

---

### TC-CHAT-007: Oznaczanie Wiadomości jako Przeczytane
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik A wysłał wiadomość do B
- Użytkownik B ma nieprzeczytaną wiadomość

**Kroki:**
1. Użytkownik B: Otwórz listę matchów
2. Obserwuj badge "nieprzeczytane" (np. czerwona kropka)
3. Kliknij na chat z Użytkownikiem A
4. Wiadomość jest widoczna
5. Wróć do listy matchów

**Oczekiwany rezultat:**
- Badge "nieprzeczytane" znika
- Użytkownik A widzi status "Przeczytano" przy wiadomości
- Licznik nieprzeczytanych aktualizuje się

---

### TC-CHAT-008: Brak Internetu podczas Wysyłania
**Priorytet:** Wysoki  
**Typ:** Negatywny

**Kroki:**
1. Otwórz chat
2. Wyłącz internet
3. Wpisz wiadomość: "Test offline"
4. Kliknij "Wyślij"
5. Obserwuj status wiadomości
6. Włącz internet po 10 sekundach

**Oczekiwany rezultat:**
- Wiadomość pokazuje się lokalnie
- Status: "Wysyłanie..." lub ikonka zegara
- Po przywróceniu internetu: Automatyczne wysłanie
- Status zmienia się na "Wysłano"
- Komunikat: "Wiadomość zostanie wysłana po przywróceniu połączenia"

---

### TC-CHAT-009: Blokowanie Użytkownika z Poziomu Chatu
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Kroki:**
1. Otwórz chat
2. Kliknij menu (⋮) w górnym rogu
3. Wybierz "Zablokuj użytkownika"
4. Potwierdź w dialogu

**Oczekiwany rezultat:**
- Użytkownik zablokowany
- Match zostaje usunięty
- Brak możliwości wysyłania wiadomości
- Komunikat: "Użytkownik został zablokowany"
- Profil nie pojawi się ponownie w swipe

---

## Nawigacja

### TC-NAV-001: Przełączanie między Zakładkami
**Priorytet:** Krytyczny  
**Typ:** Funkcjonalny

**Kroki:**
1. Uruchom aplikację (zalogowany)
2. Kliknij zakładkę "Swipe" → Sprawdź czy wyświetla się ekran swipe
3. Kliknij zakładkę "Matches" → Sprawdź listę matchów
4. Kliknij zakładkę "Czat" → Sprawdź aktywne konwersacje
5. Kliknij zakładkę "Profil" → Sprawdź własny profil

**Oczekiwany rezultat:**
- Każda zakładka otwiera się natychmiast (< 300ms)
- Stan jest zachowany (np. pozycja scrollowania)
- Aktywna zakładka jest podświetlona
- Brak błędów podczas przełączania

**Weryfikacja:**
- [ ] Bottom navigation bar responsywny
- [ ] Ikony zmieniają kolor przy aktywacji
- [ ] Brak migotania ekranu

---

### TC-NAV-002: Back Button na Androidzie
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny (Android)

**Kroki:**
1. Ekran główny (Swipe)
2. Przejdź do Profil
3. Kliknij systemowy back button
4. → Powinno wrócić do Swipe
5. Z ekranu Swipe kliknij back
6. → Powinno zapytać "Czy na pewno chcesz wyjść?"

**Oczekiwany rezultat:**
- Back button działa intuicyjnie
- Nie zamyka aplikacji nieoczekiwanie
- Dialog potwierdzenia przed zamknięciem

---

### TC-NAV-003: Deep Link do Profilu
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Użytkownik dostaje link do profilu (np. przez wiadomość)
- Format: `soundmates://profile/user123`

**Kroki:**
1. Kliknij na link deep link
2. Aplikacja otwiera się (lub aktywuje)
3. Wyświetla się profil user123

**Oczekiwany rezultat:**
- Aplikacja otwiera bezpośrednio profil
- Jeśli niezalogowany: Prośba o logowanie, potem redirect
- Przycisk "Back" wraca do poprzedniego ekranu

---

## Audio i Multimedia

### TC-AUDIO-001: Odtwarzanie Próbki - Start/Stop
**Priorytet:** Wysoki  
**Typ:** Funkcjonalny

**Kroki:**
1. Otwórz profil z próbką muzyczną
2. Kliknij "Play"
3. Słuchaj przez 5 sekund
4. Kliknij "Pause"
5. Kliknij "Play" ponownie
6. Zamknij profil (back lub swipe)

**Oczekiwany rezultat:**
- Audio odtwarza się natychmiast
- Pause zatrzymuje odtwarzanie
- Wznowienie działa od miejsca zatrzymania
- Zamknięcie profilu zatrzymuje audio automatycznie

---

### TC-AUDIO-002: Seek (Przewijanie Utworu)
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Kroki:**
1. Odtwórz próbkę muzyczną
2. Przesuń slider seekbar do środka utworu
3. Obserwuj czy odtwarzanie kontynuuje od tego miejsca
4. Przesuń na koniec
5. Przesuń na początek

**Oczekiwany rezultat:**
- Seek działa płynnie
- Audio kontynuuje od wybranego miejsca
- Brak trzasków/głitchy w audio
- Czas wyświetla się poprawnie

---

### TC-AUDIO-003: Kontrola Głośności
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Kroki:**
1. Odtwórz próbkę muzyczną
2. Użyj przycisków głośności urządzenia:
   - Volume Up (zwiększenie)
   - Volume Down (zmniejszenie)
   - Mute (wyciszenie)

**Oczekiwany rezultat:**
- Głośność zmienia się zgodnie z przyciskami urządzenia
- Wyciszenie zatrzymuje dźwięk
- Wskaźnik głośności aktualizuje się

---

### TC-AUDIO-004: Odtwarzanie w Tle
**Priorytet:** Niski  
**Typ:** Funkcjonalny

**Kroki:**
1. Odtwórz próbkę muzyczną
2. Zminimalizuj aplikację (Home button)
3. Obserwuj czy audio kontynuuje

**Oczekiwany rezultat:**
- Audio zatrzymuje się po zminimalizowaniu (oczekiwane dla próbek)
- Alternatywnie: Kontynuuje przez 10s, potem zatrzymuje

---

### TC-AUDIO-005: Notyfikacje Dźwiękowe
**Priorytet:** Średni  
**Typ:** Funkcjonalny

**Warunki wstępne:**
- Dźwięki powiadomień włączone w ustawieniach

**Scenariusze testowe:**

| Event | Oczekiwany dźwięk |
|-------|-------------------|
| Nowy match | Dźwięk "match-given.mp3" |
| Nowa wiadomość | Dźwięk "message-received.mp3" |
| Swipe right | Opcjonalnie: Subtelny feedback |

**Weryfikacja:**
- [ ] Dźwięki odtwarzają się natychmiast
- [ ] Nie nakładają się na siebie
- [ ] Respektują tryb cichy urządzenia

---

## Obsługa Błędów

### TC-ERROR-001: 401 Unauthorized (Token Wygasł)
**Priorytet:** Krytyczny  
**Typ:** Negatywny

**Warunki wstępne:**
- Token wygasł lub jest nieważny

**Symulacja:**
1. Zaloguj się
2. Backend: Ręcznie unieważnij token w bazie
3. W aplikacji: Wykonaj akcję wymagającą autentykacji (np. swipe)

**Oczekiwany rezultat:**
- Aplikacja wykrywa błąd 401
- Automatyczna próba odświeżenia tokenu (refresh token)
- Jeśli refresh nie działa: Wylogowanie + redirect do logowania
- Komunikat: "Sesja wygasła. Zaloguj się ponownie."

---

### TC-ERROR-002: 500 Internal Server Error
**Priorytet:** Wysoki  
**Typ:** Negatywny

**Symulacja:**
1. Backend zwraca 500 dla konkretnego endpointa
2. W aplikacji wykonaj akcję wywołującą ten endpoint

**Oczekiwany rezultat:**
- Komunikat użytkownikowi: "Wystąpił błąd serwera. Spróbuj ponownie później."
- Przycisk "Spróbuj ponownie"
- Logowanie błędu (do analytics/Sentry)
- Aplikacja nie crashuje

---

### TC-ERROR-003: Brak Połączenia przy Starcie Aplikacji
**Priorytet:** Wysoki  
**Typ:** Negatywny

**Kroki:**
1. Wyłącz internet na urządzeniu
2. Uruchom aplikację

**Oczekiwany rezultat:**
- Wyświetla się ekran offline:
  - Ikona braku połączenia
  - Komunikat: "Brak połączenia z internetem"
  - Przycisk "Odśwież"
- Po włączeniu internetu i kliknięciu "Odśwież": Normalne działanie

---

### TC-ERROR-004: Upload Fail - Zdjęcie Zbyt Duże
**Priorytet:** Średni  
**Typ:** Negatywny

**Kroki:**
1. Przejdź do edycji profilu
2. Spróbuj dodać zdjęcie > 10MB
3. Kliknij "Zapisz"

**Oczekiwany rezultat:**
- Walidacja przed uploadem
- Komunikat: "Zdjęcie jest zbyt duże. Maksymalny rozmiar to 5MB."
- Opcja automatycznej kompresji
- Możliwość wyboru innego zdjęcia

---

### TC-ERROR-005: Nieprawidłowy Format Pliku Audio
**Priorytet:** Średni  
**Typ:** Negatywny

**Kroki:**
1. Edytuj profil
2. Spróbuj dodać plik audio w formacie .wav lub .flac
3. Kliknij "Zapisz"

**Oczekiwany rezultat:**
- Walidacja formatu
- Komunikat: "Nieobsługiwany format. Użyj pliku MP3."
- Brak uploadu nieprawidłowego pliku

---

## Performance i UX

### TC-PERF-001: Czas Ładowania Aplikacji
**Priorytet:** Wysoki  
**Typ:** Performance

**Kroki:**
1. Całkowicie zamknij aplikację
2. Uruchom aplikację
3. Zmierz czas do wyświetlenia pierwszego ekranu (splash → login/home)

**Oczekiwany rezultat:**
- Cold start: < 3 sekundy
- Warm start: < 1 sekunda
- Splash screen wyświetla się płynnie
- Brak białych ekranów

**Narzędzia:** Stoper, Android Studio Profiler

---

### TC-PERF-002: Płynność Scrollowania
**Priorytet:** Średni  
**Typ:** Performance

**Kroki:**
1. Otwórz listę matchów (20+ elementów)
2. Szybko scroll w górę i w dół
3. Obserwuj:
   - FPS (frames per second)
   - Jittery/stuttering

**Oczekiwany rezultat:**
- 60 FPS podczas scrollowania
- Brak stutteringu
- Obrazy ładują się asynchronicznie

**Narzędzia:** Flutter DevTools, FPS counter

---

### TC-PERF-003: Zużycie Pamięci
**Priorytet:** Średni  
**Typ:** Performance

**Kroki:**
1. Uruchom aplikację
2. Przeglądaj 50 profili (swipe)
3. Odtwórz 10 próbek muzycznych
4. Przejdź do listy matchów
5. Otwórz 5 chatów
6. Sprawdź zużycie pamięci

**Oczekiwany rezultat:**
- Zużycie RAM: < 150 MB (dla Android mid-range)
- Brak memory leaks
- Obrazy i audio są poprawnie zwalniane z pamięci

**Narzędzia:** Android Studio Profiler, Dart Observatory

---

### TC-PERF-004: Zużycie Baterii
**Priorytet:** Niski  
**Typ:** Performance

**Kroki:**
1. Pełne naładowanie urządzenia
2. Korzystaj z aplikacji przez 1 godzinę:
   - 30 min swipowania
   - 20 min czatu
   - 10 min słuchania muzyki
3. Sprawdź statystyki baterii

**Oczekiwany rezultat:**
- Zużycie baterii: < 10% w ciągu godziny normalnego użytkowania
- Aplikacja nie jest w top 3 zużywających apps

---

### TC-UX-001: Accessibility - Czytnik Ekranu
**Priorytet:** Niski  
**Typ:** Accessibility

**Warunki wstępne:**
- Włączony TalkBack (Android) lub VoiceOver (iOS)

**Kroki:**
1. Nawiguj przez aplikację używając gestów czytnika
2. Sprawdź czy każdy element ma odpowiedni label
3. Przejdź przez ekran logowania
4. Wykonaj swipe
5. Otwórz chat

**Oczekiwany rezultat:**
- Wszystkie interaktywne elementy mają labels
- Kolejność focusa jest logiczna
- Komunikaty błędów są czytane
- Możliwość pełnego korzystania z aplikacji

---

### TC-UX-002: Dark Mode
**Priorytet:** Niski  
**Typ:** Funkcjonalny

**Kroki:**
1. Ustaw urządzenie w Dark Mode
2. Otwórz aplikację
3. Przejrzyj wszystkie ekrany

**Oczekiwany rezultat:**
- Aplikacja automatycznie przełącza się na ciemny motyw
- Wszystkie kolory są czytelne
- Brak białych "błysków"
- Ikony i grafiki dostosowane do dark mode

---

### TC-UX-003: Obsługa Landscape (Poziom)
**Priorytet:** Niski  
**Typ:** Funkcjonalny

**Kroki:**
1. Obróć urządzenie do poziomu
2. Sprawdź główne ekrany aplikacji

**Oczekiwany rezultat:**
- Aplikacja blokuje landscape mode (dla swipe app to normalne)
- Alternatywnie: UI dostosowuje się do landscape
- Brak uciętych elementów

---

## Podsumowanie Kategorii Testów

| Kategoria | Liczba Scenariuszy | Priorytet Krytyczny | Priorytet Wysoki |
|-----------|-------------------|---------------------|------------------|
| Autentykacja | 8 | 1 | 4 |
| Profil | 6 | 0 | 4 |
| Swipe | 7 | 2 | 3 |
| Matching | 4 | 1 | 2 |
| Czat | 9 | 3 | 3 |
| Nawigacja | 3 | 1 | 1 |
| Audio | 5 | 0 | 2 |
| Błędy | 5 | 1 | 3 |
| Performance | 7 | 0 | 1 |
| **TOTAL** | **54** | **9** | **23** |

---

## Instrukcje Wykonania Testów

### Przygotowanie Środowiska
1. Urządzenie testowe:
   - Android 8.0+ lub iOS 12+
   - Połączenie WiFi stabilne
   - Testowe konta użytkowników (min. 3)

2. Dane testowe:
   - Zdjęcia (różne rozmiary: 100KB, 2MB, 10MB)
   - Pliki audio MP3 (30s, 2min, 5min)
   - Różne formaty audio (.mp3, .wav, .flac) dla testów negatywnych

3. Backend testowy:
   - Środowisko staging/development
   - Możliwość symulacji błędów (500, 401, timeout)

### Raportowanie Błędów
Dla każdego znalezionego błędu należy podać:
- **ID scenariusza:** np. TC-AUTH-001
- **Krok, w którym wystąpił błąd:** Krok 4
- **Oczekiwany rezultat:** Użytkownik zalogowany
- **Aktualny rezultat:** Błąd "Invalid credentials"
- **Severity:** Critical / High / Medium / Low
- **Screenshots/Video:** Załącz
- **Logi:** Z konsoli/logcat
- **Środowisko:** Android 12, Pixel 5

### Harmonogram Testów
**Faza 1 - Funkcje Krytyczne (2 dni):**
- Autentykacja (TC-AUTH-001 do TC-AUTH-003)
- Swipe podstawowy (TC-SWIPE-001, TC-SWIPE-002)
- Matching (TC-MATCH-001)
- Czat podstawowy (TC-CHAT-001, TC-CHAT-002)

**Faza 2 - Funkcje Wysokiego Priorytetu (3 dni):**
- Pozostałe scenariusze autentykacji
- Profil użytkownika
- Obsługa błędów krytycznych

**Faza 3 - Funkcje Średniego/Niskiego Priorytetu (3 dni):**
- Performance
- UX/Accessibility
- Edge cases

**Faza 4 - Testy Regresji (2 dni):**
- Ponowne wykonanie testów krytycznych
- Weryfikacja poprawionych błędów

---

## Checklisty Szybkiego Testu (Smoke Test)

### ✅ Smoke Test - Przed Release
- [ ] Logowanie działa
- [ ] Rejestracja nowego użytkownika działa
- [ ] Swipe right/left działa
- [ ] Match wyświetla się poprawnie
- [ ] Wysyłanie wiadomości działa
- [ ] Odbieranie wiadomości w czasie rzeczywistym działa
- [ ] Odtwarzanie próbki muzycznej działa
- [ ] Upload zdjęcia profilowego działa
- [ ] Edycja profilu zapisuje się
- [ ] Wylogowanie działa
- [ ] Aplikacja nie crashuje przy podstawowym flow

**Czas wykonania:** ~30 minut

---

