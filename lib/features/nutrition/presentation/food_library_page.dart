import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/number_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/food_preset_repository.dart';
import '../domain/nutrient_values.dart';
import 'nutrition_labels.dart';

String foodName(FoodPreset p, AppLocalizations l) =>
    l.localeName.startsWith('zh') ? p.nameZh ?? p.name : p.name;
String foodNumber(double v) => formatNumber(v);
double? foodParse(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));
String initialFoodValue(double? value) =>
    value == null ? '' : foodNumber(value);
bool validFoodNumber(String text, {bool positive = false}) {
  final value = foodParse(text);
  return text.trim().isEmpty ||
      (value != null && value.isFinite && (positive ? value > 0 : value >= 0));
}

class FoodLibraryPage extends StatefulWidget {
  const FoodLibraryPage({
    super.key,
    required this.database,
    required this.date,
  });
  final AppDatabase database;
  final DateTime date;
  @override
  State<FoodLibraryPage> createState() => _FoodLibraryPageState();
}

class _FoodLibraryPageState extends State<FoodLibraryPage> {
  late final _repo = FoodPresetRepository(widget.database);
  late Future<List<FoodPreset>> _future = _repo.list();
  String _query = '';
  void _reload() => setState(() => _future = _repo.list());
  Future<void> _edit({FoodPreset? preset, bool copy = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FoodPresetEditorPage(repository: _repo, preset: preset, copy: copy),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(FoodPreset p) async {
    final l = AppLocalizations.of(context)!;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.delete),
        content: Text(l.deleteFoodPresetHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _repo.delete(p);
      if (mounted) _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
  }

  Future<void> _record(FoodPreset p) async {
    final l = AppLocalizations.of(context)!;
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => FoodQuantityDialog(preset: p),
    );
    if (amount == null || !mounted) return;
    try {
      await _repo.log(
        preset: p,
        date: widget.date,
        quantity: amount,
        description:
            '${foodName(p, l)} · ${preparationLabel(p.preparation, l)} · ${foodNumber(amount)} ${foodUnitLabel(p.unit, l)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.foodPresetLogged)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.saveFailed(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.foodLibrary),
        actions: [
          IconButton(
            tooltip: l.createFoodPreset,
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(DateFormat.yMMMMd(l.localeName).format(widget.date)),
                Text(
                  l.foodLibraryHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: l.searchFood,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FoodPreset>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: TextButton(onPressed: _reload, child: Text(l.retry)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final foods = snapshot.data!
                    .where(
                      (p) => '${p.name} ${p.nameZh ?? ''}'
                          .toLowerCase()
                          .contains(_query),
                    )
                    .toList();
                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (c, i) {
                    final p = foods[i];
                    return ListTile(
                      title: Text(foodName(p, l)),
                      subtitle: Text(
                        '${preparationLabel(p.preparation, l)} · ${foodNumber(p.referenceQuantity)} ${foodUnitLabel(p.unit, l)}\n${p.isBuiltIn ? l.referenceFood : l.customFood}',
                      ),
                      leading: Icon(
                        p.isBuiltIn
                            ? Icons.eco_outlined
                            : Icons.bookmark_outline,
                      ),
                      onTap: () => _record(p),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') _edit(preset: p);
                          if (v == 'copy') _edit(preset: p, copy: true);
                          if (v == 'delete') _delete(p);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'copy',
                            child: Text(l.copyFoodPreset),
                          ),
                          if (!p.isBuiltIn)
                            PopupMenuItem(value: 'edit', child: Text(l.edit)),
                          if (!p.isBuiltIn)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l.delete),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FoodPresetEditorPage extends StatefulWidget {
  const FoodPresetEditorPage({
    super.key,
    required this.repository,
    this.preset,
    this.copy = false,
  });
  final FoodPresetRepository repository;
  final FoodPreset? preset;
  final bool copy;
  @override
  State<FoodPresetEditorPage> createState() => _FoodPresetEditorPageState();
}

class _FoodPresetEditorPageState extends State<FoodPresetEditorPage> {
  late final _name = TextEditingController(text: widget.preset?.name ?? '');
  late final _reference = TextEditingController(
    text: foodNumber(widget.preset?.referenceQuantity ?? 100),
  );
  late final Map<String, TextEditingController> _fields = {
    for (final k in nutrientKeys)
      k: TextEditingController(
        text: initialFoodValue(
          decodeNutrients(widget.preset?.nutrientsJson)[k],
        ),
      ),
  };
  late final _kj = TextEditingController(
    text: initialFoodValue(
      decodeNutrients(widget.preset?.nutrientsJson)['calories'] == null
          ? null
          : decodeNutrients(widget.preset!.nutrientsJson)['calories']! *
                kilojoulesPerKcal,
    ),
  );
  late String _unit = widget.preset?.unit ?? 'g';
  late String _preparation = widget.preset?.preparation ?? 'other';
  late bool _automatic = widget.preset?.caloriesEstimated ?? true;
  bool _saving = false;
  bool _nameInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized) {
      if (widget.preset != null) {
        _name.text = foodName(widget.preset!, AppLocalizations.of(context)!);
      }
      _nameInitialized = true;
    }
  }

  void _macroChanged() {
    if (!_automatic) return;
    final p = _fields['protein']!,
        c = _fields['carbohydrate']!,
        f = _fields['fat']!;
    if (![p, c, f].every((v) => validFoodNumber(v.text))) {
      _fields['calories']!.clear();
      _kj.clear();
      return;
    }
    if ([p, c, f].every((v) => v.text.trim().isEmpty)) {
      _fields['calories']!.clear();
      _kj.clear();
      return;
    }
    final kcal =
        (foodParse(p.text) ?? 0) * 4 +
        (foodParse(c.text) ?? 0) * 4 +
        (foodParse(f.text) ?? 0) * 9;
    _fields['calories']!.text = kcal.isFinite ? foodNumber(kcal) : '';
    _kj.text = kcal.isFinite ? foodNumber(kcal * kilojoulesPerKcal) : '';
  }

  void _energyChanged(bool kj) {
    setState(() => _automatic = false);
    final value = foodParse(kj ? _kj.text : _fields['calories']!.text);
    final target = kj ? _fields['calories']! : _kj;
    final result = value == null
        ? null
        : kj
        ? value / kilojoulesPerKcal
        : value * kilojoulesPerKcal;
    target.text = result != null && result.isFinite && result >= 0
        ? foodNumber(result)
        : '';
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context)!;
    if (_name.text.trim().isEmpty ||
        _reference.text.trim().isEmpty ||
        !validFoodNumber(_reference.text, positive: true) ||
        !validFoodNumber(_kj.text) ||
        !_fields.values.every((v) => validFoodNumber(v.text))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.invalidFoodPreset)));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        id: widget.copy ? null : widget.preset?.id,
        name: _name.text,
        unit: _unit,
        referenceQuantity: foodParse(_reference.text)!,
        preparation: _preparation,
        nutrients: {
          for (final e in _fields.entries)
            if (foodParse(e.value.text) != null)
              e.key: foodParse(e.value.text)!,
        },
        estimated: _automatic,
      );
      if (mounted) Navigator.pop(context, true);
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
    _name.dispose();
    _reference.dispose();
    _kj.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.createFoodPreset)),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.foodBasisHint),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('food-preset-name'),
              controller: _name,
              decoration: InputDecoration(labelText: l.foodPresetName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              initialValue: _unit,
              decoration: InputDecoration(labelText: l.foodUnit),
              items: [
                for (final u in foodUnits)
                  DropdownMenuItem(value: u, child: Text(foodUnitLabel(u, l))),
              ],
              onChanged: (v) => setState(() => _unit = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('food-reference-quantity'),
              controller: _reference,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.referenceQuantity),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              initialValue: _preparation,
              decoration: InputDecoration(labelText: l.foodPreparation),
              items: [
                for (final p in foodPreparations)
                  DropdownMenuItem(
                    value: p,
                    child: Text(preparationLabel(p, l)),
                  ),
              ],
              onChanged: (v) => setState(() => _preparation = v!),
            ),
            const SizedBox(height: 16),
            for (final k in ['protein', 'carbohydrate', 'fat']) ...[
              TextField(
                key: ValueKey('preset-$k'),
                controller: _fields[k],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: nutrientLabel(k, l)),
                onChanged: (_) => _macroChanged(),
              ),
              const SizedBox(height: 12),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.estimateCalories),
              subtitle: const Text('4P + 4C + 9F'),
              value: _automatic,
              onChanged: (v) {
                setState(() => _automatic = v);
                _macroChanged();
              },
            ),
            TextField(
              key: const ValueKey('preset-calories'),
              controller: _fields['calories'],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.caloriesKcal),
              onChanged: (_) => _energyChanged(false),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('preset-kilojoules'),
              controller: _kj,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l.energyKilojoules),
              onChanged: (_) => _energyChanged(true),
            ),
            const SizedBox(height: 16),
            Text(l.extraNutrients),
            for (final k in extraNutrientUnits.keys) ...[
              const SizedBox(height: 12),
              TextField(
                key: ValueKey('preset-$k'),
                controller: _fields[k],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${nutrientLabel(k, l)} (${extraNutrientUnits[k]})',
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(l.foodMissingHint),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.save),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class FoodQuantityDialog extends StatefulWidget {
  const FoodQuantityDialog({super.key, required this.preset});
  final FoodPreset preset;
  @override
  State<FoodQuantityDialog> createState() => _FoodQuantityDialogState();
}

class _FoodQuantityDialogState extends State<FoodQuantityDialog> {
  late final _amount = TextEditingController(
    text: foodNumber(widget.preset.referenceQuantity),
  );
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.preset;
    final amount = foodParse(_amount.text);
    Map<String, double>? values;
    try {
      if (amount != null) {
        values = scaleNutrients(
          decodeNutrients(p.nutrientsJson),
          amount,
          p.referenceQuantity,
        );
      }
    } catch (_) {
      /* Keep incomplete input editable. */
    }
    return AlertDialog(
      scrollable: true,
      title: Text(foodName(p, l)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${preparationLabel(p.preparation, l)} · ${foodNumber(p.referenceQuantity)} ${foodUnitLabel(p.unit, l)}',
          ),
          if (p.source != null)
            Text(p.source!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('food-quantity'),
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${l.quantity} (${foodUnitLabel(p.unit, l)})',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          for (final k in nutrientKeys)
            Text(
              '${nutrientLabel(k, l)}: ${values?[k] == null ? '—' : foodNumber(values![k]!)} ${extraNutrientUnits[k] ?? ''}',
            ),
          if (values?['calories'] != null)
            Text(
              '${l.energyKilojoules}: ${foodNumber(values!['calories']! * kilojoulesPerKcal)}',
            ),
          const SizedBox(height: 12),
          Text(l.foodMissingHint, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: values == null
              ? null
              : () => Navigator.pop(context, amount),
          child: Text(l.addFoodNote),
        ),
      ],
    );
  }
}
