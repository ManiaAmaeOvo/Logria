import 'dart:convert';

class WorkoutEditorDraft {
  const WorkoutEditorDraft(this.exercises, {this.startedAt});

  final List<dynamic> exercises;
  final DateTime? startedAt;

  factory WorkoutEditorDraft.decode(String raw) {
    final value = jsonDecode(raw);
    if (value is List) return WorkoutEditorDraft(value);
    if (value is Map &&
        value['exercises'] is List &&
        value['startedAt'] is String) {
      final start = DateTime.tryParse(value['startedAt'] as String);
      if (start != null) {
        return WorkoutEditorDraft(value['exercises'] as List, startedAt: start);
      }
    }
    throw const FormatException('Invalid workout draft');
  }

  String encode() => jsonEncode(
    startedAt == null
        ? exercises
        : {
            'exercises': exercises,
            'startedAt': startedAt!.toUtc().toIso8601String(),
          },
  );
}
