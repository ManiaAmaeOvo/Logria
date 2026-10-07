import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/database/app_database.dart';
import '../../../core/record_day.dart';
import '../../../core/record_day_watcher.dart';
import '../../../l10n/app_localizations.dart';
import '../data/body_repository.dart';

class BodyPage extends StatefulWidget {
  const BodyPage({super.key, required this.database});
  final AppDatabase database;
  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  late final _repository = BodyRepository(widget.database);
  DateTime _date = RecordDay.today();
  late final RecordDayWatcher _dayWatcher;
  late Future<BodyDayData> _future = _repository.loadDay(_date);
  String? _typeId;
  int _range = 90;

  @override
  void initState() {
    super.initState();
    _dayWatcher = RecordDayWatcher((previous, current) {
      if (mounted) _reload(_date == previous ? current : _date);
    });
  }

  @override
  void dispose() {
    _dayWatcher.dispose();
    super.dispose();
  }

  void _reload([DateTime? date]) {
    setState(() {
      if (date != null) _date = DateUtils.dateOnly(date);
      _future = _repository.loadDay(_date);
    });
  }

  Future<void> _edit(BodyDayData day, {BodyMeasurementType? type}) async {
    final date = _date;
    final values = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) => _BodyEditor(
        types: type == null ? day.types : [type],
        measurements: day.measurements,
      ),
    );
    if (values == null) return;
    try {
      await _repository.saveDay(date, values);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveFailed('$error')),
          ),
        );
      }
    }
  }

  Future<void> _delete(BodyMeasurement measurement) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteMeasurement),
        content: Text(l.deleteMeasurementHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteMeasurement(measurement.id);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FutureBuilder<BodyDayData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.bodyLoadError('${snapshot.error}')),
                TextButton(onPressed: _reload, child: Text(l.retry)),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final day = snapshot.data!;
        final type = day.types.firstWhere(
          (t) => t.id == _typeId,
          orElse: () => day.types.first,
        );
        final cutoff = _range == 0
            ? DateTime(2000)
            : DateTime(_date.year, _date.month, _date.day - _range + 1);
        final history = day.history
            .where(
              (m) =>
                  m.measurementTypeId == type.id &&
                  !DateTime.parse(m.localDate).isBefore(cutoff),
            )
            .toList();
        final latest = day.history
            .where((m) => m.measurementTypeId == type.id)
            .lastOrNull;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: l.previousDay,
                  onPressed: () =>
                      _reload(DateTime(_date.year, _date.month, _date.day - 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      DateFormat.yMMMMEEEEd(l.localeName).format(_date),
                      textAlign: TextAlign.center,
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: RecordDay.today(),
                      );
                      if (date != null && mounted) _reload(date);
                    },
                  ),
                ),
                IconButton(
                  tooltip: l.nextDay,
                  onPressed: _date.isBefore(RecordDay.today())
                      ? () => _reload(
                          DateTime(_date.year, _date.month, _date.day + 1),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.bodyMeasurements,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: l.recordMeasurements,
                          onPressed: () => _edit(day),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    Text(
                      l.bodyOptionalHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final t in day.types.where(
                          (t) => !day.measurements.containsKey(t.id),
                        ))
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 16),
                            label: Text(_name(t, l)),
                            onPressed: () => _edit(day, type: t),
                          ),
                      ],
                    ),
                    for (final t in day.types.where(
                      (t) => day.measurements.containsKey(t.id),
                    ))
                      Builder(
                        builder: (context) {
                          final m = day.measurements[t.id]!;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(_name(t, l)),
                            subtitle: Text('${_number(m.value)} ${m.unit}'),
                            onTap: () => _edit(day, type: t),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _edit(day, type: t);
                                if (value == 'delete') _delete(m);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l.edit),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l.delete),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.bodyTrend,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type.id,
                      decoration: InputDecoration(labelText: l.measurementType),
                      items: [
                        for (final t in day.types)
                          DropdownMenuItem(
                            value: t.id,
                            child: Text(_name(t, l)),
                          ),
                      ],
                      onChanged: (value) => setState(() => _typeId = value),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 30, label: Text(l.last30Days)),
                        ButtonSegment(value: 90, label: Text(l.last90Days)),
                        ButtonSegment(value: 0, label: Text(l.allHistory)),
                      ],
                      selected: {_range},
                      onSelectionChanged: (values) =>
                          setState(() => _range = values.single),
                    ),
                    const SizedBox(height: 16),
                    if (latest != null)
                      Text(
                        '${l.latestMeasurement}: ${_number(latest.value)} ${latest.unit} · ${DateFormat.yMd(l.localeName).format(DateTime.parse(latest.localDate))}',
                      ),
                    const SizedBox(height: 12),
                    if (history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l.noBodyHistory),
                      )
                    else ...[
                      Text(
                        type.defaultUnit,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      Semantics(
                        label:
                            '${_name(type, l)}: ${history.map((m) => '${m.localDate} ${_number(m.value)} ${m.unit}').join(', ')}',
                        child: SizedBox(
                          height: 180,
                          child: CustomPaint(
                            painter: _TrendPainter(
                              history,
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.outlineVariant,
                              Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat.yMd(
                              l.localeName,
                            ).format(DateTime.parse(history.first.localDate)),
                          ),
                          if (history.length > 1)
                            Text(
                              DateFormat.yMd(
                                l.localeName,
                              ).format(DateTime.parse(history.last.localDate)),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      for (final m in history.reversed)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${_number(m.value)} ${m.unit}'),
                          subtitle: Text(
                            DateFormat.yMMMMd(l.localeName)
                                .format(DateTime.parse(m.localDate)),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _reload(DateTime.parse(m.localDate)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BodyEditor extends StatefulWidget {
  const _BodyEditor({required this.types, required this.measurements});
  final List<BodyMeasurementType> types;
  final Map<String, BodyMeasurement> measurements;
  @override
  State<_BodyEditor> createState() => _BodyEditorState();
}

class _BodyEditorState extends State<_BodyEditor> {
  final _form = GlobalKey<FormState>();
  late final _controllers = {
    for (final t in widget.types)
      t.id: TextEditingController(
        text: widget.measurements[t.id] == null
            ? ''
            : _number(widget.measurements[t.id]!.value),
      ),
  };
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.recordMeasurements),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.bodyOptionalHint),
              const SizedBox(height: 16),
              for (final t in widget.types)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers[t.id],
                    decoration: InputDecoration(
                      labelText: _name(t, l),
                      suffixText: t.defaultUnit,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (text) {
                      if (text == null || text.trim().isEmpty) return null;
                      final value = double.tryParse(
                        text.trim().replaceAll(',', '.'),
                      );
                      return value == null ||
                              !value.isFinite ||
                              value <= 0 ||
                              (t.keyName == 'body_fat' && value > 100)
                          ? l.invalidBodyValue
                          : null;
                    },
                  ),
                ),
            ],
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
            if (!_form.currentState!.validate()) return;
            final values = {
              for (final entry in _controllers.entries)
                if (entry.value.text.trim().isNotEmpty)
                  entry.key: double.parse(
                    entry.value.text.trim().replaceAll(',', '.'),
                  ),
            };
            if (values.isEmpty) {
              Navigator.pop(context);
              return;
            }
            Navigator.pop(context, values);
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

String _name(BodyMeasurementType type, AppLocalizations l) =>
    switch (type.keyName) {
      'weight' => l.bodyWeight,
      'height' => l.bodyHeight,
      'body_fat' => l.bodyFat,
      'waist' => l.bodyWaist,
      'arm' => l.bodyArm,
      'chest' => l.bodyChest,
      'hip' => l.bodyHip,
      'thigh' => l.bodyThigh,
      _ => type.displayName,
    };
String _number(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.color, this.grid, this.textColor);
  final List<BodyMeasurement> points;
  final Color color, grid, textColor;
  @override
  void paint(Canvas canvas, Size size) {
    final minValue = points.map((m) => m.value).reduce(math.min);
    final maxValue = points.map((m) => m.value).reduce(math.max);
    final margin = math.max(
      (maxValue - minValue) * .15,
      math.max(maxValue * .01, .1),
    );
    final bottom = minValue - margin, top = maxValue + margin;
    final start = DateTime.parse(points.first.localDate).millisecondsSinceEpoch;
    final end = DateTime.parse(points.last.localDate).millisecondsSinceEpoch;
    final width = size.width - 64, height = size.height - 16;
    for (var i = 0; i < 3; i++) {
      final y = 8 + height * i / 2;
      canvas.drawLine(
        Offset(52, y),
        Offset(size.width - 12, y),
        Paint()..color = grid,
      );
      final label = TextPainter(
        text: TextSpan(
          text: _number(top - (top - bottom) * i / 2),
          style: TextStyle(fontSize: 11, color: textColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 48);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final coordinates = points
        .map(
          (m) => Offset(
            52 +
                (end == start
                    ? width / 2
                    : (DateTime.parse(m.localDate).millisecondsSinceEpoch -
                              start) /
                          (end - start) *
                          width),
            8 + (top - m.value) / (top - bottom) * height,
          ),
        )
        .toList();
    final path = Path()..moveTo(coordinates.first.dx, coordinates.first.dy);
    for (final p in coordinates.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final p in coordinates) {
      canvas.drawCircle(p, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.points != points ||
      old.color != color ||
      old.grid != grid ||
      old.textColor != textColor;
}
