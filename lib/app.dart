import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';

class MarketMateApp extends StatelessWidget {
  const MarketMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0F766E);
    return MaterialApp(
      title: 'Market Mate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
