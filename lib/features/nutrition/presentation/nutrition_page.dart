import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/nutrition_repository.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key, required this.database});

  final AppDatabase database;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  late final NutritionRepository _repository;
  late DateTime _selectedDate;
  late Future<NutritionDayData> _dayFuture;

  @override
  void initState() {
    super.initState();
    _repository = NutritionRepository(widget.database);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _dayFuture = _repository.loadDay(_selectedDate);
  }

  void _reload() {
    final future = _repository.loadDay(_selectedDate);
    setState(() {
      _dayFuture = future;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _dayFuture = _repository.loadDay(_selectedDate);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (date != null && mounted) _selectDate(date);
  }

  Future<void> _editFoodEntry({FoodLogEntry? entry}) async {
    final values = await showDialog<_IntakeValues>(
      context: context,
      builder: (_) => _IntakeDialog(record: null, meal: true, entry: entry),
    );
    if (values == null || !mounted) return;
    if (entry == null) {
      await _repository.addFoodEntry(
        _selectedDate,
        values.text!,
        proteinGrams: values.protein,
        carbohydrateGrams: values.carbohydrate,
        fatGrams: values.fat,
        caloriesKcal: values.calories,
        caloriesEstimated: values.estimated,
      );
    } else {
      await _repository.updateFoodEntry(
        entry.id,
        values.text!,
        proteinGrams: values.protein,
        carbohydrateGrams: values.carbohydrate,
        fatGrams: values.fat,
        caloriesKcal: values.calories,
        caloriesEstimated: values.estimated,
      );
    }
    if (mounted) _reload();
  }

  Future<void> _deleteFoodEntry(FoodLogEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFoodNoteTitle),
        content: Text(l10n.deleteFoodNoteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _repository.deleteFoodEntry(entry.id);
    if (mounted) _reload();
  }

  Future<void> _editIntake(DailyNutritionRecord? record) async {
    final values = await showDialog<_IntakeValues>(
      context: context,
      builder: (_) => _IntakeDialog(record: record),
    );
    if (values == null) return;
    await _repository.saveDailyIntake(
      date: _selectedDate,
      proteinGrams: values.protein,
      carbohydrateGrams: values.carbohydrate,
      fatGrams: values.fat,
      caloriesKcal: values.calories,
    );
    if (mounted) _reload();
  }

  Future<void> _editTargets(NutritionTargets targets) async {
    final values = await showDialog<NutritionTargets>(
      context: context,
      builder: (_) => _TargetsDialog(targets: targets),
    );
    if (values == null) return;
    await _repository.saveTargets(values);
    if (mounted) _reload();
  }

  Future<void> _copyFoodLog(NutritionDayData day) async {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMd(l10n.localeName).format(_selectedDate);
    final lines = [
      '${l10n.foodLog} · $date',
      for (final entry in day.foodEntries)
        '- ${DateFormat.Hm(l10n.localeName).format(entry.occurredAt ?? entry.createdAt)}  ${entry.textContent}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.foodLogCopied)));
  }

  Future<void> _copyIntake(NutritionDayData day) async {
    final l10n = AppLocalizations.of(context)!;
    final record = day.record;
    if (record == null) return;
    final date = DateFormat.yMd(l10n.localeName).format(_selectedDate);
    final text = [
      '${l10n.dailyIntake} · $date',
      '${l10n.proteinGrams}: ${_displayOptional(record.proteinGrams)}',
      '${l10n.carbohydrateGrams}: ${_displayOptional(record.carbohydrateGrams)}',
      '${l10n.fatGrams}: ${_displayOptional(record.fatGrams)}',
      '${l10n.caloriesKcal}: ${_displayOptional(record.caloriesKcal)}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.intakeCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = DateTime.now();
    final isToday =
        _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return FutureBuilder<NutritionDayData>(
      future: _dayFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.nutritionLoadError('${snapshot.error}')),
                const SizedBox(height: 8),
                FilledButton(onPressed: _reload, child: Text(l10n.retry)),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final day = snapshot.data!;
        final record = day.record;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _DateSelector(
              date: _selectedDate,
              isToday: isToday,
              onPrevious: () =>
                  _selectDate(_selectedDate.subtract(const Duration(days: 1))),
              onNext: isToday
                  ? null
                  : () =>
                        _selectDate(_selectedDate.add(const Duration(days: 1))),
              onPickDate: _pickDate,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.dailyIntake,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _editIntake(record),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(record == null ? l10n.add : l10n.edit),
                        ),
                        if (record != null)
                          IconButton(
                            tooltip: l10n.copyIntake,
                            onPressed: () => _copyIntake(day),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                      ],
                    ),
                    Text(
                      record != null && record.source != 'meals'
                          ? l10n.manualDailyTotal
                          : l10n.intakeIndependentNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (record != null && record.source != 'meals')
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () async {
                            await _repository.useMealTotals(_selectedDate);
                            if (mounted) _reload();
                          },
                          child: Text(l10n.useMealTotals),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _MacroValue(
                          label: 'P',
                          value: record?.proteinGrams,
                          unit: 'g',
                        ),
                        _MacroValue(
                          label: 'C',
                          value: record?.carbohydrateGrams,
                          unit: 'g',
                        ),
                        _MacroValue(
                          label: 'F',
                          value: record?.fatGrams,
                          unit: 'g',
                        ),
                        _MacroValue(
                          label: l10n.caloriesShort,
                          value: record?.caloriesKcal,
                          unit: 'kcal',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.dailyGoals,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _editTargets(day.targets),
                          icon: const Icon(Icons.tune),
                          label: Text(l10n.setGoals),
                        ),
                      ],
                    ),
                    if (day.targets.proteinGoalGrams == null &&
                        day.targets.carbohydrateGoalGrams == null &&
                        day.targets.fatGoalGrams == null &&
                        day.targets.calorieLimitKcal == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(l10n.noNutritionGoals),
                      ),
                    if (day.targets.proteinGoalGrams case final goal?) ...[
                      const SizedBox(height: 12),
                      _ProgressMetric(
                        title:
                            'P · ${day.targets.proteinIsLimit ? l10n.nutrientLimit : l10n.nutrientGoal}',
                        current: record?.proteinGrams,
                        target: goal,
                        unit: 'g',
                        isLimit: day.targets.proteinIsLimit,
                      ),
                    ],
                    if (day.targets.calorieLimitKcal case final limit?) ...[
                      const SizedBox(height: 16),
                      _ProgressMetric(
                        title:
                            'kcal · ${day.targets.caloriesIsLimit ? l10n.nutrientLimit : l10n.nutrientGoal}',
                        current: record?.caloriesKcal,
                        target: limit,
                        unit: 'kcal',
                        isLimit: day.targets.caloriesIsLimit,
                      ),
                    ],
                    if (day.targets.carbohydrateGoalGrams case final goal?) ...[
                      const SizedBox(height: 16),
                      _ProgressMetric(
                        title:
                            'C · ${day.targets.carbohydrateIsLimit ? l10n.nutrientLimit : l10n.nutrientGoal}',
                        current: record?.carbohydrateGrams,
                        target: goal,
                        unit: 'g',
                        isLimit: day.targets.carbohydrateIsLimit,
                      ),
                    ],
                    if (day.targets.fatGoalGrams case final goal?) ...[
                      const SizedBox(height: 16),
                      _ProgressMetric(
                        title:
                            'F · ${day.targets.fatIsLimit ? l10n.nutrientLimit : l10n.nutrientGoal}',
                        current: record?.fatGrams,
                        target: goal,
                        unit: 'g',
                        isLimit: day.targets.fatIsLimit,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.foodLog,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.copyFoodLog,
                          onPressed: day.foodEntries.isEmpty
                              ? null
                              : () => _copyFoodLog(day),
                          icon: const Icon(Icons.copy_outlined),
                        ),
                        IconButton.filledTonal(
                          tooltip: l10n.addFoodNote,
                          onPressed: () => _editFoodEntry(),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    Text(
                      l10n.foodLogIndependentNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (day.foodEntries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(l10n.emptyFoodLog),
                      )
                    else
                      for (
                        var index = 0;
                        index < day.foodEntries.length;
                        index++
                      ) ...[
                        if (index > 0) const Divider(height: 1),
                        _FoodEntryTile(
                          entry: day.foodEntries[index],
                          onEdit: () =>
                              _editFoodEntry(entry: day.foodEntries[index]),
                          onDelete: () =>
                              _deleteFoodEntry(day.foodEntries[index]),
                        ),
                      ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.previousDay,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: TextButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              DateFormat.yMMMMEEEEd(l10n.localeName).format(date),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.nextDay,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _MacroValue extends StatelessWidget {
  const _MacroValue({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final double? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(
            value == null ? '—' : '${_format(value!)} $unit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.isLimit,
  });

  final String title;
  final double? current;
  final double target;
  final String unit;
  final bool isLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amount = current ?? 0;
    final fraction = target <= 0 ? 0.0 : (amount / target).clamp(0.0, 1.0);
    final difference = target - amount;
    final detail = isLimit
        ? difference >= 0
              ? l10n.remainingAllowance(_format(difference), unit)
              : l10n.overLimitAmount(_format(-difference), unit)
        : difference > 0
        ? l10n.remainingAmount(_format(difference), unit)
        : l10n.goalReached;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
            Flexible(
              flex: 2,
              child: Text(
                '${current == null ? '—' : _format(amount)} / ${_format(target)} $unit',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 10,
            color: isLimit && difference < 0
                ? Theme.of(context).colorScheme.error
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _FoodEntryTile extends StatelessWidget {
  const _FoodEntryTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FoodLogEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = entry.occurredAt ?? entry.createdAt;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(entry.textContent),
      onTap: onEdit,
      subtitle: Text(
        '${DateFormat.Hm(l10n.localeName).format(time)}\nP ${_displayOptional(entry.proteinGrams)} · C ${_displayOptional(entry.carbohydrateGrams)} · F ${_displayOptional(entry.fatGrams)} g · ${_displayOptional(entry.caloriesKcal)} kcal',
      ),
      trailing: PopupMenuButton<String>(
        tooltip: l10n.foodNoteOptions,
        onSelected: (value) {
          if (value == 'edit') onEdit();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }
}

class _IntakeValues {
  const _IntakeValues(
    this.protein,
    this.carbohydrate,
    this.fat,
    this.calories, {
    this.text,
    this.estimated = false,
  });
  final String? text;
  final bool estimated;

  final double? protein;
  final double? carbohydrate;
  final double? fat;
  final double? calories;
}

class _IntakeDialog extends StatefulWidget {
  const _IntakeDialog({required this.record, this.meal = false, this.entry});
  final bool meal;
  final FoodLogEntry? entry;

  final DailyNutritionRecord? record;

  @override
  State<_IntakeDialog> createState() => _IntakeDialogState();
}

class _IntakeDialogState extends State<_IntakeDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _automatic = widget.entry?.caloriesEstimated ?? true;
  late final _text = TextEditingController(
    text: widget.entry?.textContent ?? '',
  );
  late final _protein = TextEditingController(
    text: _initial(widget.entry?.proteinGrams ?? widget.record?.proteinGrams),
  );
  late final _carbs = TextEditingController(
    text: _initial(
      widget.entry?.carbohydrateGrams ?? widget.record?.carbohydrateGrams,
    ),
  );
  late final _fat = TextEditingController(
    text: _initial(widget.entry?.fatGrams ?? widget.record?.fatGrams),
  );
  late final _calories = TextEditingController(
    text: _initial(widget.entry?.caloriesKcal ?? widget.record?.caloriesKcal),
  );

  @override
  void dispose() {
    _text.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.meal
            ? (widget.entry == null ? l10n.addFoodNote : l10n.editFoodNote)
            : l10n.dailyIntake,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.meal) ...[
                TextFormField(
                  controller: _text,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.foodLog,
                    hintText: l10n.foodNoteHint,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? l10n.foodNoteRequired
                      : null,
                ),
                const SizedBox(height: 16),
                Text(l10n.foodLogIndependentNote),
                const SizedBox(height: 12),
              ],
              _MetricField(
                controller: _protein,
                label: l10n.proteinGrams,
                onChanged: (_) => _updateCalories(),
              ),
              _MetricField(
                controller: _carbs,
                label: l10n.carbohydrateGrams,
                onChanged: (_) => _updateCalories(),
              ),
              _MetricField(
                controller: _fat,
                label: l10n.fatGrams,
                onChanged: (_) => _updateCalories(),
              ),
              if (widget.meal)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.estimateCalories),
                  subtitle: const Text('4P + 4C + 9F'),
                  value: _automatic,
                  onChanged: (value) {
                    setState(() => _automatic = value);
                    _updateCalories();
                  },
                ),
              _MetricField(
                controller: _calories,
                label: l10n.caloriesKcal,
                readOnly: widget.meal && _automatic,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final protein = _parse(_protein.text);
    final carbs = _parse(_carbs.text);
    final fat = _parse(_fat.text);
    final calories = _parse(_calories.text);
    if (!_valid(protein, _protein.text) ||
        !_valid(carbs, _carbs.text) ||
        !_valid(fat, _fat.text) ||
        !_valid(calories, _calories.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidNutritionValue),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _IntakeValues(
        protein,
        carbs,
        fat,
        calories,
        text: widget.meal ? _text.text : null,
        estimated: widget.meal && _automatic,
      ),
    );
  }

  void _updateCalories() {
    if (!widget.meal || !_automatic) return;
    final p = _parse(_protein.text),
        c = _parse(_carbs.text),
        f = _parse(_fat.text);
    if (!_valid(p, _protein.text) ||
        !_valid(c, _carbs.text) ||
        !_valid(f, _fat.text)) {
      _calories.clear();
      return;
    }
    final estimate = (p ?? 0) * 4 + (c ?? 0) * 4 + (f ?? 0) * 9;
    _calories.text = p == null && c == null && f == null
        ? ''
        : estimate.isFinite
        ? _format(estimate)
        : '';
  }
}

class _TargetsDialog extends StatefulWidget {
  const _TargetsDialog({required this.targets});

  final NutritionTargets targets;

  @override
  State<_TargetsDialog> createState() => _TargetsDialogState();
}

class _TargetsDialogState extends State<_TargetsDialog> {
  late final _limits = [
    widget.targets.proteinIsLimit,
    widget.targets.carbohydrateIsLimit,
    widget.targets.fatIsLimit,
    widget.targets.caloriesIsLimit,
  ];
  late final _carbs = TextEditingController(
    text: _initial(widget.targets.carbohydrateGoalGrams),
  );
  late final _fat = TextEditingController(
    text: _initial(widget.targets.fatGoalGrams),
  );
  late final _protein = TextEditingController(
    text: _initial(widget.targets.proteinGoalGrams),
  );
  late final _calories = TextEditingController(
    text: _initial(widget.targets.calorieLimitKcal),
  );

  @override
  void dispose() {
    _carbs.dispose();
    _fat.dispose();
    _protein.dispose();
    _calories.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.setNutritionGoals),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, controller, label) in [
              (0, _protein, l10n.proteinGrams),
              (1, _carbs, l10n.carbohydrateGrams),
              (2, _fat, l10n.fatGrams),
              (3, _calories, l10n.caloriesKcal),
            ]) ...[
              _MetricField(controller: controller, label: label),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.nutrientGoal)),
                  ButtonSegment(value: true, label: Text(l10n.nutrientLimit)),
                ],
                selected: {_limits[index]},
                onSelectionChanged: (selection) =>
                    setState(() => _limits[index] = selection.single),
              ),
              const SizedBox(height: 18),
            ],
            const SizedBox(height: 4),
            Text(
              l10n.blankGoalHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }

  void _save() {
    final protein = _parse(_protein.text);
    final calories = _parse(_calories.text);
    final carbs = _parse(_carbs.text), fat = _parse(_fat.text);
    if (!_validTarget(protein, _protein.text) ||
        !_validTarget(carbs, _carbs.text) ||
        !_validTarget(fat, _fat.text) ||
        !_validTarget(calories, _calories.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invalidTargetValue),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      NutritionTargets(
        proteinIsLimit: _limits[0],
        carbohydrateIsLimit: _limits[1],
        fatIsLimit: _limits[2],
        caloriesIsLimit: _limits[3],
        proteinGoalGrams: protein,
        carbohydrateGoalGrams: carbs,
        fatGoalGrams: fat,
        calorieLimitKcal: calories,
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  const _MetricField({
    required this.controller,
    required this.label,
    this.onChanged,
    this.readOnly = false,
  });
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      onChanged: onChanged,
      readOnly: readOnly,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
      validator: (value) => _valid(_parse(value ?? ''), value ?? '')
          ? null
          : AppLocalizations.of(context)!.invalidNutritionValue,
    ),
  );
}

String _initial(double? value) => value == null ? '' : _format(value);

double? _parse(String text) {
  final value = text.trim();
  if (value.isEmpty) return null;
  return double.tryParse(value.replaceAll(',', '.'));
}

bool _valid(double? parsed, String text) =>
    text.trim().isEmpty || (parsed != null && parsed.isFinite && parsed >= 0);

bool _validTarget(double? parsed, String text) =>
    text.trim().isEmpty || (parsed != null && parsed.isFinite && parsed > 0);

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String _displayOptional(double? value) => value == null ? '—' : _format(value);
