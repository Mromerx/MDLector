import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/app_settings.dart';
import 'ui/screens/reader_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persistent settings before the first frame so saved values are used
  // immediately.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MdLectorApp(),
    ),
  );
}

/// Royal blue: the app's main accent colour.
const Color kRoyalBlue = Color(0xFF2447E0);

/// Light tint of the royal blue, for the accent in dark mode.
const Color kRoyalBlueLight = Color(0xFFAEC1FF);

/// Pale tint of the royal blue, for containers in light mode.
const Color kRoyalBluePale = Color(0xFFD9E1FF);

/// Amber: third colour, for warnings and alert states.
const Color kAmber = Color(0xFFFFB300);

/// Application root.
class MdLectorApp extends ConsumerWidget {
  const MdLectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp(
      title: 'MDLector',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: settings.get(Settings.themeIsDark)
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const ReaderScreen(),
    );
  }

  /// Same palette as the reference reader: soft neutrals + royal blue accent +
  /// amber for warnings.
  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final amber = dark ? kAmber : const Color(0xFFB37400);
    final scheme = ColorScheme.fromSeed(
      seedColor: kRoyalBlue,
      brightness: brightness,
    ).copyWith(
      primary: dark ? kRoyalBlueLight : kRoyalBlue,
      onPrimary: dark ? const Color(0xFF1B1B1B) : Colors.white,
      primaryContainer: dark ? kRoyalBlue : kRoyalBluePale,
      onPrimaryContainer: dark ? Colors.white : const Color(0xFF1B1B1B),
      secondary: dark ? kRoyalBlueLight : kRoyalBlue,
      onSecondary: dark ? const Color(0xFF1B1B1B) : Colors.white,
      secondaryContainer: dark ? kRoyalBlue : kRoyalBluePale,
      onSecondaryContainer: dark ? Colors.white : const Color(0xFF1B1B1B),
      tertiary: amber,
      onTertiary: dark ? const Color(0xFF241A00) : Colors.white,
      tertiaryContainer:
          dark ? const Color(0xFF5A4300) : const Color(0xFFFFE2A6),
      onTertiaryContainer:
          dark ? const Color(0xFFFFE2A6) : const Color(0xFF241A00),
      error: amber,
      onError: dark ? const Color(0xFF241A00) : Colors.white,
      surface: dark ? const Color(0xFF1B1B1B) : const Color(0xFFEFEFEF),
      onSurface: dark ? const Color(0xFFDADADA) : const Color(0xFF2B2B2B),
      onSurfaceVariant:
          dark ? const Color(0xFFA6A6A6) : const Color(0xFF616161),
      surfaceContainerLowest:
          dark ? const Color(0xFF161616) : const Color(0xFFF6F6F6),
      surfaceContainerLow:
          dark ? const Color(0xFF202020) : const Color(0xFFE9E9E9),
      surfaceContainer:
          dark ? const Color(0xFF262626) : const Color(0xFFE3E3E3),
      surfaceContainerHigh:
          dark ? const Color(0xFF2D2D2D) : const Color(0xFFDCDCDC),
      surfaceContainerHighest:
          dark ? const Color(0xFF343434) : const Color(0xFFD5D5D5),
      outline: dark ? const Color(0xFF7A7A7A) : const Color(0xFF9E9E9E),
      outlineVariant: dark ? const Color(0xFF424242) : const Color(0xFFCFCFCF),
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF1B1B1B) : const Color(0xFFEFEFEF),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
