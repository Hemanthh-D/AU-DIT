import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/complaint_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ComplaintProvider(),
      child: const AUDITApp(),
    ),
  );
}

class AUDITApp extends StatelessWidget {
  const AUDITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AU-DIT',

      theme: ThemeData(
        useMaterial3: true, // ✅ modern UI

        brightness: Brightness.light,

        scaffoldBackgroundColor: const Color(0xFFF8F9FA),

        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Color(0xFFFFE4E6),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: 0.5,
          ),
        ),

        // ✅ FIXED HERE
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),

        // ✨ Optional premium button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // ✨ Better text feel
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
