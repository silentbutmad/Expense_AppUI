import 'package:flutter/material.dart';

class CompactBusinessFilterChips extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  const CompactBusinessFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const List<String> _filterOptions = [
    'All',
    'SALE',
    'PURCHASE',
    'EXPENSE',
  ];
  
  static const List<String> _filterLabels = [
    'All',
    'Sales',
    'Purchases',
    'Expenses',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: SizedBox(
        height: 32,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) {
            final filterValue = _filterOptions[index];
            final filterLabel = _filterLabels[index];
            final isSelected = selectedFilter == filterValue;

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilterChip(
                label: Text(
                  filterLabel,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  // Pass null for "All" to show all transactions
                  final valueToSend = filterValue == 'All' ? null : filterValue;
                  onFilterChanged(selected ? valueToSend : null);
                },
                selectedColor: theme.colorScheme.primaryContainer,
                checkmarkColor: theme.colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          },
        ),
      ),
    );
  }
}