import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/number_format.dart';
import '../data/fitness_repository.dart';
import '../domain/training_cycle.dart';
import '../domain/training_plan_template.dart';
import '../../../l10n/app_localizations.dart';
import 'plan_editor_page.dart';
import 'workout_editor_page.dart';
import 'workout_history_page.dart';
import 'fitness_extras_page.dart';

String _templateName(TrainingPlanTemplate template, AppLocalizations l10n) =>
    switch (template.id) {
      'ppl' => 'PPL',
      'ppl_x2' => 'PPL × 2',
      'four_day_split' => l10n.fourSplit,
      _ => template.name,
    };

String _templateDescription(
  TrainingPlanTemplate template,
  AppLocalizations l10n,
) => switch (template.descriptionKey) {
  'pplDescription' => l10n.pplDescription,
  'ppl2Description' => l10n.ppl2Description,
  'fourSplitDescription' => l10n.fourSplitDescription,
  _ => template.descriptionKey,
};

String _templateDayName(String name, AppLocalizations l10n) => switch (name) {
  'push' => l10n.push,
  'pull' => l10n.pull,
  'legs' => l10n.legs,
  'rest' => l10n.rest,
  'chest' => l10n.chest,
  'back' => l10n.back,
  'shoulders' => l10n.shoulders,
  _ => name,
};

class FitnessPage extends StatefulWidget {
  const FitnessPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<FitnessPage> createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  late final FitnessRepository _repository;
  late Future<FitnessDashboardData?> _dashboardFuture;
  String? _seedLocale;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = AppLocalizations.of(context)!.localeName;
    if (_seedLocale != locale) {
      _seedLocale = locale;
      _repository.ensureCommonExercises(locale.startsWith('zh')).catchError((
        Object error,
      ) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saveFailed(error)),
            ),
          );
        }
      });
    }
  }

  Future<void> _extras(bool cardio) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            FitnessExtrasPage(repository: _repository, cardio: cardio),
      ),
    );
    if (mounted) _reload();
  }

  Widget _extraButtons() {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        children: [
          OutlinedButton.icon(
            onPressed: () => _extras(false),
            icon: const Icon(Icons.show_chart),
            label: Text(l.prTitle),
          ),
          OutlinedButton.icon(
            onPressed: () => _extras(true),
            icon: const Icon(Icons.directions_run),
            label: Text(l.cardioTitle),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _repository = FitnessRepository(widget.database);
    _dashboardFuture = _repository.loadDashboard();
  }

  void _reload() {
    final dashboardFuture = _repository.loadDashboard();
    setState(() {
      _dashboardFuture = dashboardFuture;
    });
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
          final l10n = AppLocalizations.of(context)!;
          return Column(
            children: [
              _extraButtons(),
              Expanded(
                child: _TemplatePicker(
                  title: l10n.selectTrainingCycle,
                  intro: l10n.templateIntro,
                  onSelected: (template) async {
                    await _repository.activateTemplate(
                      template,
                      planName: _templateName(template, l10n),
                      dayNames: [
                        for (final day in template.days)
                          _templateDayName(day.name, l10n),
                      ],
                    );
                    _reload();
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            _extraButtons(),
            Expanded(
              child: _FitnessDashboard(
                dashboard: dashboard,
                repository: _repository,
                onEditPlan: _editPlan,
                onSwitchPlan: _switchPlan,
                onShowHistory: _showHistory,
                onStartWorkout: () => _startWorkout(dashboard),
                onRest: _takeRest,
                onSkip: _skipTraining,
                onUndo: _undoTodayAction,
                onRedo: _redoTodayAction,
                onChooseStart: () => _chooseStart(dashboard),
                onRestart: _restartTraining,
                onUsePrevious: () =>
                    _startWorkout(dashboard, usePrevious: true),
                onEditTodayWorkout: (workout) =>
                    _editTodayWorkout(dashboard, workout),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPlan() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlanEditorPage(repository: _repository),
      ),
    );
    _reload();
  }

  Future<void> _chooseStart(FitnessDashboardData dashboard) async {
    final l = AppLocalizations.of(context)!;
    final dayId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l.chooseStartingDay),
              subtitle: Text(l.chooseStartingDayHint),
            ),
            for (final day in dashboard.planDays)
              ListTile(
                leading: Icon(
                  day.dayType == 'rest'
                      ? Icons.hotel_outlined
                      : Icons.fitness_center,
                ),
                title: Text(day.name),
                selected: day.id == dashboard.progress.nextDay?.id,
                onTap: () => Navigator.pop(c, day.id),
              ),
          ],
        ),
      ),
    );
    if (dayId == null || !mounted) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.chooseStartingDay),
        content: Text(l.chooseStartingDayHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _repository.chooseCycleStart(dayId);
      if (mounted) _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.startingDayUnavailable)));
      }
    }
  }

  Future<void> _restartTraining() async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.restartTraining),
        scrollable: true,
        content: Text(l.restartTrainingHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.restartTraining),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await _repository.restartTrainingCycle();
      if (mounted) _reload();
    } on FitnessDayActionLockedException {
      if (mounted) _showActionLockedMessage();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
  }

  Future<void> _redoTodayAction() async {
    final l = AppLocalizations.of(context)!;
    try {
      final restored = await _repository.redoLatestFitnessActionToday();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restored ? l.todayActionRestored : l.redoUnavailable),
        ),
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
  }

  Future<void> _showHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutHistoryPage(repository: _repository),
      ),
    );
  }

  Future<void> _switchPlan() async {
    final switched = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _SwitchPlanPage(repository: _repository),
      ),
    );
    if (switched == true) _reload();
  }

  Future<void> _startWorkout(
    FitnessDashboardData dashboard, {
    bool usePrevious = false,
  }) async {
    if (dashboard.hasActionToday) {
      _showActionLockedMessage();
      return;
    }
    final day = dashboard.progress.nextDay!;
    final planDay = dashboard.planDays.firstWhere((item) => item.id == day.id);
    final planned = await _repository.loadPlanExercises([planDay]);
    final previous = await _repository.previousSessionForDay(
      planDayId: day.id,
      beforeCycleNumber: dashboard.cycle.cycleNumber,
    );
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorPage(
          repository: _repository,
          dashboard: dashboard,
          plannedExercises: planned[day.id] ?? const [],
          previousWorkout: previous,
          usePreviousOnOpen: usePrevious,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _takeRest() async {
    final l10n = AppLocalizations.of(context)!;
    late final CycleExecutionType type;
    try {
      type = await _repository.takeRest();
    } on FitnessDayActionLockedException {
      if (mounted) _showActionLockedMessage();
      _reload();
      return;
    }
    if (!mounted) return;
    final message = switch (type) {
      CycleExecutionType.plannedRest => l10n.plannedRestDone,
      CycleExecutionType.movedRest => l10n.movedRestTaken,
      CycleExecutionType.extraRest => l10n.extraRestTaken,
      _ => l10n.restRecorded,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _reload();
  }

  Future<void> _skipTraining() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.skipConfirmTitle),
        content: Text(AppLocalizations.of(context)!.skipConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.confirmSkip),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.skipCurrentTraining();
    } on FitnessDayActionLockedException {
      if (!mounted) return;
      _showActionLockedMessage();
      _reload();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.trainingSkipped)),
    );
    _reload();
  }

  Future<void> _undoTodayAction() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final undone = await _repository.undoLatestFitnessActionToday();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            undone ? l10n.todayActionUndone : l10n.noTodayActionToUndo,
          ),
        ),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.undoActionFailed('$error'))));
    }
  }

  Future<void> _editTodayWorkout(
    FitnessDashboardData dashboard,
    WorkoutHistoryItem workout,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorPage(
          repository: _repository,
          dashboard: dashboard,
          existingWorkout: workout,
        ),
      ),
    );
    if (saved == true) _reload();
  }

  void _showActionLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.todayActionLocked)),
    );
  }
}

class _TemplatePicker extends StatefulWidget {
  const _TemplatePicker({
    required this.title,
    required this.intro,
    required this.onSelected,
  });

  final String title;
  final String intro;
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
        Text(widget.title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(widget.intro),
        const SizedBox(height: 24),
        for (final template in builtInTrainingPlanTemplates) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _templateName(template, AppLocalizations.of(context)!),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _templateDescription(
                      template,
                      AppLocalizations.of(context)!,
                    ),
                  ),
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
                          label: Text(
                            _templateDayName(
                              day.name,
                              AppLocalizations.of(context)!,
                            ),
                          ),
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
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .createPlanError(error),
                                  ),
                                ),
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
                        : Text(AppLocalizations.of(context)!.useTemplate),
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

class _SwitchPlanPage extends StatefulWidget {
  const _SwitchPlanPage({required this.repository});

  final FitnessRepository repository;

  @override
  State<_SwitchPlanPage> createState() => _SwitchPlanPageState();
}

class _SwitchPlanPageState extends State<_SwitchPlanPage> {
  Future<void> _selectTemplate(TrainingPlanTemplate template) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.switchPlanConfirmTitle(_templateName(template, l10n))),
        content: Text(l10n.switchPlanConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirmSwitch),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await widget.repository.activateTemplate(
      template,
      planName: _templateName(template, l10n),
      dayNames: [
        for (final day in template.days) _templateDayName(day.name, l10n),
      ],
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.switchPlan)),
      body: _TemplatePicker(
        title: l10n.chooseDifferentPlan,
        intro: l10n.switchPlanIntro,
        onSelected: _selectTemplate,
      ),
    );
  }
}

class _FitnessDashboard extends StatelessWidget {
  const _FitnessDashboard({
    required this.dashboard,
    required this.repository,
    required this.onEditPlan,
    required this.onSwitchPlan,
    required this.onShowHistory,
    required this.onStartWorkout,
    required this.onRest,
    required this.onSkip,
    required this.onUndo,
    required this.onRedo,
    required this.onChooseStart,
    required this.onRestart,
    required this.onUsePrevious,
    required this.onEditTodayWorkout,
  });

  final FitnessDashboardData dashboard;
  final FitnessRepository repository;
  final VoidCallback onEditPlan;
  final VoidCallback onSwitchPlan;
  final VoidCallback onShowHistory;
  final VoidCallback onStartWorkout;
  final Future<void> Function() onRest;
  final Future<void> Function() onSkip;
  final Future<void> Function() onUndo;
  final Future<void> Function() onRedo;
  final VoidCallback onChooseStart;
  final VoidCallback onRestart, onUsePrevious;
  final ValueChanged<WorkoutHistoryItem> onEditTodayWorkout;

  @override
  Widget build(BuildContext context) {
    final nextDay = dashboard.progress.nextDay!;
    final consumedIds = dashboard.progress.consumedDayIds;
    final cycleColor = Color(dashboard.cycle.colorValue);
    final actionLocked = dashboard.hasActionToday;

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
                  Text(
                    AppLocalizations.of(context)!
                        .cycleNumber(dashboard.cycle.cycleNumber),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEditPlan();
                if (value == 'switch') onSwitchPlan();
                if (value == 'history') onShowHistory();
                if (value == 'restart') onRestart();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'restart',
                  child: Text(AppLocalizations.of(context)!.restartTraining),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text(AppLocalizations.of(context)!.editPlan),
                ),
                PopupMenuItem(
                  value: 'switch',
                  child: Text(AppLocalizations.of(context)!.switchPlan),
                ),
                PopupMenuItem(
                  value: 'history',
                  child: Text(AppLocalizations.of(context)!.workoutHistory),
                ),
              ],
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
        if (dashboard.canChooseStart) ...[
          OutlinedButton.icon(
            onPressed: onChooseStart,
            icon: const Icon(Icons.start),
            label: Text(AppLocalizations.of(context)!.chooseStartingDay),
          ),
          const SizedBox(height: 12),
        ],
        if (dashboard.canRedo) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppLocalizations.of(context)!.redoTodayHint),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRedo,
                    icon: const Icon(Icons.redo),
                    label: Text(AppLocalizations.of(context)!.redoTodayAction),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (dashboard.hasDraft) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: Text(AppLocalizations.of(context)!.continueWorkoutDraft),
              subtitle: Text(AppLocalizations.of(context)!.workoutDraftHint),
              onTap: dashboard.todayWorkout == null
                  ? (actionLocked ? null : onStartWorkout)
                  : () => onEditTodayWorkout(dashboard.todayWorkout!),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (dashboard.todayWorkout case final workout?) ...[
          _TodayWorkoutCard(
            workout: workout,
            onEdit: () => onEditTodayWorkout(workout),
          ),
          const SizedBox(height: 12),
        ],
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppLocalizations.of(context)!.current,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  nextDay.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 18),
                if (nextDay.type == CycleDayType.training) ...[
                  FilledButton.icon(
                    onPressed: actionLocked ? null : onStartWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppLocalizations.of(context)!.startWorkout),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: actionLocked ? null : onRest,
                    icon: const Icon(Icons.hotel_outlined),
                    label: Text(AppLocalizations.of(context)!.takeRest),
                  ),
                  TextButton(
                    onPressed: actionLocked ? null : onSkip,
                    child: Text(AppLocalizations.of(context)!.skipTrainingDay),
                  ),
                ] else
                  FilledButton.icon(
                    onPressed: actionLocked ? null : onRest,
                    icon: const Icon(Icons.hotel_outlined),
                    label: Text(AppLocalizations.of(context)!.completeRestDay),
                  ),
              ],
            ),
          ),
        ),
        if (actionLocked) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline),
                    title: Text(
                      AppLocalizations.of(context)!.todayActionLocked,
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.undoToChangeAction,
                    ),
                    trailing: TextButton.icon(
                      onPressed: onUndo,
                      icon: const Icon(Icons.undo),
                      label: Text(AppLocalizations.of(context)!.undo),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (nextDay.type == CycleDayType.training &&
            dashboard.cycle.cycleNumber > 1)
          FutureBuilder<WorkoutHistoryItem?>(
            future: repository.previousSessionForDay(
              planDayId: nextDay.id,
              beforeCycleNumber: dashboard.cycle.cycleNumber,
            ),
            builder: (context, snapshot) {
              final previous = snapshot.data;
              if (previous == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(
                          AppLocalizations.of(context)!.previousRoundSameDay,
                        ),
                        subtitle: Text(_previousSummary(previous)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutHistoryDetailPage(item: previous),
                          ),
                        ),
                      ),
                      if (!actionLocked)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: OutlinedButton.icon(
                            onPressed: onUsePrevious,
                            icon: const Icon(Icons.copy_outlined),
                            label: Text(
                              AppLocalizations.of(context)!.usePreviousTemplate,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context)!.cycleProgress,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (dashboard.unrecordedDayIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(AppLocalizations.of(context)!.beforeStartingDay),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final day in dashboard.planDays)
              Chip(
                avatar: Icon(
                  dashboard.unrecordedDayIds.contains(day.id)
                      ? Icons.remove_circle_outline
                      : consumedIds.contains(day.id)
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

  String _previousSummary(WorkoutHistoryItem item) {
    final values = <String>[];
    for (final exercise in item.exercises) {
      double? best;
      for (final set in exercise.sets.where((set) => set.isCompleted)) {
        final weight = set.weightValue;
        if (weight != null && (best == null || weight > best)) best = weight;
      }
      values.add(
        '${exercise.exercise.exerciseNameSnapshot}: ${best == null ? '—' : '$best kg'}',
      );
    }
    return 'Cycle ${item.cycleNumber ?? '—'} · ${values.join('  •  ')}';
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  const _TodayWorkoutCard({required this.workout, required this.onEdit});

  final WorkoutHistoryItem workout;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = workout.session;
    final details = <String>[
      if (session.planNameSnapshot?.isNotEmpty == true)
        session.planNameSnapshot!,
      if (workout.cycleNumber != null) l10n.cycleNumber(workout.cycleNumber!),
    ];

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.todayWorkout,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        [
                          session.dayNameSnapshot ?? l10n.workout,
                          ...details,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.editTodayWorkout,
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const Divider(height: 20),
            for (var index = 0; index < workout.exercises.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              Text(
                workout.exercises[index].exercise.exerciseNameSnapshot,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              for (final set in workout.exercises[index].sets)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    l10n.setLine(
                      set.setNumber,
                      set.weightText ?? _formatWorkoutValue(set.weightValue),
                      set.weightText == null ? set.weightUnit : '',
                      set.reps ?? '—',
                      _formatWorkoutValue(set.rir),
                      set.isCompleted ? '' : l10n.skippedSuffix,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatWorkoutValue(double? value) {
  if (value == null) return '—';
  return formatNumber(value);
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
            Text(AppLocalizations.of(context)!.readWorkoutError),
            const SizedBox(height: 4),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
