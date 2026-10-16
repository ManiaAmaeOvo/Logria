import 'database/app_database.dart';
import 'number_format.dart';

extension WorkoutSetValues on WorkoutSet {
  String? get rirLabel => rirText ?? (rir == null ? null : formatNumber(rir!));
}
