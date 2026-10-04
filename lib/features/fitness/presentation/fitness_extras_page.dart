import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/fitness_repository.dart';

class FitnessExtrasPage extends StatefulWidget {
  const FitnessExtrasPage({
    super.key,
    required this.repository,
    required this.cardio,
  });
  final FitnessRepository repository;
  final bool cardio;
  @override
  State<FitnessExtrasPage> createState() => _FitnessExtrasPageState();
}

class _FitnessExtrasPageState extends State<FitnessExtrasPage> {
  late Future<void> _load;
  List<CardioLog> _cardio = [];
  List<String> _tracked = [];
  String? _selected;
  List<PrPoint> _points = [];
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load = _refresh();
  }

  Future<void> _refresh() async {
    if (widget.cardio) {
      _cardio = await widget.repository.cardioHistory();
    } else {
      _tracked = await widget.repository.trackedExercises();
      if (!_tracked.contains(_selected)) _selected = _tracked.firstOrNull;
      _points = _selected == null
          ? []
          : await widget.repository.prHistory(_selected!);
    }
  }

  void _reload() {
    setState(() => _load = _refresh());
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed(error)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.cardio ? l.cardioTitle : l.prTitle)),
      body: FutureBuilder<void>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(l.saveFailed(snapshot.error!)));
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(widget.cardio ? l.cardioHint : l.prExplanation),
              const SizedBox(height: 16),
              if (widget.cardio) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () => _editCardio(),
                  icon: const Icon(Icons.add),
                  label: Text(l.addCardio),
                ),
                for (final c in _cardio)
                  Card(
                    child: ListTile(
                      title: Text(c.activity),
                      subtitle: Text(
                        '${c.localDate} · ${c.minutes} min${c.distanceKm == null ? '' : ' · ${c.distanceKm} km'}${c.notes?.isNotEmpty == true ? '\n${c.notes}' : ''}',
                      ),
                      onTap: _busy ? null : () => _editCardio(c),
                      trailing: IconButton(
                        tooltip: l.remove,
                        onPressed: _busy
                            ? null
                            : () => _delete(
                                () => widget.repository.deleteCardio(c.id),
                              ),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : _chooseExercise,
                  icon: const Icon(Icons.add),
                  label: Text(l.trackExercise),
                ),
                if (_tracked.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selected,
                    key: ValueKey(_selected),
                    isExpanded: true,
                    items: _tracked
                        .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: _busy
                        ? null
                        : (value) {
                            _selected = value;
                            _reload();
                          },
                  ),
                  const SizedBox(height: 16),
                  if (_points.isEmpty)
                    Text(l.noPr)
                  else ...[
                    Text(
                      'PR: ${_points.map((p) => p.weight).reduce(math.max)} kg',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: _points
                          .map((p) => '${p.date}: ${p.weight} kg')
                          .join(', '),
                      child: SizedBox(
                        height: 190,
                        child: CustomPaint(
                          painter: _PrPainter(
                            _points,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 16,
                      children: [
                        Text(_points.first.date),
                        Text(_points.last.date),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _addPr,
                    icon: const Icon(Icons.add),
                    label: Text(l.addPr),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _mutate(
                            () => widget.repository.trackExercise(
                              _selected!,
                              false,
                            ),
                          ),
                    child: Text(l.removeTracking),
                  ),
                  for (final p in _points.reversed)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${p.weight} kg${p.reps == null ? '' : ' × ${p.reps}'}',
                        ),
                        subtitle: Text(
                          '${p.date} · ${p.id == null ? l.workoutPr : l.manualPr}',
                        ),
                        trailing: p.id == null
                            ? null
                            : IconButton(
                                tooltip: l.remove,
                                onPressed: _busy
                                    ? null
                                    : () => _delete(
                                        () => widget.repository.deletePr(p.id!),
                                      ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                      ),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(Future<void> Function() action) async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.remove),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (yes == true) await _mutate(action);
  }

  Future<void> _chooseExercise() async {
    final l = AppLocalizations.of(context)!;
    await widget.repository.ensureCommonExercises(
      l.localeName.startsWith('zh'),
    );
    final presets = await widget.repository.listExercises();
    final history = await widget.repository.listWorkoutHistory(limit: 10000);
    final names = {
      ...presets.map((e) => e.name),
      ...history.expand(
        (w) => w.exercises.map((e) => e.exercise.exerciseNameSnapshot),
      ),
    }.toList()..sort();
    if (!mounted) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(l.trackExercise)),
            for (final name in names)
              CheckboxListTile(
                value: _tracked.contains(name),
                title: Text(name),
                onChanged: (_) => Navigator.pop(c, name),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _mutate(
      () => widget.repository.trackExercise(picked, !_tracked.contains(picked)),
    );
  }

  Future<void> _addPr() async {
    final result = await showDialog<_EntryResult>(
      context: context,
      builder: (_) => _EntryDialog(cardio: false, name: _selected!),
    );
    if (result == null) return;
    await _mutate(
      () => widget.repository.addPr(
        _selected!,
        result.date,
        result.value,
        result.reps,
      ),
    );
  }

  Future<void> _editCardio([CardioLog? existing]) async {
    final result = await showDialog<_EntryResult>(
      context: context,
      builder: (_) => _EntryDialog(cardio: true, existing: existing),
    );
    if (result == null) return;
    await _mutate(
      () => widget.repository.saveCardio(
        id: existing?.id,
        date: result.date,
        activity: result.name,
        minutes: result.value,
        distance: result.distance,
        notes: result.notes,
      ),
    );
  }
}

class _EntryResult {
  const _EntryResult(
    this.date,
    this.name,
    this.value,
    this.distance,
    this.notes,
    this.reps,
  );
  final DateTime date;
  final String name, notes;
  final double value;
  final double? distance;
  final int? reps;
}

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.cardio, this.existing, this.name});
  final bool cardio;
  final CardioLog? existing;
  final String? name;
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.existing?.activity ?? widget.name ?? '',
  );
  late final _value = TextEditingController(
    text: widget.existing?.minutes.toString() ?? '',
  );
  late final _distance = TextEditingController(
    text: widget.existing?.distanceKm?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  final _reps = TextEditingController();
  late DateTime _date = widget.existing == null
      ? DateTime.now()
      : DateTime.parse(widget.existing!.localDate);
  @override
  void dispose() {
    for (final c in [_name, _value, _distance, _notes, _reps]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _number(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.cardio ? l.cardioTitle : l.addPr),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${l.dateLabel}: ${DateFormat('yyyy-MM-dd').format(_date)}',
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now(),
                    );
                    if (date != null && mounted) setState(() => _date = date);
                  },
                ),
                if (widget.cardio) ...[
                  Wrap(
                    spacing: 4,
                    children: l.cardioPresets
                        .split(',')
                        .map(
                          (n) => ActionChip(
                            label: Text(n),
                            onPressed: () => _name.text = n,
                          ),
                        )
                        .toList(),
                  ),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l.cardioActivity),
                    validator: (v) =>
                        v!.trim().isEmpty ? l.invalidFitnessValue : null,
                  ),
                ] else
                  Text(widget.name!),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.cardio ? l.cardioMinutes : 'kg',
                  ),
                  validator: (v) {
                    final number = _number(v!);
                    return number == null ||
                            !number.isFinite ||
                            number < 0 ||
                            (widget.cardio && number == 0)
                        ? l.invalidFitnessValue
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                if (widget.cardio) ...[
                  TextFormField(
                    controller: _distance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: l.cardioDistance),
                    validator: (v) {
                      if (v!.trim().isEmpty) return null;
                      final n = _number(v);
                      return n == null || !n.isFinite || n < 0
                          ? l.invalidFitnessValue
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: l.cardioNotes),
                  ),
                ] else
                  TextFormField(
                    controller: _reps,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l.repsLabel),
                    validator: (v) {
                      if (v!.trim().isEmpty) return null;
                      final n = int.tryParse(v);
                      return n == null || n < 0 ? l.invalidFitnessValue : null;
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(
                context,
                _EntryResult(
                  _date,
                  _name.text.trim(),
                  _number(_value.text)!,
                  _number(_distance.text),
                  _notes.text.trim(),
                  int.tryParse(_reps.text),
                ),
              );
            }
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

class _PrPainter extends CustomPainter {
  _PrPainter(this.points, this.color);
  final List<PrPoint> points;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    // Combine manual and workout entries only for the curve; the log retains each source.
    final daily = <String, double>{};
    for (final p in points) {
      daily[p.date] = math.max(daily[p.date] ?? p.weight, p.weight);
    }
    final entries = daily.entries.toList();
    final low = entries.map((e) => e.value).reduce(math.min);
    final high = entries.map((e) => e.value).reduce(math.max);
    final padding = math.max((high - low) * .15, 1.0);
    final first = DateTime.parse(entries.first.key).millisecondsSinceEpoch;
    final last = DateTime.parse(entries.last.key).millisecondsSinceEpoch;
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final y = 12 + (size.height - 24) * i / 2;
      canvas.drawLine(
        Offset(48, y),
        Offset(size.width - 8, y),
        Paint()..color = color.withValues(alpha: .15),
      );
      final label = TextPainter(
        text: TextSpan(
          text: (high + padding - (high - low + 2 * padding) * i / 2)
              .toStringAsFixed(1),
          style: TextStyle(color: color, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 44);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final x =
          48 +
          (size.width - 56) *
              (first == last
                  ? .5
                  : (DateTime.parse(e.key).millisecondsSinceEpoch - first) /
                        (last - first));
      final y =
          12 +
          (size.height - 24) *
              (high + padding - e.value) /
              (high - low + 2 * padding);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PrPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
