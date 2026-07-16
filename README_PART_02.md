# Market Mate — Part 2

This part replaces Part 1 and adds:

- Drift/SQLite database foundation
- Business registration
- Owner profile
- Four-digit PIN creation
- PIN hashing with a random salt
- PIN login
- Logout / manual app locking
- Initial dashboard

## Installation

Copy this folder's `lib` directory and `pubspec.yaml` into your Flutter project.

Run:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The build_runner command generates:

```text
lib/core/database/app_database.g.dart
```

Do not create that generated file manually.

## Testing registration again

The registration is stored in the local SQLite database. To reset during development, uninstall the app from the emulator/device, or clear the app's data, then run it again.
