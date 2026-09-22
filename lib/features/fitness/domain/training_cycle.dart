enum CycleDayType { training, rest }

enum CycleExecutionType {
  completedTraining,
  skippedTraining,
  plannedRest,
  movedRest,
  extraRest,
}

class CycleDayDefinition {
  const CycleDayDefinition({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
  });

  final String id;
  final String name;
  final int position;
  final CycleDayType type;
}

class CycleExecution {
  const CycleExecution({
    required this.type,
    required this.occurredAt,
    this.planDayId,
    this.originalPosition,
  });

  final CycleExecutionType type;
  final DateTime occurredAt;
  final String? planDayId;
  final int? originalPosition;
}

class CycleTransition {
  const CycleTransition({required this.progress, required this.execution});

  final TrainingCycleProgress progress;
  final CycleExecution execution;
}

/// Runtime state for one concrete cycle of a training plan.
///
/// A moved rest day consumes the next unconsumed rest slot without consuming
/// the pending training slot. This keeps the plan order stable while allowing
/// recovery days to happen earlier in the cycle.
class TrainingCycleProgress {
  TrainingCycleProgress({
    required this.cycleNumber,
    required List<CycleDayDefinition> days,
    Set<String> consumedDayIds = const {},
  }) : assert(cycleNumber > 0),
       days = List.unmodifiable(_validatedDays(days)),
       consumedDayIds = Set.unmodifiable(consumedDayIds) {
    final knownIds = this.days.map((day) => day.id).toSet();
    if (!knownIds.containsAll(consumedDayIds)) {
      throw ArgumentError('Consumed day ids must belong to this cycle.');
    }
  }

  final int cycleNumber;
  final List<CycleDayDefinition> days;
  final Set<String> consumedDayIds;

  bool get isComplete => nextDay == null;

  CycleDayDefinition? get nextDay {
    for (final day in days) {
      if (!consumedDayIds.contains(day.id)) return day;
    }
    return null;
  }

  CycleTransition completeCurrent(DateTime occurredAt) {
    final current = nextDay;
    if (current == null) {
      throw StateError('The cycle is already complete.');
    }

    final type = current.type == CycleDayType.training
        ? CycleExecutionType.completedTraining
        : CycleExecutionType.plannedRest;
    return _consume(current, type, occurredAt);
  }

  CycleTransition skipCurrentTraining(DateTime occurredAt) {
    final current = nextDay;
    if (current == null) {
      throw StateError('The cycle is already complete.');
    }
    if (current.type != CycleDayType.training) {
      throw StateError('Only a training day can be skipped.');
    }

    return _consume(current, CycleExecutionType.skippedTraining, occurredAt);
  }

  CycleTransition takeRest(DateTime occurredAt) {
    final current = nextDay;
    if (current == null) {
      throw StateError('The cycle is already complete.');
    }

    if (current.type == CycleDayType.rest) {
      return _consume(current, CycleExecutionType.plannedRest, occurredAt);
    }

    CycleDayDefinition? availableRest;
    for (final day in days) {
      if (day.type == CycleDayType.rest &&
          !consumedDayIds.contains(day.id) &&
          day.position > current.position) {
        availableRest = day;
        break;
      }
    }

    if (availableRest == null) {
      return CycleTransition(
        progress: this,
        execution: CycleExecution(
          type: CycleExecutionType.extraRest,
          occurredAt: occurredAt,
        ),
      );
    }

    return _consume(availableRest, CycleExecutionType.movedRest, occurredAt);
  }

  CycleTransition _consume(
    CycleDayDefinition day,
    CycleExecutionType type,
    DateTime occurredAt,
  ) {
    final nextConsumedIds = {...consumedDayIds, day.id};
    return CycleTransition(
      progress: TrainingCycleProgress(
        cycleNumber: cycleNumber,
        days: days,
        consumedDayIds: nextConsumedIds,
      ),
      execution: CycleExecution(
        type: type,
        occurredAt: occurredAt,
        planDayId: day.id,
        originalPosition: day.position,
      ),
    );
  }

  static List<CycleDayDefinition> _validatedDays(
    List<CycleDayDefinition> days,
  ) {
    if (days.isEmpty) {
      throw ArgumentError('A training cycle must contain at least one day.');
    }

    final sorted = [...days]..sort((a, b) => a.position.compareTo(b.position));
    if (sorted.map((day) => day.id).toSet().length != sorted.length) {
      throw ArgumentError('Cycle day ids must be unique.');
    }
    if (sorted.map((day) => day.position).toSet().length != sorted.length) {
      throw ArgumentError('Cycle day positions must be unique.');
    }
    return sorted;
  }
}
