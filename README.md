# Market Mate — complete offline MVP

Copy `lib/` and `pubspec.yaml` into your Flutter project.

Run:

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The generated `lib/core/database/app_database.g.dart` is required and must not be edited manually.

For Android, launch an emulator and use `flutter devices`, then `flutter run -d <android-device-id>`.

To reset all local data while testing, uninstall the app from the emulator/device and reinstall it.
