# SoundMates

A Flutter application for connecting music enthusiasts.

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or later)
- Dart SDK (included with Flutter)
- Android Studio (for Android emulator)
- A `.env` file in the project root with configuration:

```env
API_BASE_URL=http://localhost:5000/
API_ANDROID_URL=http://10.0.2.2:5000
LOGO_PATH=lib/assets/logo.png
```

### Install Dependencies

```bash
flutter pub get
```

---

## Native Splash Screen Setup

This project uses `flutter_native_splash` to generate native splash screens for Android, iOS, and Web.

### Configuration

The splash screen is configured in `flutter_native_splash.yaml`. Key settings:

- **Background colors**: Light mode (`#FFFFFF`), Dark mode (`#1A1A1A`)
- **Logo**: `lib/assets/logo.png`
- **Android 12+**: Uses background color only (no icon) to avoid circular mask clipping

### Generate Splash Screen Assets

After modifying `flutter_native_splash.yaml`, regenerate the assets:

```bash
dart run flutter_native_splash:create
```

This updates native resources in `android/app/src/main/res/` and `ios/Runner/`.

---

## Running the App

### Web

Run the app on a local web server:

```bash
flutter run -d web-server --web-port=5555 --web-hostname=localhost
```

Then open `http://localhost:5555` in your browser.

### Android Emulator

1. Start your Android emulator from Android Studio (AVD Manager)
2. Verify the emulator is detected:

```bash
flutter devices
```

3. Run the app:

```bash
flutter run -d emulator-5554
```

Or use **Run > Run 'main.dart'** in Android Studio.

---

## Android Build Troubleshooting

### Error: "Incompatible magic value 0 in class file"

This error indicates corrupted Gradle cache files. Follow these steps to fix:

#### Step 1: Stop Gradle Daemon

```powershell
cd android
.\gradlew.bat --stop
cd ..
```

#### Step 2: Clean Project Caches

```powershell
flutter clean
Remove-Item -Recurse -Force android\.gradle -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\app\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
```

#### Step 3: Clean User Gradle Cache

```powershell
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\caches -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $env:USERPROFILE\.gradle\daemon -ErrorAction SilentlyContinue
```

#### Step 4: Rebuild

```bash
flutter pub get
flutter run -d emulator-5554
```

### Prevention Tips

- **Don't interrupt builds**: Avoid pressing `Ctrl+C` while Gradle is downloading dependencies or compiling
- **Graceful exit**: Press `q` in the terminal to quit Flutter run gracefully
- **Stop daemon first**: If you need to cancel, run `.\android\gradlew.bat --stop` before cleaning caches

---

## API Client

This project includes an API client for the SoundMates backend at `http://localhost:5000/`.

### Key Files

- `lib/api/api_client.dart` — HTTP client for the SoundMates API
- `lib/api/models.dart` — DTO model classes
- `lib/api/token_store.dart` — Secure token storage

### Notes

- The client uses the `http` package with manual DTOs
- Authentication tokens are stored securely using `flutter_secure_storage`
- For production, consider code generation using OpenAPI Generator

