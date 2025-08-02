import 'package:flutter/material.dart';

import '../../../../constants.dart';

class ProductAttributes extends StatelessWidget {
  final Map<String, List<String>> attributes;

  const ProductAttributes({super.key, required this.attributes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = attributes.entries.toList();

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(3),
      },
      border: TableBorder(
        horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      children: List.generate(rows.length, (index) {
        final entry = rows[index];
        final key = entry.key;
        final value = entry.value.join(', ');
        final isStriped = index % 2 == 1;

        return TableRow(
          decoration: BoxDecoration(
            color: isStriped ? Colors.white : Colors.grey.shade100,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                key,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}