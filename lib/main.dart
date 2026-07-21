import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:solar_erp_app/app/app_routes.dart';
import 'package:solar_erp_app/app/navigator.dart';
import 'package:solar_erp_app/core/providers/global_loading_provider.dart';
import 'package:solar_erp_app/core/theme/app_theme_provider.dart';
import 'package:solar_erp_app/core/theme/theme_mode_provider.dart';
import 'package:solar_erp_app/shared/widgets/global_overlays.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const Root());
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();

  static void restartApp() => triggerAppRestart();
}

class _RootState extends State<Root> {
  Key key = UniqueKey();

  void restart() {
    setState(() => key = UniqueKey());
  }

  @override
  void initState() {
    super.initState();
    appRestartCallback = restart;
  }

  @override
  void dispose() {
    if (appRestartCallback == restart) {
      appRestartCallback = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(key: key, child: const MyApp());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(appThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IMT-BillBook',
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      theme: _buildTheme(primaryColor, Brightness.light),
      darkTheme: _buildTheme(primaryColor, Brightness.dark),
      initialRoute: '/',
      routes: AppRoutes.routes,
      builder: (context, child) {
        final overlay = ref.watch(globalLoadingProvider);
        return Stack(
          children: [
            child!,
            if (overlay.isLoading) GlobalLoader(message: overlay.message),
            if (overlay.isSuccess) GlobalSuccess(message: overlay.message),
            if (overlay.isError) GlobalError(message: overlay.message),
            if (overlay.isMessage) GlobalMessage(message: overlay.message),
          ],
        );
      },
    );
  }

  ThemeData _buildTheme(Color primary, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    final baseText = brightness == Brightness.dark
        ? ThemeData(brightness: Brightness.dark).textTheme
        : ThemeData(brightness: Brightness.light).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
      scaffoldBackgroundColor:
          brightness == Brightness.light ? const Color(0xFFF4F7F6) : null,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
