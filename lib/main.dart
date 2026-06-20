import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LunaWashApp());
}

class LunaWashApp extends StatelessWidget {
  const LunaWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LunaWash Customer App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F2050),
          primary: const Color(0xFF0F2050),
          secondary: const Color(0xFF4EE1F1),
          background: const Color(0xFFF8F9FA),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF0F2050),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
