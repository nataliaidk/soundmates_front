## Refaktoryzacja ProfileScreen - Plan

### Utworzone pliki:
1. ✅ `profile_data_loader.dart` - ładowanie danych z API
2. ✅ `profile_tag_manager.dart` - zarządzanie tagami
3. ✅ `profile_band_member_dialog.dart` - dialog członków zespołu
4. ✅ `profile_edit_step1.dart` - Step 1 edycji (podstawowe info)

### Do utworzenia:
5. `profile_edit_step2.dart` - Step 2 edycji (tagi, opis, członkowie, zdjęcie)
6. `profile_view_tabs.dart` - widok profilu (Your Info + Multimedia)
7. `profile_pickers.dart` - dialogi wyboru kraju i miasta
8. `profile_screen.dart` - główny orkiestrator (zredukowany z 2100+ do ~400 linii)

### Korzyści:
- Każdy plik < 400 linii (łatwa nawigacja)
- Separation of concerns (każdy plik ma jedną odpowiedzialność)
- Łatwiejsze testowanie
- Możliwość reużycia komponentów
- Lepsze zarządzanie stanem

### Następne kroki:
1. Utworzyć pozostałe pliki
2. Zrefaktoryzować główny profile_screen.dart
3. Zaktualizować import w main.dart
4. Przetestować całość

Czy chcesz, żebym kontynuował tworzenie pozostałych plików?
