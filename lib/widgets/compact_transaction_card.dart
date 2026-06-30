import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CompactTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;
  final VoidCallback? onNameTap;

  const CompactTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onNameTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = (() {
      final val = transaction['total_amount'] ?? transaction['amount'];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    })();
    final transactionType = transaction['transaction_type'] as String? ?? '';
    final category = (() {
      if (transaction['category'] != null && (transaction['category'] as String).isNotEmpty) {
        return transaction['category'] as String;
      }
      final items = transaction['items'];
      if (items is List && items.isNotEmpty) {
        final firstItem = items[0];
        if (firstItem is Map) {
          final desc = firstItem['description'] as String? ?? firstItem['name'] as String? ?? '';
          if (items.length > 1) {
            return '$desc + ${items.length - 1} items';
          }
          return desc;
        }
      }
      return '';
    })();
    final transactionCategory = transaction['transactionCategory'] as String? ?? '';
    final paymentMode = transaction['payment_mode'] as String? ?? '';
    final dateStr = transaction['transaction_date'] as String? ?? '';
    final remark = transaction['remark'] as String? ?? '';
    final isExpenseTransaction = transactionType.toUpperCase() == 'EXPENSE';
    final personName = isExpenseTransaction
        ? (transaction['title'] as String? ?? transaction['description'] as String? ?? '')
        : (transaction['name'] as String? ?? transaction['party']?['name'] as String? ?? transaction['party_name'] as String? ?? '');

    DateTime? date;
    String? timeStr;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
        // Use __transaction_time field if available, fallback to transaction_time, otherwise extract from date
        final transactionTime = transaction['__transaction_time'] as String? ??
                               transaction['transaction_time'] as String?;
        if (transactionTime != null && transactionTime.isNotEmpty) {
          timeStr = transactionTime;
        } else {
          timeStr = DateFormat.jm().format(date);
        }
      } catch (e) {
        // Keep date as null
      }
    }

    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (transactionType.toUpperCase()) {
      case 'INCOME':
      case 'SALE':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        typeLabel = transactionType.toUpperCase() == 'SALE' ? 'Sale' : 'Income';
        break;
      case 'EXPENSE':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Expense';
        break;
      case 'PURCHASE':
        typeColor = Colors.blue;
        typeIcon = Icons.arrow_upward;
        typeLabel = 'Purchase';
        break;
      case 'LOAN':
        final loanType = transaction['loan_type'] as String? ?? '';
        if (loanType == 'LENT') {
          typeColor = Colors.blue;
          typeIcon = Icons.account_balance_wallet;
          typeLabel = 'Lent';
        } else {
          typeColor = Colors.orange;
          typeIcon = Icons.account_balance;
          typeLabel = 'Borrow';
        }
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
        typeLabel = transactionType;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (personName.isNotEmpty)
                          GestureDetector(
                            onTap: onNameTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: typeColor, width: 0.5),
                              ),
                              child: Text(personName, style: TextStyle(color: typeColor, fontWeight: FontWeight.w600, fontSize: 11)),
                            ),
                          ),
                        if (personName.isNotEmpty) const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 12), overflow: TextOverflow.ellipsis),
                              if (transactionCategory.isNotEmpty) Text(transactionCategory, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (date != null) Text(DateFormat.yMMMd().format(date), style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
                        if (date != null && timeStr != null && timeStr.isNotEmpty) Text(' at $timeStr', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
                        if (date != null && paymentMode.isNotEmpty) Text(' • $paymentMode', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  (() {
                    final isPositive = transactionType.toUpperCase() == 'INCOME' || transactionType.toUpperCase() == 'SALE';
                    final sign = isPositive ? '+' : '-';
                    return Text('$sign₹${amount.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: typeColor, fontSize: 13));
                  })(),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                    child: Text(typeLabel, style: TextStyle(fontSize: 9, color: typeColor, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}