import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/number_format.dart';

import '../data/fitness_repository.dart';
import '../../../l10n/app_localizations.dart';

class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key, required this.repository});

  final FitnessRepository repository;

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  late Future<List<WorkoutHistoryItem>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.repository.listWorkoutHistory();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workoutHistory)),
      body: FutureBuilder<List<WorkoutHistoryItem>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l10n.historyLoadError(snapshot.error!)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final history = snapshot.data!;
          if (history.isEmpty) {
            return Center(child: Text(l10n.emptyHistory));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.fitness_center),
                  ),
                  title: Text(item.session.dayNameSnapshot ?? 'Workout'),
                  subtitle: Text(
                    '${DateFormat.yMMMd(l10n.localeName).format(item.session.startedAt)} · '
                    '${item.session.planNameSnapshot ?? l10n.freeWorkout}'
                    '${item.cycleNumber == null ? '' : ' · ${l10n.cycleNumber(item.cycleNumber!)}'}\n'
                    '${l10n.exerciseCount(item.exercises.length, _setCount(item))}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WorkoutHistoryDetailPage(item: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _setCount(WorkoutHistoryItem item) =>
      item.exercises.fold(0, (total, exercise) => total + exercise.sets.length);
}

class WorkoutHistoryDetailPage extends StatelessWidget {
  const WorkoutHistoryDetailPage({super.key, required this.item});

  final WorkoutHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = item.session;
    return Scaffold(
      appBar: AppBar(title: Text(session.dayNameSnapshot ?? l10n.workout)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            DateFormat.yMMMMEEEEd(l10n.localeName).format(session.startedAt),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${session.planNameSnapshot ?? l10n.freeWorkout}'
            '${item.cycleNumber == null ? '' : ' · ${l10n.cycleNumber(item.cycleNumber!)}'}',
          ),
          const SizedBox(height: 20),
          for (final exercise in item.exercises) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      exercise.exercise.exerciseNameSnapshot,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final set in exercise.sets)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          l10n.setLine(
                            set.setNumber,
                            set.weightText ?? _number(set.weightValue),
                            set.weightText == null ? set.weightUnit : '',
                            set.reps ?? '—',
                            _number(set.rir),
                            set.isCompleted ? '' : l10n.skippedSuffix,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (session.notes?.isNotEmpty == true)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(session.notes!),
              ),
            ),
        ],
      ),
    );
  }

  String _number(double? value) {
    if (value == null) return '—';
    return formatNumber(value);
  }
}
