import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';

class BarberBookApp extends ConsumerWidget {
  const BarberBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'BarberBook',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark, // Force true black theme
    );
  }
}

// ── Minimalist Luxury Design Tokens ──────────────────────────────────────────

const _accentColor = Color(0xFFAFAF8F); // Sophisticated Muted Gold
const _pureBlack = Color(0xFF000000);
const _deepGrey = Color(0xFF121212); // Slightly lighter for cards
const _surfaceGrey = Color(0xFF222222);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? _pureBlack : Colors.white;
  final onSurface = isDark ? Colors.white : _pureBlack;
  final cardColor = isDark ? _deepGrey : const Color(0xFFF9F9F9);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: surface,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _accentColor,
      primary: onSurface,
      secondary: _accentColor,
      surface: surface,
      onSurface: onSurface,
      brightness: brightness,
    ),

    // ── Typography: Minimalist & Elegant ─────────────────────────────────────
    textTheme: GoogleFonts.interTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w200, letterSpacing: -2, color: onSurface),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w300, letterSpacing: -1, color: onSurface),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 22, color: onSurface),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, color: onSurface),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, color: onSurface.withOpacity(0.9)),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 11, color: _accentColor),
    ),

    // ── Components ───────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: onSurface),
      titleTextStyle: GoogleFonts.inter(
        color: onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w300,
        letterSpacing: 3,
      ),
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDark ? BorderSide(color: Colors.white.withOpacity(0.05), width: 1) : BorderSide.none,
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: onSurface,
        foregroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? _deepGrey : const Color(0xFFF1F1F1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(color: Colors.grey),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: _accentColor.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.5),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final sel = states.contains(WidgetState.selected);
        return IconThemeData(color: sel ? _accentColor : onSurface.withOpacity(0.3), size: 24);
      }),
    ),
  );
}
