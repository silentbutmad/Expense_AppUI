import 'package:flutter/material.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/widgets/expense_chart.dart';
import 'package:myapp/widgets/expense_list.dart';
import 'package:provider/provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final recentExpenses = expenseProvider.expenses.where((expense) {
      return expense.date
          .isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpenseChart(expenses: recentExpenses),
            const SizedBox(height: 20),
            ExpenseList(expenses: expenseProvider.expenses),
          ],
        ),
      ),
    );
  }
}
