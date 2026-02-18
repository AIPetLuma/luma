import 'package:flutter/material.dart';
import 'shared/constants.dart';

/// Root widget. Routing and theme will be expanded as UI screens are built.
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
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary home screen — will be replaced by onboarding/home router.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Luma is waking up...',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
