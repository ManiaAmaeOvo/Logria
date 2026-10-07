import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/record_day.dart';
import '../../../core/record_day_watcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../fitness/data/fitness_repository.dart';
import '../../fitness/presentation/historical_fitness_page.dart';
import '../../today/data/today_repository.dart';
import '../../today/presentation/today_log_formatter.dart';
import '../data/calendar_repository.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.database});
  final AppDatabase database;
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  late final _repository = CalendarRepository(widget.database);
  late final _logs = TodayRepository(widget.database);
  DateTime _date = RecordDay.today();
  late final RecordDayWatcher _dayWatcher;
  late DateTime _month = DateTime(_date.year, _date.month);
  late Future<CalendarMonthData> _monthFuture = _repository.loadMonth(_month);
  late Future<TodayLogData> _logFuture = _logs.loadDay(_date);
  String? _cycleId;
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayWatcher = RecordDayWatcher((previous, current) {
      if (!mounted) return;
      if (_date == previous && current != previous) _select(current);
      _refresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayWatcher.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _select(DateTime date) {
    setState(() {
      _date = DateUtils.dateOnly(date);
      final month = DateTime(date.year, date.month);
      if (month != _month) {
        _month = month;
        _monthFuture = _repository.loadMonth(month);
      }
      _logFuture = _logs.loadDay(_date);
    });
  }

  void _move(int offset) {
    final month = DateTime(_month.year, _month.month + offset);
    final now = RecordDay.today();
    var date = DateTime(
      month.year,
      month.month,
      _date.day.clamp(1, DateUtils.getDaysInMonth(month.year, month.month)),
    );
    if (date.isAfter(DateUtils.dateOnly(now))) date = DateUtils.dateOnly(now);
    _select(date);
  }

  Future<void> _refresh() async {
    final month = _repository.loadMonth(_month), log = _logs.loadDay(_date);
    setState(() {
      _monthFuture = month;
      _logFuture = log;
    });
    try {
      await Future.wait([month, log]);
    } catch (_) {
      /* Errors are displayed inline. */
    }
  }

  Future<void> _copy(int? module) async {
    if (_copying) return;
    final date = _date;
    setState(() => _copying = true);
    try {
      final data = await _logs.loadDay(date);
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final f = TodayLogFormatter(data, l, historical: true);
      await Clipboard.setData(
        ClipboardData(
          text: switch (module) {
            1 => f.section(l.fitness, f.fitness),
            2 => f.section(l.nutrition, f.food),
            3 => f.section(l.body, f.body),
            _ => f.all,
          },
        ),
      );
      if (!mounted) return;
      if (_date == date) setState(() => _logFuture = Future.value(data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.dateLogCopied(DateFormat.yMd(l.localeName).format(date)),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.todayCopyFailed('$error'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = RecordDay.today();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l.previousMonth,
                onPressed: _month.year == 2000 && _month.month == 1
                    ? null
                    : () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: now,
                    );
                    if (date != null && mounted) _select(date);
                  },
                  child: Text(
                    DateFormat.yMMMM(l.localeName).format(_month),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                tooltip: l.nextMonth,
                onPressed: DateTime(_month.year, _month.month + 1).isAfter(now)
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () {
                  _cycleId = null;
                  _select(now);
                },
                child: Text(l.today),
              ),
            ],
          ),
          FutureBuilder<CalendarMonthData>(
            key: ValueKey(_month),
            future: _monthFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: _refresh,
                  child: Text(l.calendarLoadError('${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final data = snapshot.data!;
              final cycles = {for (final c in data.cycles) c.cycle.id: c};
              final material = MaterialLocalizations.of(context);
              final firstWeekday = material.firstDayOfWeekIndex;
              final offset = (_month.weekday % 7 - firstWeekday + 7) % 7;
              final count = DateUtils.getDaysInMonth(_month.year, _month.month);
              final slots = ((offset + count) / 7).ceil() * 7;
              final chosenCycle = cycles[_cycleId];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              for (var i = 0; i < 7; i++)
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      material.narrowWeekdays[(firstWeekday +
                                              i) %
                                          7],
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: slots,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisExtent: math.max(
                                    64,
                                    MediaQuery.textScalerOf(context).scale(14) +
                                        34,
                                  ),
                                  crossAxisSpacing: 3,
                                  mainAxisSpacing: 3,
                                ),
                            itemBuilder: (context, index) {
                              final dayNumber = index - offset + 1;
                              if (dayNumber < 1 || dayNumber > count) {
                                return const SizedBox();
                              }
                              final date = DateTime(
                                _month.year,
                                _month.month,
                                dayNumber,
                              );
                              final d =
                                  data.days[_repository.key(date)] ??
                                  CalendarDay();
                              final cycle = d.cycleIds
                                  .map((id) => cycles[id])
                                  .whereType<CalendarCycle>()
                                  .firstOrNull;
                              final dim =
                                  _cycleId != null &&
                                  !d.cycleIds.contains(_cycleId);
                              final labels = [
                                DateFormat.yMMMMd(l.localeName).format(date),
                                if (d.training) l.fitness,
                                if (d.rest) l.restRecorded,
                                if (d.skipped) l.trainingSkipped,
                                if (d.nutrition) l.nutrition,
                                if (d.body) l.body,
                                if (d.review) l.dailyReview,
                                if (cycle != null)
                                  '${cycle.planName} · ${l.cycleNumber(cycle.cycle.cycleNumber)}',
                              ].join(', ');
                              final color = cycle == null
                                  ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerLow
                                  : Color(cycle.cycle.colorValue);
                              return Semantics(
                                label: labels,
                                selected: date == _date,
                                button: true,
                                child: Tooltip(
                                  message: labels,
                                  child: Opacity(
                                    opacity: dim || date.isAfter(now) ? .35 : 1,
                                    child: InkWell(
                                      key: ValueKey(
                                        'calendar-${_repository.key(date)}',
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: date.isAfter(now)
                                          ? null
                                          : () => _select(date),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.withValues(
                                            alpha: cycle == null ? 1 : .15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: date == _date
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                : cycle == null
                                                ? Colors.transparent
                                                : color.withValues(alpha: .5),
                                            width: date == _date ? 2 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                '$dayNumber',
                                                maxLines: 1,
                                                softWrap: false,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      date == now ||
                                                          date == _date
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  decoration: date == now
                                                      ? TextDecoration.underline
                                                      : null,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              children: [
                                                if (d.training)
                                                  const Icon(
                                                    Icons.fitness_center,
                                                    size: 10,
                                                  ),
                                                if (d.rest)
                                                  const Icon(
                                                    Icons.bedtime_outlined,
                                                    size: 10,
                                                  ),
                                                if (d.skipped)
                                                  const Icon(
                                                    Icons.skip_next,
                                                    size: 10,
                                                  ),
                                                if (d.nutrition)
                                                  const Icon(
                                                    Icons.restaurant_outlined,
                                                    size: 10,
                                                  ),
                                                if (d.body)
                                                  const Icon(
                                                    Icons
                                                        .monitor_weight_outlined,
                                                    size: 10,
                                                  ),
                                                if (d.review)
                                                  const Icon(
                                                    Icons.notes_outlined,
                                                    size: 10,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final (icon, title) in [
                        (Icons.fitness_center, l.fitness),
                        (Icons.bedtime_outlined, l.restRecorded),
                        (Icons.skip_next, l.trainingSkipped),
                        (Icons.restaurant_outlined, l.nutrition),
                        (Icons.monitor_weight_outlined, l.body),
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 13),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_cycleId),
                    initialValue: chosenCycle?.cycle.id ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.locateCycle),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l.allCycles)),
                      for (final c in data.cycles)
                        DropdownMenuItem(
                          value: c.cycle.id,
                          child: Text(
                            '${c.planName} · ${l.cycleNumber(c.cycle.cycleNumber)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() => _cycleId = value == '' ? null : value);
                      final cycle = cycles[value];
                      if (cycle != null) _select(cycle.startDate);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chosenCycle == null
                        ? l.cycleCalendarHint
                        : '${DateFormat.yMd(l.localeName).format(chosenCycle.startDate)} – ${DateFormat.yMd(l.localeName).format(chosenCycle.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            DateFormat.yMMMMEEEEd(l.localeName).format(_date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _copying ? null : () => _copy(null),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(l.copySelectedLog),
          ),
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoricalFitnessPage(
                    repository: FitnessRepository(widget.database),
                    date: _date,
                  ),
                ),
              );
              if (mounted) _refresh();
            },
            icon: const Icon(Icons.edit_calendar),
            label: Text(l.editDateFitness),
          ),
          Text(l.recordDayHint, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          FutureBuilder<TodayLogData>(
            key: ValueKey(_date),
            future: _logFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: _refresh,
                  child: Text(l.todayLoadError('${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final f = TodayLogFormatter(snapshot.data!, l, historical: true);
              return Column(
                children: [
                  if (snapshot.data!.note.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l.dailyReview,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            SelectableText(snapshot.data!.note),
                          ],
                        ),
                      ),
                    ),
                  for (final (index, title, text) in [
                    (1, l.fitness, f.fitness),
                    (2, l.nutrition, f.food),
                    (3, l.body, f.body),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l.copyTodaySection(title),
                                    onPressed: _copying
                                        ? null
                                        : () => _copy(index),
                                    icon: const Icon(Icons.copy_outlined),
                                  ),
                                ],
                              ),
                              SelectableText(text),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
