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
    final now = DateTime.now();
    
    // Filter transactions from last 7 days
    final recentTransactions = expenseProvider.personalTransactions.where((tx) {
      final dateStr = tx['transaction_date'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        return date.isAfter(now.subtract(const Duration(days: 7)));
      } catch (e) {
        return false;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ExpenseChart(transactions: recentTransactions),
            const SizedBox(height: 20),
            ExpenseList(transactions: expenseProvider.personalTransactions),
          ],
        ),
      ),
    );
  }
}