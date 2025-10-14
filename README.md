# zpi_test

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API demo

This project includes a small API client wired to the OpenAPI at `http://localhost:5000/`.

Files added:
- `lib/api/api_client.dart` — small HTTP client for the Soundmates API.
- `lib/api/models.dart` — DTO model classes used by the client.
- `lib/main.dart` — demo page (`ApiDemoPage`) with buttons to call `GET /users` and `GET /messages/preview` and show responses.

How to configure and run:

1. Create a `.env` file in the project root with the API base URL (optional if using default `http://localhost:5000/`):

```
API_BASE_URL=http://localhost:5000/
```

2. Get packages:

```
flutter pub get
```

3. Run the app (desktop or device):

```
flutter run
```

4. Open the app and press "Get Users" or "Get Message Previews" to see the raw JSON responses returned by the API running at `API_BASE_URL`.

Notes and next steps:
- The client is intentionally simple (uses `http` and manual DTOs). For production, consider code generation using OpenAPI Generator or `openapi_yaml` packages.
- Endpoints for file upload and authentication tokens are present in `ApiClient` but the demo UI only exercises simple GET endpoints. You can extend it to call register/login and persist tokens.

