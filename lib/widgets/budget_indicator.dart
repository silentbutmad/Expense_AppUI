import 'package:flutter/material.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:myapp/theme/app_tokens.dart';
import 'package:provider/provider.dart';

class BudgetIndicator extends StatelessWidget {
  const BudgetIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a hardcoded monthly budget for demonstration
    const double monthlyBudget = 5000.0;

    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Calculate total expenses for the current month from transactions
        final now = DateTime.now();
        double totalExpenses = 0.0;
        
        for (final tx in expenseProvider.personalTransactions) {
          final dateStr = tx['transaction_date'] as String? ?? '';
          if (dateStr.isEmpty) continue;
          try {
            final date = DateTime.parse(dateStr);
            if (date.month == now.month && date.year == now.year) {
              final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
              final type = tx['transaction_type'] as String? ?? '';
              // Only count expenses (not income or loans)
              if (type == 'EXPENSE') {
                totalExpenses += amount;
              }
            }
          } catch (e) {
            // Skip invalid dates
          }
        }

        // Calculate the progress, ensuring it's between 0.0 and 1.0
        final progress = (totalExpenses / monthlyBudget).clamp(0.0, 1.0);
        final percentage = (progress * 100).toStringAsFixed(0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly Budget', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTokens.padding / 2),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(AppTokens.radius / 2),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTokens.padding / 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\u20b9${totalExpenses.toStringAsFixed(0)} / \u20b9${monthlyBudget.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}