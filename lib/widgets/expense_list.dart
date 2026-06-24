import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const ExpenseList({super.key, this.transactions = const []});

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'travel':
        return Icons.flight;
      case 'utilities':
        return Icons.power;
      case 'entertainment':
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
      itemCount: transactions.length,
      itemBuilder: (context, index) {
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
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: Icon(
              _getIconForCategory(category),
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              category,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              date != null ? DateFormat.yMMMd().format(date) : 'No date',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              '-\u20b9${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
            ),
          ),
        );
      },
    );
  }
}