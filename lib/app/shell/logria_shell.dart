import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../features/fitness/presentation/fitness_page.dart';

class LogriaShell extends StatefulWidget {
  const LogriaShell({super.key, required this.database});

  final AppDatabase database;

  @override
  State<LogriaShell> createState() => _LogriaShellState();
}

class _LogriaShellState extends State<LogriaShell> {
  int _selectedIndex = 0;

  static const _destinations = <_Destination>[
    _Destination('今日', Icons.today_outlined, Icons.today),
    _Destination('训练', Icons.fitness_center_outlined, Icons.fitness_center),
    _Destination('饮食', Icons.restaurant_outlined, Icons.restaurant),
    _Destination('身体', Icons.monitor_weight_outlined, Icons.monitor_weight),
    _Destination('日历', Icons.calendar_month_outlined, Icons.calendar_month),
  ];

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logria'),
        actions: [
          IconButton(
            tooltip: '设置',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(child: _bodyFor(destination)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          for (final item in _destinations)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }

  Widget _bodyFor(_Destination destination) {
    if (destination.label == '训练') {
      return FitnessPage(database: widget.database);
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: _ModulePlaceholder(destination: destination),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  const _ModulePlaceholder({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          destination.label,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _descriptionFor(destination.label),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  destination.selectedIcon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                const Expanded(child: Text('离线数据基础已就绪，功能将在本轮逐步接入。')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _descriptionFor(String label) => switch (label) {
    '今日' => '集中查看今天的训练、饮食、营养和身体记录。',
    '训练' => '管理训练循环、动作、组数、次数、重量与 RIR。',
    '饮食' => '分别记录原始饮食文本与每日营养汇总。',
    '身体' => '按需记录体重、体脂率和身体围度。',
    '日历' => '按自然日期和训练轮次回顾全部记录。',
    _ => '',
  };
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
