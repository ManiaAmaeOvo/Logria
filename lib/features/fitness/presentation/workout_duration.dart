import '../../../l10n/app_localizations.dart';

String? workoutDurationLabel(AppLocalizations l, Duration? duration) =>
    duration == null ? null : l.workoutDuration(elapsedClock(duration));

String elapsedClock(Duration elapsed) {
  final seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return hours == 0 ? '$minutes:$remainder' : '$hours:$minutes:$remainder';
}
