import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/database/app_database.dart';
import '../l10n/app_localizations.dart';
import 'shell/logria_shell.dart';

class LogriaApp extends StatefulWidget {
  const LogriaApp({super.key, required this.database});

  final AppDatabase database;

  @override
  State<LogriaApp> createState() => _LogriaAppState();
}

class _LogriaAppState extends State<LogriaApp> {
  Locale? _locale;
  bool _localeChosen = false;

  @override
  void initState() {
    super.initState();
    _restoreLocale();
  }

  Future<void> _restoreLocale() async {
    try {
      final setting = await (widget.database.select(
        widget.database.appSettings,
      )..where((row) => row.keyName.equals('app.locale'))).getSingleOrNull();
      if (!mounted || _localeChosen) return;
      setState(
        () => _locale = ['en', 'zh'].contains(setting?.value)
            ? Locale(setting!.value)
            : null,
      );
    } catch (_) {
      /* Keep the system language when settings cannot be read. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF356859),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logria',
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8F4),
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: const Color(0xFFF0F4EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE1E8DF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        navigationBarTheme: const NavigationBarThemeData(height: 72),
      ),
      home: LogriaShell(
        database: widget.database,
        locale: _locale,
        onLocaleChanged: (locale) => setState(() {
          _localeChosen = true;
          _locale = locale;
        }),
      ),
    );
  }
}
