import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/today_repository.dart';
import 'today_log_formatter.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.database,
    required this.onOpenModule,
  });
  final AppDatabase database;
  final ValueChanged<int> onOpenModule;
  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> with WidgetsBindingObserver {
  late final _repository = TodayRepository(widget.database);
  late Future<TodayLogData> _future;
  Timer? _midnight;
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _repository.loadDay(DateTime.now());
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    _midnight = Timer(
      DateTime(now.year, now.month, now.day + 1).difference(now),
      () {
        if (mounted) _reload();
      },
    );
  }

  Future<void> _reload() async {
    final future = _repository.loadDay(DateTime.now());
    setState(() {
      _future = future;
    });
    _scheduleMidnight();
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the load error and retry action.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _copy({int? module}) async {
    if (_copying) return;
    setState(() => _copying = true);
    try {
      // Read fresh data, including a possible date rollover, before copying.
      final data = await _repository.loadDay(DateTime.now());
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      final formatter = TodayLogFormatter(data, l);
      final text = switch (module) {
        1 => formatter.section(l.fitness, formatter.fitness),
        2 => formatter.section(l.nutrition, formatter.food),
        3 => formatter.section(l.body, formatter.body),
        _ => formatter.all,
      };
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      setState(() {
        _future = Future.value(data);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.todayLogCopied)));
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
    return FutureBuilder<TodayLogData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.todayLoadError('${snapshot.error}')),
                TextButton(onPressed: _reload, child: Text(l.retry)),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final formatter = TodayLogFormatter(data, l);
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                DateFormat.yMMMMEEEEd(l.localeName).format(data.date),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _copying ? null : () => _copy(),
                      icon: const Icon(Icons.copy_all_outlined),
                      label: Text(l.copyTodayLog),
                    ),
                  ),
                  IconButton(
                    tooltip: l.refreshToday,
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.todayCopyHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _DailyReviewCard(
                key: ValueKey(data.nutrition.localDate),
                repository: _repository,
                localDate: data.nutrition.localDate,
                initialNote: data.note,
              ),
              const SizedBox(height: 12),
              for (final (module, title, icon, text) in [
                (1, l.fitness, Icons.fitness_center, formatter.fitness),
                (2, l.nutrition, Icons.restaurant_outlined, formatter.food),
                (3, l.body, Icons.monitor_weight_outlined, formatter.body),
              ]) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: l.copyTodaySection(title),
                              onPressed: _copying
                                  ? null
                                  : () => _copy(module: module),
                              icon: const Icon(Icons.copy_outlined),
                            ),
                            IconButton(
                              tooltip: l.openModule(title),
                              onPressed: () => widget.onOpenModule(module),
                              icon: const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(text),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DailyReviewCard extends StatefulWidget {
  const _DailyReviewCard({
    super.key,
    required this.repository,
    required this.localDate,
    required this.initialNote,
  });
  final TodayRepository repository;
  final String localDate, initialNote;
  @override
  State<_DailyReviewCard> createState() => _DailyReviewCardState();
}

class _DailyReviewCardState extends State<_DailyReviewCard> {
  late final _controller = TextEditingController(text: widget.initialNote);
  bool _saving = false;
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context)!;
    try {
      await widget.repository.saveNote(widget.localDate, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.reviewSaved)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.dailyReview, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('daily-review'),
              controller: _controller,
              enabled: !_saving,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(hintText: l.dailyReviewHint),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(l.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
