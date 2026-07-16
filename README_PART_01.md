# Market Mate - Part 01: Project Foundation

This part establishes:

- Flutter application entry point
- Riverpod ProviderScope
- Material 3 light and dark themes
- GoRouter configuration
- App constants
- A temporary bootstrap screen
- Full dependency list required by later stages

## Install

Copy `pubspec.yaml` and the `lib` folder into the root of your Flutter project, then run:

```bash
flutter clean
flutter pub get
flutter run
```

## Expected result

The app opens to a Market Mate bootstrap screen without database or feature logic yet.

## Next part

Part 02 will create the complete Drift database foundation, table definitions, database connection, migrations, DAOs, and providers.
