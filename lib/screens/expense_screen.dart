import 'package:flutter/material.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/screens/expense_detail_screen.dart';
import 'package:myapp/widgets/expense_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _showChart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final transactions = expenseProvider.personalTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.pie_chart),
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExpenseDetailScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showChart
                ? ExpenseChart(transactions: transactions)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: transactions.isEmpty
                ? const Center(
                    child: Text(
                      'No expenses yet. Add one!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (ctx, index) {
                      final tx = transactions[index];
                      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                      final category = tx['category'] as String? ?? '';
                      final dateStr = tx['transaction_date'] as String? ?? '';
                      final transactionType = tx['transaction_type'] as String? ?? '';

                      DateTime? date;
                      if (dateStr.isNotEmpty) {
                        try {
                          date = DateTime.parse(dateStr);
                        } catch (e) {
                          // Keep date as null
                        }
                      }

                      Color typeColor;
                      switch (transactionType.toUpperCase()) {
                        case 'INCOME':
                          typeColor = Colors.green;
                          break;
                        case 'EXPENSE':
                          typeColor = Colors.red;
                          break;
                        case 'LOAN':
                          typeColor = Colors.orange;
                          break;
                        default:
                          typeColor = Colors.grey;
                      }

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withAlpha(25),
                            child: Icon(
                              _getIconForCategory(category),
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          subtitle: Text(
                            date != null ? DateFormat.yMMMd().format(date) : 'No date',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Text(
                            '\u20b9${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: typeColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add expense screen
          // This will be implemented with proper routing
        },
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
        backgroundColor: theme.colorScheme.primary,
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_bus;
      case 'leisure':
        return Icons.sports_esports;
      case 'work':
        return Icons.work;
      default:
        return Icons.more_horiz;
    }
  }
}