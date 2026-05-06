import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    double totalExpenses = 0;
    for (var expense in expenses) {
      categoryTotals.update(
        expense.category, // Use category string for grouping
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
      totalExpenses += expense.amount;
    }

    final List<PieChartSectionData> sections = [];
    final List<Color> chartColors = [
      // Use a consistent set of colors for the chart
      Colors.blue.shade400,
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.yellow.shade700,
    ];
    int colorIndex = 0;

    // Create a section for each category
    if (totalExpenses > 0) {
      categoryTotals.forEach((category, total) {
        final color = chartColors[colorIndex % chartColors.length];
        colorIndex++;
        final percentage = (total / totalExpenses) * 100;
        sections.add(
          PieChartSectionData(
            value: total,
            title: '${percentage.toStringAsFixed(0)}%',
            color: color,
            radius: 80, // Increased radius for better visibility
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        );
      });
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        // FIX: Use surfaceContainerHighest instead of deprecated surfaceVariant
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Expense Breakdown',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: sections.isEmpty
                    ? const Center(child: Text('No expense data to display'))
                    : PieChart(
                        PieChartData(
                          sections: sections,
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              // Optional: Handle touch events
                            },
                          ),
                        ),
                      ),
              ),
              if (sections.isNotEmpty) ...[
                const SizedBox(height: 24),
                // Legend
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: categoryTotals.entries.map((entry) {
                    // Find the color for the current category
                    final index =
                        categoryTotals.keys.toList().indexOf(entry.key);
                    final color = chartColors[index % chartColors.length];
                    return _buildLegendItem(context, color, entry.key);
                  }).toList(),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for legend items
  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
