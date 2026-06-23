import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/expense_model.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseList({super.key, this.expenses = const []});

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Food':
        return Icons.fastfood;
      case 'Travel':
        return Icons.flight;
      case 'Utilities':
        return Icons.power;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.money;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final transaction = expenses[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              _getIconForCategory(transaction.category),
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
           
            subtitle: Text(
              DateFormat.yMMMd().format(transaction.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              '-\u20b9${transaction.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        );
      },
    );
  }
}
