import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../data/fitness_repository.dart';
import '../domain/training_cycle.dart';
import '../domain/training_plan_template.dart';
import 'workout_editor_page.dart';

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  late final FitnessRepository _repository;
  late Future<FitnessDashboardData?> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _repository = FitnessRepository(widget.database);
    _dashboardFuture = _repository.loadDashboard();
  }

  void _reload() {
    setState(() => _dashboardFuture = _repository.loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FitnessDashboardData?>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error, onRetry: _reload);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final dashboard = snapshot.data;
        if (dashboard == null) {
          return _TemplatePicker(
            onSelected: (template) async {
              await _repository.activateTemplate(template);
              _reload();
            },
          );
        }

        return _FitnessDashboard(
          dashboard: dashboard,
          onStartWorkout: () => _startWorkout(dashboard),
          onRest: _takeRest,
          onSkip: _skipTraining,
        );
      },
    );
  }

  Future<void> _startWorkout(FitnessDashboardData dashboard) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WorkoutEditorPage(repository: _repository, dashboard: dashboard),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _takeRest() async {
    final type = await _repository.takeRest();
    if (!mounted) return;
    final message = switch (type) {
      CycleExecutionType.plannedRest => '预设休息日已完成',
      CycleExecutionType.movedRest => '已提前使用本轮下一个预设休息日',
      CycleExecutionType.extraRest => '已记录额外休息，训练位置保持不变',
      _ => '休息已记录',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _reload();
  }

  Future<void> _skipTraining() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过当前训练？'),
        content: const Text('该训练日会标记为跳过，循环将继续到下一日。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认跳过'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.skipCurrentTraining();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已跳过当前训练日')));
    _reload();
  }
}

class _TemplatePicker extends StatefulWidget {
  const _TemplatePicker({required this.onSelected});

  final Future<void> Function(TrainingPlanTemplate template) onSelected;

  @override
  State<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<_TemplatePicker> {
  String? _activatingId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('选择训练循环', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('先从模板建立活动计划。预设休息日可以在每轮中提前使用。'),
        const SizedBox(height: 24),
        for (final template in builtInTrainingPlanTemplates) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    template.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(template.description),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final day in template.days)
                        Chip(
                          avatar: Icon(
                            day.type == CycleDayType.rest
                                ? Icons.hotel_outlined
                                : Icons.fitness_center,
                            size: 16,
                          ),
                          label: Text(day.name),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _activatingId == null
                        ? () async {
                            setState(() => _activatingId = template.id);
                            try {
                              await widget.onSelected(template);
                            } catch (error) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('无法建立计划：$error')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _activatingId = null);
                              }
                            }
                          }
                        : null,
                    child: _activatingId == template.id
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('使用此模板'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _FitnessDashboard extends StatelessWidget {
  const _FitnessDashboard({
    required this.dashboard,
    required this.onStartWorkout,
    required this.onRest,
    required this.onSkip,
  });

  final FitnessDashboardData dashboard;
  final VoidCallback onStartWorkout;
  final Future<void> Function() onRest;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final nextDay = dashboard.progress.nextDay!;
    final consumedIds = dashboard.progress.consumedDayIds;
    final cycleColor = Color(dashboard.cycle.colorValue);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dashboard.plan.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text('第 ${dashboard.cycle.cycleNumber} 轮'),
                ],
              ),
            ),
            Container(
              width: 18,
              height: 48,
              decoration: BoxDecoration(
                color: cycleColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('当前', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  nextDay.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                if (nextDay.type == CycleDayType.training) ...[
                  FilledButton.icon(
                    onPressed: onStartWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始记录训练'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRest,
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text('今天休息'),
                  ),
                  TextButton(onPressed: onSkip, child: const Text('跳过此训练日')),
                ] else
                  FilledButton.icon(
                    onPressed: onRest,
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text('完成休息日'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('本轮进度', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in dashboard.planDays)
              Chip(
                avatar: Icon(
                  consumedIds.contains(day.id)
                      ? Icons.check_circle
                      : day.id == nextDay.id
                      ? Icons.radio_button_checked
                      : day.dayType == CycleDayType.rest.name
                      ? Icons.hotel_outlined
                      : Icons.circle_outlined,
                  size: 18,
                  color: consumedIds.contains(day.id) ? cycleColor : null,
                ),
                label: Text(day.name),
                side: day.id == nextDay.id
                    ? BorderSide(color: cycleColor, width: 2)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            const Text('无法读取训练数据'),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
