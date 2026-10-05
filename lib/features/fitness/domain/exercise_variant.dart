import 'dart:convert';

String variantExerciseName(String base, String note) =>
    '${base.trim()} [${note.trim()}]';

({String base, String? note}) exerciseVariant(String name, String? metadata) {
  if (metadata != null) {
    try {
      final data = jsonDecode(metadata) as Map<String, dynamic>;
      if (data['kind'] == 'variant') {
        return (base: data['base'] as String, note: data['note'] as String);
      }
    } catch (_) {
      /* Older free-text preset notes are not variant metadata. */
    }
  }
  return (base: name, note: null);
}
