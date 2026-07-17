import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';

class SokoLinkApp extends StatelessWidget {
  const SokoLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF08783E);
    const forest = Color(0xFF064E2A);
    const lime = Color(0xFFB7D93D);
    const paleGreen = Color(0xFFF3F8EA);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.light,
    ).copyWith(
      primary: emerald,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDF2D1),
      onPrimaryContainer: forest,
      secondary: const Color(0xFF5C7F22),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFEAF3BE),
      tertiary: lime,
      onTertiary: forest,
      surface: Colors.white,
      surfaceContainer: const Color(0xFFEDF5E5),
      outline: const Color(0xFF9EAF98),
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF77D394),
      onPrimary: const Color(0xFF003919),
      primaryContainer: const Color(0xFF075B31),
      secondary: const Color(0xFFC6DF73),
      tertiary: lime,
      surface: const Color(0xFF0D2116),
      surfaceContainer: const Color(0xFF173324),
    );
    return MaterialApp(
      title: 'SokoLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: paleGreen,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: forest,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: forest,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 1,
          shadowColor: forest.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF08170F),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
