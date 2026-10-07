import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/fitness_repository.dart';
import '../domain/exercise_variant.dart';
import 'exercise_variant_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/record_day.dart';

class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({
    super.key,
    required this.repository,
    required this.dashboard,
    this.existingWorkout,
    this.plannedExercises = const [],
    this.previousWorkout,
    this.usePreviousOnOpen = false,
    this.recordDate,
    this.onSave,
  });

  final FitnessRepository repository;
  final FitnessDashboardData dashboard;
  final WorkoutHistoryItem? existingWorkout;
  final List<PlanExerciseData> plannedExercises;
  final WorkoutHistoryItem? previousWorkout;
  final bool usePreviousOnOpen;
  final DateTime? recordDate;
  final Future<void> Function(List<WorkoutDraftExercise>)? onSave;

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage>
    with WidgetsBindingObserver {
  final List<_ExerciseInput> _exercises = [];
  bool _saving = false;
  bool _loading = true;
  bool _canPop = false;
  bool _finished = false;
  bool _committing = false;
  Timer? _debounce;
  Future<void> _writes = Future.value();
  late final DateTime _recordDate = RecordDay.dateOnly(
    widget.recordDate ?? widget.repository.recordingDate,
  );
  late final String _draftKey =
      'fitness.draft.${RecordDay.key(_recordDate)}.${widget.onSave == null ? '' : '${widget.dashboard.cycle.id}.'}${widget.existingWorkout?.session.id ?? widget.dashboard.progress.nextDay!.id}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.existingWorkout case final workout?) {
      for (final exercise in workout.exercises) {
        _exercises.add(_ExerciseInput.fromHistory(exercise));
      }
    } else {
      for (final planned in widget.plannedExercises) {
        _exercises.add(_ExerciseInput.fromPlan(planned));
      }
    }
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    try {
      final raw = await widget.repository.readSetting(_draftKey);
      if (!mounted) return;
      if (raw != null) {
        final restored = (jsonDecode(raw) as List)
            .map((e) => _ExerciseInput.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        for (final e in _exercises) {
          e.dispose();
        }
        _exercises
          ..clear()
          ..addAll(restored);
      }
      for (final e in _exercises) {
        _listen(e);
      }
      setState(() => _loading = false);
      if (widget.usePreviousOnOpen && widget.previousWorkout != null) {
        await _usePrevious(confirm: raw != null);
      }
    } catch (error) {
      if (!mounted) return;
      for (final e in _exercises) {
        _listen(e);
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.saveFailed(error)),
        ),
      );
    }
  }

  void _listen(_ExerciseInput input) {
    for (final set in input.sets) {
      for (final c in [set.weight, set.reps, set.rir]) {
        c.addListener(_changed);
      }
      set.weightFocus.addListener(() {
        if (!set.weightFocus.hasFocus) {
          input.finishFirstEdit(weight: true);
          _changed();
        }
      });
      set.repsFocus.addListener(() {
        if (!set.repsFocus.hasFocus) {
          input.finishFirstEdit(weight: false);
          _changed();
        }
      });
    }
  }

  Future<void> _usePrevious({bool confirm = true}) async {
    if (_saving || _loading || widget.previousWorkout == null) return;
    final l = AppLocalizations.of(context)!;
    if (confirm) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l.usePreviousTemplate),
          content: Text(l.replaceWorkoutTemplateHint),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l.usePreviousTemplate),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final old = List<_ExerciseInput>.of(_exercises);
    final replacements = widget.previousWorkout!.exercises
        .map((e) => _ExerciseInput.fromHistory(e, asTemplate: true))
        .toList();
    for (final e in replacements) {
      _listen(e);
    }
    setState(() {
      _exercises
        ..clear()
        ..addAll(replacements);
    });
    // Let old TextFields detach before disposing their controllers/focus nodes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final e in old) {
        e.dispose();
      }
    });
    try {
      await _persistDraft();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
  }

  void _changed() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _persistDraft().catchError((Object error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.saveFailed(error)),
            ),
          );
        }
      });
    });
  }

  Future<void> _persistDraft() {
    _debounce?.cancel();
    if (_finished || _loading || _committing) return _writes;
    final raw = jsonEncode(_exercises.map((e) => e.toJson()).toList());
    _writes = _writes
        .catchError((Object _) {})
        .then((_) => widget.repository.writeSetting(_draftKey, raw));
    return _writes;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _persistDraft().catchError((Object _) {});
    }
  }

  Future<void> _exit() async {
    if (_saving || _loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = true);
    try {
      await _persistDraft();
      if (!mounted) return;
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed(error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _discardDraft() async {
    if (_saving || _loading) return;
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.discardWorkoutDraft),
        content: Text(l.discardWorkoutDraftHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.discardWorkoutDraft),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    _committing = true;
    _debounce?.cancel();
    try {
      await _writes.catchError((Object _) {});
      await widget.repository.clearSetting(_draftKey);
      _finished = true;
      if (!mounted) return;
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    } finally {
      _committing = false;
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayName =
        (widget.onSave == null
            ? widget.existingWorkout?.session.dayNameSnapshot
            : null) ??
        widget.dashboard.progress.nextDay!.name;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              tooltip: l10n.discardWorkoutDraft,
              onPressed: _saving || _loading ? null : _discardDraft,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
          leading: IconButton(
            onPressed: _saving || _loading ? null : _exit,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            '${widget.existingWorkout == null ? dayName : l10n.editWorkout}\n${RecordDay.key(_recordDate)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : AbsorbPointer(
                absorbing: _saving,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${widget.dashboard.plan.name} · ${l10n.cycleNumber(widget.dashboard.cycle.cycleNumber)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.workoutDraftHint),
                    if (widget.existingWorkout == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.firstSetFillHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (widget.existingWorkout == null &&
                        widget.previousWorkout != null)
                      OutlinedButton.icon(
                        onPressed: () => _usePrevious(),
                        icon: const Icon(Icons.copy_outlined),
                        label: Text(l10n.usePreviousTemplate),
                      ),
                    const SizedBox(height: 12),
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
                      for (
                        var index = 0;
                        index < _exercises.length;
                        index++
                      ) ...[
                        _ExerciseCard(
                          key: ObjectKey(_exercises[index]),
                          index: index,
                          input: _exercises[index],
                          onVariant: () => _editVariant(_exercises[index]),
                          onAddSet: () {
                            final set = _SetInput();
                            for (final c in [set.weight, set.reps, set.rir]) {
                              c.addListener(_changed);
                            }
                            setState(() => _exercises[index].sets.add(set));
                            _changed();
                          },
                          onRemoveSet: (setIndex) {
                            setState(() {
                              if (setIndex == 0) {
                                _exercises[index].weightFilled = true;
                                _exercises[index].repsFilled = true;
                              }
                              final removed = _exercises[index].sets.removeAt(
                                setIndex,
                              );
                              removed.dispose();
                            });
                            _changed();
                          },
                          onRemoveExercise: () {
                            setState(() {
                              final removed = _exercises.removeAt(index);
                              removed.dispose();
                            });
                            _changed();
                          },
                          onWeightModeChanged: () {
                            setState(() {});
                            _changed();
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
              ),
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
                    _ExerciseSelection(
                      exercise.name,
                      true,
                      baseName: exerciseVariant(
                        exercise.name,
                        exercise.notes,
                      ).base,
                      note: exerciseVariant(exercise.name, exercise.notes).note,
                    ),
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

    final input = _ExerciseInput(selection);
    _listen(input);
    setState(() => _exercises.add(input));
    _changed();
  }

  Future<_ExerciseSelection?> _askForNewExercise() async {
    return showDialog<_ExerciseSelection>(
      context: context,
      builder: (context) => const _NewExerciseDialog(),
    );
  }

  Future<void> _editVariant(_ExerciseInput input) async {
    final l = AppLocalizations.of(context)!;
    final note = await showDialog<String>(
      context: context,
      builder: (_) => ExerciseVariantDialog(initial: input.variantNote ?? ''),
    );
    if (note == null || !mounted) return;
    try {
      if (note.isNotEmpty) {
        await widget.repository.createExerciseVariant(input.baseName, note);
      }
      setState(() {
        input.variantNote = note.isEmpty ? null : note;
        input.name = note.isEmpty
            ? input.baseName
            : variantExerciseName(input.baseName, note);
        input.saveAsPreset = true;
      });
      _changed();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
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
          final rawWeight = input.weight.text.trim();
          final parsedWeight = double.tryParse(rawWeight.replaceAll(',', '.'));
          final weight =
              parsedWeight ??
              (rawWeight.isNotEmpty && input.textAsZero ? 0.0 : null);
          final reps = int.tryParse(input.reps.text.trim());
          final rir = double.tryParse(
            input.rir.text.trim().replaceAll(',', '.'),
          );
          if (parsedWeight != null &&
              (!parsedWeight.isFinite || parsedWeight < 0)) {
            throw FormatException(l10n.invalidWeight(exercise.name));
          }
          if (input.reps.text.trim().isNotEmpty && (reps == null || reps < 0)) {
            throw FormatException(l10n.invalidReps(exercise.name));
          }
          if (input.rir.text.trim().isNotEmpty &&
              (rir == null ||
                  !rir.isFinite ||
                  rir < 0 ||
                  rir > 10 ||
                  (rir * 2) % 1 != 0)) {
            throw FormatException(l10n.invalidRir(exercise.name));
          }
          if (rawWeight.isEmpty && reps == null && rir == null) continue;
          sets.add(
            WorkoutDraftSet(
              weight: weight,
              weightText: parsedWeight == null && rawWeight.isNotEmpty
                  ? rawWeight
                  : null,
              reps: reps,
              rir: rir,
            ),
          );
        }
        if (sets.isEmpty) continue;
        drafts.add(
          WorkoutDraftExercise(
            name: exercise.name,
            saveAsPreset: exercise.saveAsPreset,
            sets: sets,
            baseName: exercise.baseName,
            variantNote: exercise.variantNote,
          ),
        );
      }

      if (drafts.isEmpty) throw FormatException(l10n.addFirstExercise);

      setState(() => _saving = true);
      await _persistDraft();
      _committing = true;
      final existingWorkout = widget.existingWorkout;
      await widget.repository.database.transaction(() async {
        if (widget.onSave != null) {
          await widget.onSave!(drafts);
        } else if (existingWorkout == null) {
          await widget.repository.completeWorkout(
            widget.dashboard,
            drafts,
            recordDate: _recordDate,
          );
        } else {
          await widget.repository.updateWorkoutSession(
            existingWorkout.session.id,
            drafts,
          );
        }
        await widget.repository.clearSetting(_draftKey);
      });
      _finished = true;
      _debounce?.cancel();
      if (!mounted) return;
      setState(() => _canPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
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
      _committing = false;
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.index,
    required this.input,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onRemoveExercise,
    required this.onWeightModeChanged,
    required this.onVariant,
  });

  final int index;
  final _ExerciseInput input;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final VoidCallback onRemoveExercise;
  final VoidCallback onWeightModeChanged;
  final VoidCallback onVariant;

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
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onVariant,
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.exerciseVariantNote),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(width: 32, child: Text(l10n.setLabel)),
                Expanded(child: Text(l10n.weightInputLabel)),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 32, child: Text('${setIndex + 1}')),
                        Expanded(
                          child: _NumberField(
                            controller: input.sets[setIndex].weight,
                            decimal: true,
                            allowText: true,
                            focusNode: input.sets[setIndex].weightFocus,
                            onChanged: (_) =>
                                input.edit(setIndex, weight: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _NumberField(
                            controller: input.sets[setIndex].reps,
                            focusNode: input.sets[setIndex].repsFocus,
                            onChanged: (_) =>
                                input.edit(setIndex, weight: false),
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
                    StatefulBuilder(
                      builder: (context, refresh) =>
                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: input.sets[setIndex].weight,
                            builder: (context, value, _) {
                              if (value.text.trim().isEmpty ||
                                  double.tryParse(
                                        value.text.trim().replaceAll(',', '.'),
                                      ) !=
                                      null) {
                                return const SizedBox.shrink();
                              }
                              return DropdownButtonFormField<bool>(
                                key: ValueKey(input.sets[setIndex].textAsZero),
                                isExpanded: true,
                                itemHeight: null,
                                isDense: false,
                                initialValue: input.sets[setIndex].textAsZero,
                                decoration: InputDecoration(
                                  labelText: l10n.textWeightHandling,
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: false,
                                    child: Text(
                                      l10n.textWeightNull,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: true,
                                    child: Text(
                                      l10n.textWeightZero,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  refresh(
                                    () => input.sets[setIndex].textAsZero =
                                        v ?? false,
                                  );
                                  input.edit(
                                    setIndex,
                                    weight: true,
                                    modeOnly: true,
                                  );
                                  onWeightModeChanged();
                                },
                              );
                            },
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
  const _NumberField({
    required this.controller,
    this.decimal = false,
    this.allowText = false,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool decimal;
  final bool allowText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: allowText
          ? TextInputType.text
          : TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _ExerciseSelection {
  const _ExerciseSelection(
    this.name,
    this.saveAsPreset, {
    this.baseName,
    this.note,
  });

  final String name;
  final bool saveAsPreset;
  final String? baseName, note;
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
      baseName = selection.baseName ?? selection.name,
      variantNote = selection.note,
      saveAsPreset = selection.saveAsPreset,
      sets = [_SetInput()];

  _ExerciseInput.fromPlan(PlanExerciseData data)
    : name = data.exercise.name,
      baseName = exerciseVariant(data.exercise.name, data.exercise.notes).base,
      variantNote = exerciseVariant(
        data.exercise.name,
        data.exercise.notes,
      ).note,
      saveAsPreset = true,
      sets = [
        for (
          var index = 0;
          index < (data.planExercise.targetSets ?? 3);
          index++
        )
          _SetInput(),
      ];

  _ExerciseInput.fromHistory(
    WorkoutHistoryExercise data, {
    bool asTemplate = false,
  }) : name = data.exercise.exerciseNameSnapshot,
       baseName =
           data.exercise.notes != null &&
               data.exercise.exerciseNameSnapshot.endsWith(
                 ' [${data.exercise.notes}]',
               )
           ? data.exercise.exerciseNameSnapshot.substring(
               0,
               data.exercise.exerciseNameSnapshot.length -
                   data.exercise.notes!.length -
                   3,
             )
           : data.exercise.exerciseNameSnapshot,
       variantNote =
           data.exercise.notes != null &&
               data.exercise.exerciseNameSnapshot.endsWith(
                 ' [${data.exercise.notes}]',
               )
           ? data.exercise.notes
           : null,
       saveAsPreset = data.exercise.exerciseId != null,
       sets = [
         for (final set in data.sets)
           _SetInput(
             weightValue: set.weightValue,
             repsValue: set.reps,
             rirValue: set.rir,
             weightText: set.weightText,
             textAsZero: set.weightText != null && set.weightValue == 0,
           ),
       ] {
    weightFilled = !asTemplate;
    repsFilled = !asTemplate;
    weightModeFilled = !asTemplate;
  }

  String name;
  final String baseName;
  String? variantNote;
  bool saveAsPreset;
  final List<_SetInput> sets;
  bool weightFilled = false, repsFilled = false;
  bool weightModeFilled = false;
  bool _weightEditing = false, _repsEditing = false;

  void finishFirstEdit({required bool weight}) {
    if (weight && _weightEditing) {
      weightFilled = true;
      _weightEditing = false;
    }
    if (!weight && _repsEditing) {
      repsFilled = true;
      _repsEditing = false;
    }
  }

  void edit(int index, {required bool weight, bool modeOnly = false}) {
    final source = sets[index];
    if (index != 0) {
      if (weight) {
        source.weightEdited = true;
      } else {
        source.repsEdited = true;
      }
      return;
    }
    if (modeOnly) {
      if (weightModeFilled) return;
      weightModeFilled = true;
      for (final target in sets.skip(1)) {
        if (!target.weightEdited && target.weight.text == source.weight.text) {
          target.textAsZero = source.textAsZero;
        }
      }
      return;
    }
    if (weight ? weightFilled : repsFilled) return;
    if (weight) {
      _weightEditing = true;
    } else {
      _repsEditing = true;
    }
    for (final target in sets.skip(1)) {
      if (weight && !target.weightEdited) {
        target.weight.text = source.weight.text;
        target.textAsZero = source.textAsZero;
      } else if (!weight && !target.repsEdited) {
        target.reps.text = source.reps.text;
      }
    }
  }

  _ExerciseInput.fromJson(Map<String, dynamic> json)
    : name = json['name'] as String,
      baseName = json['baseName'] as String? ?? json['name'] as String,
      variantNote = json['variantNote'] as String?,
      saveAsPreset = json['preset'] as bool,
      sets = (json['sets'] as List)
          .map((s) => _SetInput.fromJson(Map<String, dynamic>.from(s)))
          .toList() {
    // Legacy drafts with recorded values must not unexpectedly overwrite them.
    weightFilled =
        json['weightFilled'] as bool? ??
        sets.any((s) => s.weight.text.isNotEmpty);
    repsFilled =
        json['repsFilled'] as bool? ?? sets.any((s) => s.reps.text.isNotEmpty);
    weightModeFilled = json['weightModeFilled'] as bool? ?? weightFilled;
  }
  Map<String, dynamic> toJson() => {
    'name': name,
    'baseName': baseName,
    'variantNote': variantNote,
    'preset': saveAsPreset,
    'sets': sets.map((s) => s.toJson()).toList(),
    'weightFilled': weightFilled || _weightEditing,
    'repsFilled': repsFilled || _repsEditing,
    'weightModeFilled': weightModeFilled,
  };

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _SetInput {
  _SetInput({
    double? weightValue,
    int? repsValue,
    double? rirValue,
    String? weightText,
    this.textAsZero = false,
  }) : weight = TextEditingController(
         text: weightText ?? weightValue?.toString() ?? '',
       ),
       reps = TextEditingController(text: repsValue?.toString() ?? ''),
       rir = TextEditingController(text: rirValue?.toString() ?? '');

  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController rir;
  bool textAsZero;
  final weightFocus = FocusNode();
  final repsFocus = FocusNode();
  bool weightEdited = false, repsEdited = false;
  _SetInput.fromJson(Map<String, dynamic> json)
    : weight = TextEditingController(text: json['weight'] as String),
      reps = TextEditingController(text: json['reps'] as String),
      rir = TextEditingController(text: json['rir'] as String),
      textAsZero = json['zero'] as bool {
    weightEdited = json['weightEdited'] as bool? ?? weight.text.isNotEmpty;
    repsEdited = json['repsEdited'] as bool? ?? reps.text.isNotEmpty;
  }
  Map<String, dynamic> toJson() => {
    'weight': weight.text,
    'reps': reps.text,
    'rir': rir.text,
    'zero': textAsZero,
    'weightEdited': weightEdited,
    'repsEdited': repsEdited,
  };

  void dispose() {
    weight.dispose();
    reps.dispose();
    rir.dispose();
    weightFocus.dispose();
    repsFocus.dispose();
  }
}
