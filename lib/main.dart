import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';

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
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFF0F2050),
              body: Center(child: CircularProgressIndicator(color: Color(0xFF4EE1F1))),
            );
          }
          final token = snapshot.data?.getString('jwt_token');
          if (token != null && token.isNotEmpty) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
