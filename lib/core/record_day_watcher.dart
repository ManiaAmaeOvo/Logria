import 'dart:async';

import 'package:flutter/widgets.dart';

import 'record_day.dart';

/// Refresh on 04:00 and resume without resetting a manually selected past date.
class RecordDayWatcher extends WidgetsBindingObserver {
  RecordDayWatcher(this.onRefresh) : _date = RecordDay.today() {
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }
  final void Function(DateTime previous, DateTime current) onRefresh;
  DateTime _date;
  Timer? _timer;
  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    _timer = Timer(RecordDay.nextBoundary(now).difference(now), _refresh);
  }

  void _refresh() {
    final previous = _date;
    _date = RecordDay.today();
    onRefresh(previous, _date);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
