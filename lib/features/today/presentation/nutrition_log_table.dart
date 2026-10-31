import 'package:flutter/material.dart';

import 'today_log_formatter.dart';

/// Native rendering shared by Today and historical calendar logs.
/// Markdown remains a clipboard/export format, never visible source markup.
class NutritionLogTable extends StatelessWidget {
  const NutritionLogTable({super.key, required this.formatter});
  final TodayLogFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10,
            horizontalMargin: 8,
            headingRowHeight: 40,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            dataTextStyle: style,
            columns: [
              for (final heading in formatter.foodColumns)
                DataColumn(
                  label: Text(
                    ['P (g)', 'C (g)', 'F (g)'].contains(heading)
                        ? heading[0]
                        : heading,
                    style: style,
                  ),
                ),
            ],
            rows: [
              for (final row in formatter.foodRows)
                DataRow(
                  cells: [
                    for (var i = 0; i < row.length; i++)
                      DataCell(
                        i == 0
                            ? Tooltip(
                                message: row[i],
                                child: SizedBox(
                                  width: 120,
                                  child: Text(
                                    row[i],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            : Text(row[i]),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Text('P/C/F: g · kcal'),
        if (formatter.hasMealIngredients)
          Text(formatter.l.mealIngredientTableHint, style: style),
        Text(formatter.l.missingNutritionHint, style: style),
      ],
    );
  }
}
