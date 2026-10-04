import 'package:flutter/material.dart';

import '../data/fitness_repository.dart';
import '../../../l10n/app_localizations.dart';

class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({
    super.key,
    required this.repository,
    required this.dashboard,
    this.existingWorkout,
    this.plannedExercises = const [],
  });

  final FitnessRepository repository;
  final FitnessDashboardData dashboard;
  final WorkoutHistoryItem? existingWorkout;
  final List<PlanExerciseData> plannedExercises;

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  final List<_ExerciseInput> _exercises = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingWorkout case final workout?) {
      for (final exercise in workout.exercises) {
        _exercises.add(_ExerciseInput.fromHistory(exercise));
      }
    } else {
      for (final planned in widget.plannedExercises) {
        _exercises.add(_ExerciseInput.fromPlan(planned));
      }
    }
  }

  @override
  void dispose() {
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayName =
        widget.existingWorkout?.session.dayNameSnapshot ??
        widget.dashboard.progress.nextDay!.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingWorkout == null ? dayName : l10n.editWorkout,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.dashboard.plan.name} · ${l10n.cycleNumber(widget.dashboard.cycle.cycleNumber)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_exercises.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.fitness_center, size: 38),
                    const SizedBox(height: 12),
                    Text(l10n.addFirstExercise),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addExercise),
                    ),
                  ],
                ),
              ),
            )
          else
            for (var index = 0; index < _exercises.length; index++) ...[
              _ExerciseCard(
                index: index,
                input: _exercises[index],
                onAddSet: () {
                  setState(() => _exercises[index].sets.add(_SetInput()));
                },
                onRemoveSet: (setIndex) {
                  setState(() {
                    final removed = _exercises[index].sets.removeAt(setIndex);
                    removed.dispose();
                  });
                },
                onRemoveExercise: () {
                  setState(() {
                    final removed = _exercises.removeAt(index);
                    removed.dispose();
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          if (_exercises.isNotEmpty) ...[
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: Text(l10n.addExercise),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _saveWorkout,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(
                widget.existingWorkout == null
                    ? l10n.finishSaveWorkout
                    : l10n.saveWorkoutChanges,
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _addExercise() async {
    final l10n = AppLocalizations.of(context)!;
    final existing = await widget.repository.listExercises();
    if (!mounted) return;

    _ExerciseSelection? selection;
    if (existing.isNotEmpty) {
      selection = await showModalBottomSheet<_ExerciseSelection>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(l10n.chooseExercise)),
              for (final exercise in existing)
                ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(exercise.name),
                  onTap: () => Navigator.pop(
                    context,
                    _ExerciseSelection(exercise.name, true),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(l10n.enterNewExercise),
                onTap: () =>
                    Navigator.pop(context, const _ExerciseSelection('', true)),
              ),
            ],
          ),
        ),
      );
      if (selection == null) return;
    }

    if (selection == null || selection.name.isEmpty) {
      selection = await _askForNewExercise();
    }
    if (selection == null || !mounted) return;

    setState(() => _exercises.add(_ExerciseInput(selection!)));
  }

  Future<_ExerciseSelection?> _askForNewExercise() async {
    return showDialog<_ExerciseSelection>(
      context: context,
      builder: (context) => const _NewExerciseDialog(),
    );
  }

  Future<void> _saveWorkout() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final drafts = <WorkoutDraftExercise>[];
      for (final exercise in _exercises) {
        if (exercise.name.trim().isEmpty) {
          throw FormatException(l10n.emptyExerciseName);
        }
        if (exercise.sets.isEmpty) {
          throw FormatException(l10n.atLeastOneSet(exercise.name));
        }

        final sets = <WorkoutDraftSet>[];
        for (final input in exercise.sets) {
          final weight = double.tryParse(input.weight.text);
          final reps = int.tryParse(input.reps.text);
          final rir = double.tryParse(input.rir.text);
          if (weight == null || weight < 0) {
            throw FormatException(l10n.invalidWeight(exercise.name));
          }
          if (reps == null || reps < 0) {
            throw FormatException(l10n.invalidReps(exercise.name));
          }
          if (rir == null || rir < 0 || rir > 10 || (rir * 2) % 1 != 0) {
            throw FormatException(l10n.invalidRir(exercise.name));
          }
          sets.add(WorkoutDraftSet(weight: weight, reps: reps, rir: rir));
        }
        drafts.add(
          WorkoutDraftExercise(
            name: exercise.name,
            saveAsPreset: exercise.saveAsPreset,
            sets: sets,
          ),
        );
      }

      setState(() => _saving = true);
      final existingWorkout = widget.existingWorkout;
      if (existingWorkout == null) {
        await widget.repository.completeWorkout(widget.dashboard, drafts);
      } else {
        await widget.repository.updateWorkoutSession(
          existingWorkout.session.id,
          drafts,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } on FitnessDayActionLockedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.todayActionLocked)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.saveFailed(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.index,
    required this.input,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
  });

  final int index;
  final _ExerciseInput input;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onRemoveExercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    input.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.remove,
                  onPressed: onRemoveExercise,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (!input.saveAsPreset)
              Text(l10n.workingCopyOnly, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 32, child: Text(l10n.setLabel)),
                Expanded(child: Text('kg')),
                SizedBox(width: 8),
                Expanded(child: Text(l10n.repsLabel)),
                SizedBox(width: 8),
                Expanded(child: Text(l10n.rirLabel)),
                SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 6),
            for (var setIndex = 0; setIndex < input.sets.length; setIndex++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: Text('${setIndex + 1}')),
                    Expanded(
                      child: _NumberField(
                        controller: input.sets[setIndex].weight,
                        decimal: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumberField(
                        controller: input.sets[setIndex].reps,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumberField(
                        controller: input.sets[setIndex].rir,
                        decimal: true,
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        tooltip: l10n.removeSet,
                        onPressed: input.sets.length > 1
                            ? () => onRemoveSet(setIndex)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add),
              label: Text(l10n.addAnotherSet),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, this.decimal = false});

  final TextEditingController controller;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _ExerciseSelection {
  const _ExerciseSelection(this.name, this.saveAsPreset);

  final String name;
  final bool saveAsPreset;
}

class _NewExerciseDialog extends StatefulWidget {
  const _NewExerciseDialog();

  @override
  State<_NewExerciseDialog> createState() => _NewExerciseDialogState();
}

class _NewExerciseDialogState extends State<_NewExerciseDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.enterNewExercise),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.exerciseName,
          hintText: l10n.exerciseHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => _submit(saveAsPreset: false),
          child: Text(l10n.oneTimeOnly),
        ),
        FilledButton(
          onPressed: () => _submit(saveAsPreset: true),
          child: Text(l10n.saveAsPreset),
        ),
      ],
    );
  }

  void _submit({required bool saveAsPreset}) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, _ExerciseSelection(name, saveAsPreset));
  }
}

class _ExerciseInput {
  _ExerciseInput(_ExerciseSelection selection)
    : name = selection.name,
      saveAsPreset = selection.saveAsPreset,
      sets = [_SetInput()];

  _ExerciseInput.fromPlan(PlanExerciseData data)
    : name = data.exercise.name,
      saveAsPreset = true,
      sets = [
        for (
          var index = 0;
          index < (data.planExercise.targetSets ?? 3);
          index++
        )
          _SetInput(
            weightValue: data.planExercise.targetWeight,
            repsValue: data.planExercise.targetRepsMin,
            rirValue: 2,
          ),
      ];

  _ExerciseInput.fromHistory(WorkoutHistoryExercise data)
    : name = data.exercise.exerciseNameSnapshot,
      saveAsPreset = data.exercise.exerciseId != null,
      sets = [
        for (final set in data.sets)
          _SetInput(
            weightValue: set.weightValue,
            repsValue: set.reps,
            rirValue: set.rir,
          ),
      ];

  final String name;
  final bool saveAsPreset;
  final List<_SetInput> sets;

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetInput {
  _SetInput({double? weightValue, int? repsValue, double? rirValue})
    : weight = TextEditingController(text: weightValue?.toString() ?? ''),
      reps = TextEditingController(text: repsValue?.toString() ?? ''),
      rir = TextEditingController(text: rirValue?.toString() ?? '');

  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController rir;

  void dispose() {
    weight.dispose();
    reps.dispose();
    rir.dispose();
  }
}
