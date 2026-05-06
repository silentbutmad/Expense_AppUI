import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/theme/app_tokens.dart';

class ExpensePieChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpensePieChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate total expenses for each category
    final Map<String, double> dataMap = {};
    for (var expense in expenses) {
      dataMap[expense.category] =
          (dataMap[expense.category] ?? 0) + expense.amount;
    }

    // 2. Define a list of colors for the chart sections
    final List<Color> colorList = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
      Colors.pink,
    ];

    // 3. Create pie chart sections from the data map
    final List<PieChartSectionData> sections = [];
    final totalExpenses = expenses.fold<double>(0.0, (sum, item) => sum + item.amount);

    if (totalExpenses == 0) {
      // If there are no expenses, show a single grey section
      sections.add(
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: 'No Data',
          radius: 50.0,
          titleStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
      );
    } else {
      int colorIndex = 0;
      for (var entry in dataMap.entries) {
        final percentage = (entry.value / totalExpenses) * 100;
        sections.add(
          PieChartSectionData(
            color: colorList[colorIndex % colorList.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 50.0,
            titleStyle: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        colorIndex++;
      }
    }

    // 4. Build the UI: Pie Chart + Legend
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.padding),
        // Legend
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: dataMap.keys.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return _buildLegendItem(
              color: colorList[index % colorList.length],
              text: category,
            );
          }).toList(),
        ),
      ],
    );
  }

  // Helper widget for building a legend item
  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
