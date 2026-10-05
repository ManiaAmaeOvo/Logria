import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class ExerciseVariantDialog extends StatefulWidget {
  const ExerciseVariantDialog({super.key, this.initial = ''});
  final String initial;
  @override
  State<ExerciseVariantDialog> createState() => _ExerciseVariantDialogState();
}

class _ExerciseVariantDialogState extends State<ExerciseVariantDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.exerciseVariantNote),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.exerciseVariantHint),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('exercise-variant-note'),
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(hintText: l.exerciseVariantExample),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(l.save),
        ),
      ],
    );
  }
}
