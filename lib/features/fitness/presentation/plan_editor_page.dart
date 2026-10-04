import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../data/fitness_repository.dart';
import '../domain/training_cycle.dart';
import '../../../l10n/app_localizations.dart';

class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({super.key, required this.repository});

  final FitnessRepository repository;

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late Future<_PlanEditorData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_PlanEditorData> _load() async {
    final dashboard = await widget.repository.loadDashboard();
    if (dashboard == null) throw StateError('No active plan');
    return _PlanEditorData(
      dashboard,
      await widget.repository.loadPlanExercises(dashboard.planDays),
    );
  }

  void _reload() {
    final dataFuture = _load();
    setState(() {
      _dataFuture = dataFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.editPlan)),
      body: FutureBuilder<_PlanEditorData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!
                    .planLoadError('${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _editor(snapshot.data!);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDay,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addDay),
      ),
    );
  }

  Widget _editor(_PlanEditorData data) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(data.dashboard.plan.name),
            subtitle: Text(AppLocalizations.of(context)!.planName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editPlanName(data.dashboard.plan.name),
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < data.dashboard.planDays.length; index++)
          _dayCard(data, index),
      ],
    );
  }

  Widget _dayCard(_PlanEditorData data, int index) {
    final day = data.dashboard.planDays[index];
    final exercises = data.exercisesByDay[day.id] ?? const <PlanExerciseData>[];
    final isRest = day.dayType == CycleDayType.rest.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(isRest ? Icons.hotel_outlined : Icons.fitness_center),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    day.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.editDay,
                  onPressed: () => _editDayName(day),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.moveUp,
                  onPressed: index == 0
                      ? null
                      : () => _moveDay(data.dashboard.planDays, index, -1),
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.moveDown,
                  onPressed: index == data.dashboard.planDays.length - 1
                      ? null
                      : () => _moveDay(data.dashboard.planDays, index, 1),
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.removeDay,
                  onPressed: () => _removeDay(day),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (!isRest) ...[
              if (exercises.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppLocalizations.of(context)!.noExercisesAssigned,
                  ),
                ),
              for (final item in exercises)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.exercise.name),
                  subtitle: Text(_targetLabel(item.planExercise)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _editTargets(item.planExercise);
                      if (action == 'remove') {
                        _removeExercise(item.planExercise);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(AppLocalizations.of(context)!.editTargets),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(AppLocalizations.of(context)!.remove),
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => _addExercise(day.id),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addExercise),
              ),
            ] else
              Padding(
                padding: EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(AppLocalizations.of(context)!.restSlotDescription),
              ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(PlanDayExercise exercise) {
    final sets = exercise.targetSets?.toString() ?? '—';
    final min = exercise.targetRepsMin?.toString() ?? '—';
    final max = exercise.targetRepsMax?.toString() ?? min;
    final weight = exercise.targetWeight == null
        ? ''
        : ' · ${exercise.targetWeight!.toStringAsFixed(exercise.targetWeight! % 1 == 0 ? 0 : 1)} kg';
    return '$sets sets · $min–$max reps$weight';
  }

  Future<void> _editPlanName(String currentName) async {
    final name = await _textDialog(
      title: AppLocalizations.of(context)!.planName,
      initial: currentName,
    );
    if (name == null || !mounted) return;
    await widget.repository.renameActivePlan(name);
    _reload();
  }

  Future<void> _editDayName(PlanDay day) async {
    final name = await _textDialog(
      title: AppLocalizations.of(context)!.trainingDayName,
      initial: day.name,
    );
    if (name == null || !mounted) return;
    await widget.repository.updatePlanDayName(day.id, name);
    _reload();
  }

  Future<String?> _textDialog({
    required String title,
    required String initial,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _TextEntryDialog(title: title, initial: initial),
    );
  }

  Future<void> _moveDay(List<PlanDay> days, int index, int offset) async {
    final ids = days.map((day) => day.id).toList();
    final target = index + offset;
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await widget.repository.reorderPlanDays(ids);
    _reload();
  }

  Future<void> _addDay() async {
    final name = await _textDialog(
      title: AppLocalizations.of(context)!.newDayName,
      initial: AppLocalizations.of(context)!.newDay,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final type = await showDialog<CycleDayType>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.dayType),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, CycleDayType.training),
            child: ListTile(
              leading: const Icon(Icons.fitness_center),
              title: Text(AppLocalizations.of(context)!.trainingDay),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, CycleDayType.rest),
            child: ListTile(
              leading: const Icon(Icons.hotel_outlined),
              title: Text(AppLocalizations.of(context)!.plannedRest),
            ),
          ),
        ],
      ),
    );
    if (type == null || !mounted) return;
    await widget.repository.addPlanDay(name: name, type: type);
    _reload();
  }

  Future<void> _removeDay(PlanDay day) async {
    final removed = await widget.repository.removePlanDay(day.id);
    if (!mounted) return;
    if (!removed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.historyLockedDay)),
      );
      return;
    }
    _reload();
  }

  Future<void> _addExercise(String dayId) async {
    final presets = await widget.repository.listExercises();
    if (!mounted) return;
    final selection = await showModalBottomSheet<Exercise?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)!.choosePresetExercise),
            ),
            for (final exercise in presets)
              ListTile(
                title: Text(exercise.name),
                leading: const Icon(Icons.fitness_center),
                onTap: () => Navigator.pop(context, exercise),
              ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.createExercisePreset),
              leading: const Icon(Icons.add),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    String? exerciseId = selection?.id;
    if (selection == null) {
      final name = await _textDialog(
        title: AppLocalizations.of(context)!.newExercisePreset,
        initial: '',
      );
      if (name == null || name.isEmpty || !mounted) return;
      exerciseId = await widget.repository.createExercisePreset(name);
    }
    if (exerciseId == null || !mounted) return;
    final target = await _targetDialog();
    if (target == null) return;
    await widget.repository.addPlanExercise(
      planDayId: dayId,
      exerciseId: exerciseId,
      targetSets: target.sets,
      targetRepsMin: target.repsMin,
      targetRepsMax: target.repsMax,
      targetWeight: target.weight,
    );
    _reload();
  }

  Future<void> _editTargets(PlanDayExercise exercise) async {
    final target = await _targetDialog(exercise: exercise);
    if (target == null) return;
    await widget.repository.updatePlanExerciseTargets(
      id: exercise.id,
      targetSets: target.sets,
      targetRepsMin: target.repsMin,
      targetRepsMax: target.repsMax,
      targetWeight: target.weight,
    );
    _reload();
  }

  Future<_ExerciseTarget?> _targetDialog({PlanDayExercise? exercise}) async {
    return showDialog<_ExerciseTarget>(
      context: context,
      builder: (context) => _TargetsDialog(exercise: exercise),
    );
  }

  Future<void> _removeExercise(PlanDayExercise exercise) async {
    await widget.repository.removePlanExercise(exercise.id);
    _reload();
  }
}

class _PlanEditorData {
  const _PlanEditorData(this.dashboard, this.exercisesByDay);
  final FitnessDashboardData dashboard;
  final Map<String, List<PlanExerciseData>> exercisesByDay;
}

class _ExerciseTarget {
  const _ExerciseTarget(this.sets, this.repsMin, this.repsMax, this.weight);
  final int sets;
  final int repsMin;
  final int repsMax;
  final double? weight;
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(controller: _controller, autofocus: true),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(AppLocalizations.of(context)!.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: Text(AppLocalizations.of(context)!.save),
      ),
    ],
  );
}

class _TargetsDialog extends StatefulWidget {
  const _TargetsDialog({this.exercise});
  final PlanDayExercise? exercise;

  @override
  State<_TargetsDialog> createState() => _TargetsDialogState();
}

class _TargetsDialogState extends State<_TargetsDialog> {
  late final TextEditingController _sets = TextEditingController(
    text: '${widget.exercise?.targetSets ?? 3}',
  );
  late final TextEditingController _min = TextEditingController(
    text: '${widget.exercise?.targetRepsMin ?? 8}',
  );
  late final TextEditingController _max = TextEditingController(
    text: '${widget.exercise?.targetRepsMax ?? 12}',
  );
  late final TextEditingController _weight = TextEditingController(
    text: widget.exercise?.targetWeight?.toString() ?? '',
  );

  @override
  void dispose() {
    _sets.dispose();
    _min.dispose();
    _max.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.exercise == null ? l10n.exerciseTargets : l10n.editTargets,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TargetField(label: l10n.targetSets, controller: _sets),
          _TargetField(label: l10n.minReps, controller: _min),
          _TargetField(label: l10n.maxReps, controller: _max),
          _TargetField(
            label: l10n.suggestedWeight,
            controller: _weight,
            decimal: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final setCount = int.tryParse(_sets.text);
            final min = int.tryParse(_min.text);
            final max = int.tryParse(_max.text);
            final load = _weight.text.trim().isEmpty
                ? null
                : double.tryParse(_weight.text);
            if (setCount == null ||
                setCount < 1 ||
                min == null ||
                min < 0 ||
                max == null ||
                max < min ||
                (_weight.text.trim().isNotEmpty && load == null)) {
              return;
            }
            Navigator.pop(context, _ExerciseTarget(setCount, min, max, load));
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _TargetField extends StatelessWidget {
  const _TargetField({
    required this.label,
    required this.controller,
    this.decimal = false,
  });
  final String label;
  final TextEditingController controller;
  final bool decimal;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label, isDense: true),
    ),
  );
}
