import 'package:flutter/material.dart';
import 'package:myapp/utils/amount_parser.dart';
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
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No transactions found'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        debugPrint('Transaction $index: $tx');
        
        final amount = parseAmount(tx['amount']);
        final category = tx['category'] as String? ?? tx['name'] as String? ?? 'Unknown';
        final dateStr = tx['transaction_date'] as String? ?? '';
        final transactionTime = tx['transaction_time'] as String? ?? '';
        final transactionType = tx['transaction_type'] as String? ?? '';

        DateTime? date;
        String displayDate = 'No date';
        
        if (dateStr.isNotEmpty) {
          try {
            // Handle YYYY-MM-DD format from backend
            final parts = dateStr.split('-');
            if (parts.length == 3) {
              date = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
              displayDate = DateFormat.yMMMd().format(date!);
              if (transactionTime.isNotEmpty) {
                displayDate += ' at $transactionTime';
              }
            } else {
              date = DateTime.parse(dateStr);
              displayDate = DateFormat.yMMMd().format(date);
            }
          } catch (e) {
            debugPrint('Error parsing date: $e');
            // Keep default 'No date'
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
              displayDate,
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