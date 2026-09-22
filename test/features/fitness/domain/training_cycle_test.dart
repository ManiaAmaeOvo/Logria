import 'package:flutter_test/flutter_test.dart';
import 'package:logria/features/fitness/domain/training_cycle.dart';

void main() {
  final day = DateTime(2026, 9, 23, 8);

  List<CycleDayDefinition> pplDays() => const [
    CycleDayDefinition(
      id: 'push-1',
      name: 'Push 1',
      position: 0,
      type: CycleDayType.training,
    ),
    CycleDayDefinition(
      id: 'pull-1',
      name: 'Pull 1',
      position: 1,
      type: CycleDayType.training,
    ),
    CycleDayDefinition(
      id: 'legs-1',
      name: 'Legs 1',
      position: 2,
      type: CycleDayType.training,
    ),
    CycleDayDefinition(
      id: 'rest-1',
      name: 'Rest',
      position: 3,
      type: CycleDayType.rest,
    ),
  ];

  test('moving a planned rest preserves the pending training day', () {
    var progress = TrainingCycleProgress(cycleNumber: 1, days: pplDays());
    progress = progress.completeCurrent(day).progress;

    final transition = progress.takeRest(day.add(const Duration(days: 1)));

    expect(transition.execution.type, CycleExecutionType.movedRest);
    expect(transition.execution.planDayId, 'rest-1');
    expect(transition.execution.originalPosition, 3);
    expect(transition.progress.nextDay?.id, 'pull-1');
  });

  test('a moved rest is not repeated at its default position', () {
    var progress = TrainingCycleProgress(cycleNumber: 1, days: pplDays());
    progress = progress.completeCurrent(day).progress;
    progress = progress.takeRest(day.add(const Duration(days: 1))).progress;
    progress = progress
        .completeCurrent(day.add(const Duration(days: 2)))
        .progress;
    progress = progress
        .completeCurrent(day.add(const Duration(days: 3)))
        .progress;

    expect(progress.isComplete, isTrue);
  });

  test('rest becomes extra rest after all planned rest slots are consumed', () {
    var progress = TrainingCycleProgress(cycleNumber: 1, days: pplDays());
    progress = progress.takeRest(day).progress;

    final transition = progress.takeRest(day.add(const Duration(days: 1)));

    expect(transition.execution.type, CycleExecutionType.extraRest);
    expect(transition.execution.planDayId, isNull);
    expect(transition.progress.nextDay?.id, 'push-1');
  });

  test('skipping consumes only the current training day', () {
    final progress = TrainingCycleProgress(cycleNumber: 1, days: pplDays());

    final transition = progress.skipCurrentTraining(day);

    expect(transition.execution.type, CycleExecutionType.skippedTraining);
    expect(transition.progress.nextDay?.id, 'pull-1');
  });
}
