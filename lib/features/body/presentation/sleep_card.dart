import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/number_format.dart';
import '../../../core/record_day.dart';
import '../../../l10n/app_localizations.dart';
import '../data/sleep_repository.dart';

class SleepCard extends StatefulWidget {
  const SleepCard({super.key, required this.database, required this.date});
  final AppDatabase database;
  final DateTime date;
  @override
  State<SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<SleepCard> {
  late final _repository = SleepRepository(widget.database);
  late Future<SleepLog?> _future = _repository.load(widget.date);
  bool _busy = false;
  void _reload() {
    if (mounted) setState(() => _future = _repository.load(widget.date));
  }

  @override
  void didUpdateWidget(covariant SleepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _future = _repository.load(widget.date);
  }

  Future<void> _edit(SleepLog? log) async {
    final result = await showDialog<(DateTime, DateTime, String)>(
      context: context,
      builder: (_) => _SleepDialog(date: widget.date, log: log),
    );
    if (result == null) return;
    setState(() => _busy = true);
    try {
      await _repository.save(widget.date, result.$1, result.$2, result.$3);
      _reload();
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<SleepLog?>(
          future: _future,
          builder: (context, snapshot) {
            final log = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.sleep,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: l.sleep,
                      onPressed:
                          _busy ||
                              snapshot.connectionState != ConnectionState.done
                          ? null
                          : () => _edit(log),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
                if (snapshot.hasError) Text(l.saveFailed(snapshot.error!)),
                if (log != null) ...[
                  Text(
                    '${DateFormat.Md(l.localeName).add_Hm().format(log.startedAt)} → ${DateFormat.Md(l.localeName).add_Hm().format(log.endedAt)} · ${formatNumber(log.endedAt.difference(log.startedAt).inMinutes / 60)} h',
                  ),
                  if (log.notes?.isNotEmpty == true) Text(log.notes!),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('${l.delete} · ${l.sleep}'),
                                content: Text(RecordDay.key(widget.date)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: Text(l.cancel),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: Text(l.delete),
                                  ),
                                ],
                              ),
                            );
                            if (yes == true) {
                              await _repository.delete(widget.date);
                              _reload();
                            }
                          },
                    child: Text(l.delete),
                  ),
                ] else
                  const Text('—'),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SleepDialog extends StatefulWidget {
  const _SleepDialog({required this.date, this.log});
  final DateTime date;
  final SleepLog? log;
  @override
  State<_SleepDialog> createState() => _SleepDialogState();
}

class _SleepDialogState extends State<_SleepDialog> {
  late DateTime _start =
      widget.log?.startedAt ??
      DateTime(widget.date.year, widget.date.month, widget.date.day - 1, 23);
  late DateTime _end =
      widget.log?.endedAt ??
      DateTime(widget.date.year, widget.date.month, widget.date.day, 7);
  late final _notes = TextEditingController(text: widget.log?.notes ?? '');
  bool _invalid = false;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final value = start ? _start : _end;
    final day = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _start = result;
      } else {
        _end = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text('${l.sleep} · ${RecordDay.key(widget.date)}'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l.sleepStart),
            subtitle: Text(
              DateFormat.yMd(l.localeName).add_Hm().format(_start),
            ),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: Text(l.sleepEnd),
            subtitle: Text(DateFormat.yMd(l.localeName).add_Hm().format(_end)),
            onTap: () => _pick(false),
          ),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: InputDecoration(labelText: l.sleepNotes),
          ),
          if (_invalid)
            Text(
              l.sleepInvalid,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () {
            final minutes = _end.difference(_start).inMinutes;
            if (minutes <= 0 || minutes > 2880) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, (_start, _end, _notes.text));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}
