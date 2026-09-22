import 'package:flutter/material.dart';

import '../data/fitness_repository.dart';

class WorkoutEditorPage extends StatefulWidget {
  const WorkoutEditorPage({
    super.key,
    required this.repository,
    required this.dashboard,
  });

  final FitnessRepository repository;
  final FitnessDashboardData dashboard;

  @override
  State<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends State<WorkoutEditorPage> {
  final List<_ExerciseInput> _exercises = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayName = widget.dashboard.progress.nextDay!.name;

    return Scaffold(
      appBar: AppBar(title: Text(dayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.dashboard.plan.name} · 第 ${widget.dashboard.cycle.cycleNumber} 轮',
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
                    const Text('添加今天的第一个动作'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _addExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('添加动作'),
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
              label: const Text('添加动作'),
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
              label: const Text('完成并保存训练'),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _addExercise() async {
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
              const ListTile(title: Text('选择动作')),
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
                title: const Text('输入新动作'),
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
    final controller = TextEditingController();
    final selection = await showDialog<_ExerciseSelection>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入新动作'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: '动作名称',
            hintText: '例如：平板卧推',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, _ExerciseSelection(name, false));
              }
            },
            child: const Text('仅本次'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, _ExerciseSelection(name, true));
              }
            },
            child: const Text('保存为预设'),
          ),
        ],
      ),
    );
    controller.dispose();
    return selection;
  }

  Future<void> _saveWorkout() async {
    try {
      final drafts = <WorkoutDraftExercise>[];
      for (final exercise in _exercises) {
        if (exercise.name.trim().isEmpty) {
          throw const FormatException('动作名称不能为空');
        }
        if (exercise.sets.isEmpty) {
          throw FormatException('${exercise.name} 至少需要一组');
        }

        final sets = <WorkoutDraftSet>[];
        for (final input in exercise.sets) {
          final weight = double.tryParse(input.weight.text);
          final reps = int.tryParse(input.reps.text);
          final rir = double.tryParse(input.rir.text);
          if (weight == null || weight < 0) {
            throw FormatException('${exercise.name} 的重量无效');
          }
          if (reps == null || reps < 0) {
            throw FormatException('${exercise.name} 的次数无效');
          }
          if (rir == null || rir < 0 || rir > 10 || (rir * 2) % 1 != 0) {
            throw FormatException('${exercise.name} 的 RIR 应为 0–10，步进 0.5');
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
      await widget.repository.completeWorkout(widget.dashboard, drafts);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('保存失败：$error')));
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
                  tooltip: '删除动作',
                  onPressed: onRemoveExercise,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (!input.saveAsPreset)
              const Text('仅保存在本次训练中', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(width: 32, child: Text('组')),
                Expanded(child: Text('kg')),
                SizedBox(width: 8),
                Expanded(child: Text('次数')),
                SizedBox(width: 8),
                Expanded(child: Text('RIR')),
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
                        tooltip: '删除此组',
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
              label: const Text('增加一组'),
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

class _ExerciseInput {
  _ExerciseInput(_ExerciseSelection selection)
    : name = selection.name,
      saveAsPreset = selection.saveAsPreset,
      sets = [_SetInput()];

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
  _SetInput()
    : weight = TextEditingController(),
      reps = TextEditingController(),
      rir = TextEditingController();

  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController rir;

  void dispose() {
    weight.dispose();
    reps.dispose();
    rir.dispose();
  }
}
