import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/widgets/expense_list.dart';
import 'package:provider/provider.dart';

enum DateRange {
  thisMonth,
  last30Days,
  allTime,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateRange _selectedRange = DateRange.thisMonth;

  List<Map<String, dynamic>> _getFilteredTransactions(List<Map<String, dynamic>> allTransactions) {
    final now = DateTime.now();
    switch (_selectedRange) {
      case DateRange.thisMonth:
        return allTransactions
            .where((tx) {
              final dateStr = tx['transaction_date'] as String? ?? '';
              if (dateStr.isEmpty) return false;
              try {
                final date = DateTime.parse(dateStr);
                return date.month == now.month && date.year == now.year;
              } catch (e) {
                return false;
              }
            })
            .toList();
      case DateRange.last30Days:
        return allTransactions
            .where((tx) {
              final dateStr = tx['transaction_date'] as String? ?? '';
              if (dateStr.isEmpty) return false;
              try {
                final date = DateTime.parse(dateStr);
                return date.isAfter(now.subtract(const Duration(days: 30)));
              } catch (e) {
                return false;
              }
            })
            .toList();
      case DateRange.allTime:
        return allTransactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final filteredTransactions = _getFilteredTransactions(expenseProvider.personalTransactions);

    // Sort by date descending
    filteredTransactions.sort((a, b) {
      final dateA = DateTime.tryParse(a['transaction_date'] as String? ?? '') ?? DateTime.now();
      final dateB = DateTime.tryParse(b['transaction_date'] as String? ?? '') ?? DateTime.now();
      return dateB.compareTo(dateA);
    });

    // Calculate totals from filtered transactions
    double filteredTotalExpenses = 0.0;
    double filteredTotalIncome = 0.0;
    
    for (final tx in filteredTransactions) {
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final type = tx['transaction_type'] as String? ?? '';
      
      if (type == 'INCOME') {
        filteredTotalIncome += amount;
      } else if (type == 'EXPENSE') {
        filteredTotalExpenses += amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SegmentedButton<DateRange>(
              segments: const [
                ButtonSegment(
                    value: DateRange.thisMonth, label: Text('This Month')),
                ButtonSegment(
                    value: DateRange.last30Days, label: Text('30 Days')),
                ButtonSegment(value: DateRange.allTime, label: Text('All Time')),
              ],
              selected: {_selectedRange},
              onSelectionChanged: (Set<DateRange> newSelection) {
                setState(() {
                  _selectedRange = newSelection.first;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Total Income',
                    amount: filteredTotalIncome,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    title: 'Total Expenses',
                    amount: filteredTotalExpenses,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          if (filteredTransactions.isNotEmpty)
            SizedBox(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 20),
                child: _buildBarChart(context, filteredTransactions),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('No transactions for this period.'))
                : ExpenseList(transactions: filteredTransactions),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context,
      {required String title, required double amount, required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              '\u20b9${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<Map<String, dynamic>> transactions) {
    final DateFormat formatter = DateFormat('MMM d, yy');
    final sortedEntries = _getSortedDailyTotals(transactions, formatter);

    final titlesData = FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (double value, TitleMeta meta) {
            final index = value.toInt();
            if (index >= 0 && index < sortedEntries.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Transform.rotate(
                  angle: -0.785,
                  child: Text(sortedEntries[index].key, style: const TextStyle(fontSize: 9)),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedEntries.isEmpty
            ? 100
            : sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) *
                1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: titlesData,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.value,
                color: Theme.of(context).colorScheme.primary,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              )
            ],
          );
        }).toList(),
      ),
    );
  }

  List<MapEntry<String, double>> _getSortedDailyTotals(
      List<Map<String, dynamic>> transactions, DateFormat formatter) {
    Map<String, double> dailyTotals = {};
    for (var tx in transactions) {
      final dateStr = tx['transaction_date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final date = DateTime.parse(dateStr);
        final day = formatter.format(date);
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + amount;
      } catch (e) {
        // Skip invalid dates
      }
    }

    final sortedEntries = dailyTotals.entries.toList()
      ..sort((a, b) {
        try {
          return formatter.parse(a.key).compareTo(formatter.parse(b.key));
        } catch (e) {
          return 0;
        }
      });

    return sortedEntries;
  }
}