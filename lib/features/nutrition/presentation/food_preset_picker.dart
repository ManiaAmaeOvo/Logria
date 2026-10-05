import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../data/food_preset_repository.dart';
import 'food_library_page.dart';
import 'nutrition_labels.dart';

/// Quick selection in the meal log; library management stays a separate flow.
class FoodPresetPicker extends StatefulWidget {
  const FoodPresetPicker({super.key, required this.repository});
  final FoodPresetRepository repository;

  @override
  State<FoodPresetPicker> createState() => _FoodPresetPickerState();
}

class _FoodPresetPickerState extends State<FoodPresetPicker> {
  late Future<List<FoodPreset>> _foods = widget.repository.list();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.quickAddFood),
      content: SizedBox(
        width: 480,
        height: MediaQuery.sizeOf(context).height * .45,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('quick-food-search'),
              decoration: InputDecoration(
                labelText: l.searchFood,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<FoodPreset>>(
                future: _foods,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _foods = widget.repository.list()),
                        child: Text(l.retry),
                      ),
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
                  if (foods.isEmpty) {
                    return Center(child: Text(l.noFoodMatches));
                  }
                  return ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (context, i) {
                      final p = foods[i];
                      return ListTile(
                        title: Text(foodName(p, l)),
                        subtitle: Text(
                          '${preparationLabel(p.preparation, l)} · ${foodNumber(p.referenceQuantity)} ${foodUnitLabel(p.unit, l)}',
                        ),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
      ],
    );
  }
}
