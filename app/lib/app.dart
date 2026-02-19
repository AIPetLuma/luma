import 'package:flutter/material.dart';
import 'router/app_router.dart';

/// Root widget with Material 3 theming.
class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6B4EFF),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6B4EFF),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const AppRouter(),
    );
  }
}
