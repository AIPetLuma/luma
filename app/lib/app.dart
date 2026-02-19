import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/app_router.dart';
import 'shared/l10n.dart';

/// Root widget with Material 3 theming.
class LumaApp extends StatelessWidget {
  const LumaApp({super.key});

  static const _seed = Color(0xFF6B4EFF);

  @override
  Widget build(BuildContext context) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF121218),
      onSurface: const Color(0xFFE4E1E9),
      surfaceContainerHighest: const Color(0xFF2A2831),
      primary: const Color(0xFFB8A5FF),
      onPrimary: const Color(0xFF1E0F47),
      primaryContainer: const Color(0xFF3D2D6B),
      secondary: const Color(0xFF9ECAFF),
      tertiary: const Color(0xFFE8B4F8),
    );

    return MaterialApp(
      title: 'Luma',
      debugShowCheckedModeBanner: false,
      // i18n: English + Chinese
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        L10nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _buildTheme(lightScheme, Brightness.light),
      darkTheme: _buildTheme(darkScheme, Brightness.dark),
      home: const AppRouter(),
    );
  }

  ThemeData _buildTheme(ColorScheme scheme, Brightness brightness) {
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: brightness,
    );

    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
