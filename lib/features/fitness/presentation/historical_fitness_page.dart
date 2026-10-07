import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../data/fitness_repository.dart';
import 'workout_editor_page.dart';

class HistoricalFitnessPage extends StatefulWidget {
  const HistoricalFitnessPage({
    super.key,
    required this.repository,
    required this.date,
  });
  final FitnessRepository repository;
  final DateTime date;
  @override
  State<HistoricalFitnessPage> createState() => _HistoricalFitnessPageState();
}

class _HistoricalFitnessPageState extends State<HistoricalFitnessPage> {
  late Future<HistoricalFitnessDay> _future = widget.repository
      .loadHistoricalDay(widget.date);
  HistoricalFitnessDay? _context;
  String _kind = 'rest';
  String? _cycleId, _dayId;
  Future<Set<String>>? _occupied;
  bool _saving = false;

  void _selectCycle(FitnessCycleChoice choice) {
    _cycleId = choice.cycle.id;
    _dayId = null;
    _occupied = widget.repository.occupiedHistoricalDays(
      choice.cycle.id,
      widget.date,
    );
  }

  Future<bool> _confirm() async {
    final l = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            scrollable: true,
            title: Text(l.editDateFitness),
            content: Text(l.replaceDateFitnessWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: Text(l.continueLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save(FitnessCycleChoice choice) async {
    if (_saving || !await _confirm() || !mounted) return;
    final revision = _context!.revision;
    setState(() => _saving = true);
    try {
      if (_kind == 'training') {
        final existing = _context!.workouts.firstOrNull;
        final planned =
            (await widget.repository.loadPlanExercises(choice.days))[_dayId!] ??
            const <PlanExerciseData>[];
        if (!mounted) return;
        final kind = _kind;
        final dayId = _dayId;
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutEditorPage(
              repository: widget.repository,
              dashboard: widget.repository.historicalDashboard(choice, dayId!),
              recordDate: widget.date,
              existingWorkout: existing,
              plannedExercises: planned,
              onSave: (exercises) => widget.repository.replaceHistoricalDay(
                date: widget.date,
                cycleId: choice.cycle.id,
                dayId: dayId,
                kind: kind,
                expectedRevision: revision,
                exercises: exercises,
              ),
            ),
          ),
        );
        if (result == true && mounted) Navigator.pop(context, true);
      } else {
        await widget.repository.replaceHistoricalDay(
          date: widget.date,
          cycleId: choice.cycle.id,
          dayId: _dayId,
          kind: _kind,
          expectedRevision: revision,
        );
        if (mounted) Navigator.pop(context, true);
      }
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.editDateFitness)),
      body: FutureBuilder<HistoricalFitnessDay>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _context = null;
                  _future = widget.repository.loadHistoricalDay(widget.date);
                }),
                child: Text(l.retry),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (_context == null) {
            _context = data;
            final action = data.executions.firstOrNull;
            _kind = data.workouts.isNotEmpty
                ? 'training'
                : action?.executionType == 'skippedTraining'
                ? 'skip'
                : 'rest';
            final preferred =
                data.workouts.firstOrNull?.session.cycleInstanceId ??
                action?.cycleInstanceId;
            final choice =
                data.choices
                    .where((c) => c.cycle.id == preferred)
                    .firstOrNull ??
                data.choices.firstOrNull;
            if (choice != null) {
              _selectCycle(choice);
              _dayId =
                  data.workouts.firstOrNull?.session.planDayId ??
                  action?.planDayId;
            }
          }
          final choice = data.choices
              .where((c) => c.cycle.id == _cycleId)
              .firstOrNull;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                DateFormat.yMMMMEEEEd(l.localeName).format(widget.date),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(l.recordDayHint),
              const SizedBox(height: 12),
              if (data.executions.isEmpty && data.workouts.isEmpty)
                Text(l.defaultRest),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (value, label) in [
                    ('training', l.historyTraining),
                    ('rest', l.historyRest),
                    ('skip', l.historySkip),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _kind == value,
                      onSelected: _saving
                          ? null
                          : (_) => setState(() {
                              _kind = value;
                              _dayId = null;
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (choice == null)
                Text(l.noPlanForHistory)
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _cycleId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.locateCycle),
                  items: [
                    for (final c in data.choices)
                      DropdownMenuItem(
                        value: c.cycle.id,
                        child: Text(
                          '${c.plan.name} · ${l.cycleNumber(c.cycle.cycleNumber)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (id) => setState(
                          () => _selectCycle(
                            data.choices.firstWhere((c) => c.cycle.id == id),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Set<String>>(
                  future: _occupied,
                  builder: (context, occupied) {
                    if (occupied.hasError) {
                      return Text(l.saveFailed(occupied.error!));
                    }
                    if (!occupied.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final days = choice.days
                        .where(
                          (d) =>
                              d.dayType ==
                              (_kind == 'rest' ? 'rest' : 'training'),
                        )
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('$_cycleId.$_kind.$_dayId'),
                          initialValue: _dayId ?? '',
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.planDayForDate,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(
                                _kind == 'rest'
                                    ? l.historyExtraRest
                                    : l.chooseHistoryDay,
                              ),
                            ),
                            for (final d in days)
                              DropdownMenuItem(
                                value: d.id,
                                enabled: !occupied.data!.contains(d.id),
                                child: Text(
                                  '${d.name}${occupied.data!.contains(d.id) ? ' · ${l.alreadyRecordedDay}' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (id) => setState(
                                  () => _dayId = id == '' ? null : id,
                                ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('save-historical-fitness'),
                          onPressed:
                              _saving ||
                                  (_kind != 'rest' && _dayId == null) ||
                                  occupied.data!.contains(_dayId)
                              ? null
                              : () => _save(choice),
                          icon: const Icon(Icons.edit_calendar),
                          label: Text(
                            _kind == 'training' ? l.editWorkout : l.save,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(l.historicalCompatibilityHint),
                      ],
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
