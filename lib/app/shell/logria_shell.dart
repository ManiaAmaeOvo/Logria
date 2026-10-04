import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../features/body/presentation/body_page.dart';
import '../../features/calendar/presentation/calendar_page.dart';
import '../../features/fitness/presentation/fitness_page.dart';
import '../../features/nutrition/presentation/nutrition_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/today/presentation/today_page.dart';
import '../../l10n/app_localizations.dart';

class LogriaShell extends StatefulWidget {
  const LogriaShell({
    super.key,
    required this.database,
    required this.onLocaleChanged,
    this.locale,
  });
  final AppDatabase database;
  final Locale? locale;
  final ValueChanged<Locale?> onLocaleChanged;
  @override
  State<LogriaShell> createState() => _LogriaShellState();
}

class _LogriaShellState extends State<LogriaShell> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/logria-icon.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 10),
            Text(l.appTitle),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => SettingsPage(
                  database: widget.database,
                  locale: widget.locale,
                  onLocaleChanged: widget.onLocaleChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_selectedIndex) {
          1 => FitnessPage(database: widget.database),
          2 => NutritionPage(database: widget.database),
          3 => BodyPage(database: widget.database),
          4 => CalendarPage(database: widget.database),
          _ => TodayPage(
            database: widget.database,
            onOpenModule: (index) => setState(() => _selectedIndex = index),
          ),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: const Icon(Icons.fitness_center),
            label: l.fitness,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: l.nutrition,
          ),
          NavigationDestination(
            icon: const Icon(Icons.monitor_weight_outlined),
            selectedIcon: const Icon(Icons.monitor_weight),
            label: l.body,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l.calendar,
          ),
        ],
      ),
    );
  }
}
