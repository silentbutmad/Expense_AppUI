import 'package:flutter/material.dart';
import 'package:myapp/utils/amount_parser.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final tx = widget.transaction;

    final amount = parseAmount(tx['amount']);
    final name = tx['name'] as String? ?? tx['personName'] as String? ?? 'N/A';
    final email = tx['email'] as String? ?? tx['person_email'] as String? ?? 'N/A';
    final category = tx['category'] as String? ?? 'N/A';
    final remark = tx['remark'] as String? ?? 'N/A';
    final paymentMode =
        tx['payment_mode'] as String? ?? tx['paymentMode'] as String? ?? 'N/A';
    final transactionType = tx['transaction_type'] as String? ??
        tx['transactionType'] as String? ??
        'N/A';
    final loanType =
        tx['loan_type'] as String? ?? tx['loanType'] as String? ?? 'N/A';
    final dateStr =
        tx['transaction_date'] as String? ?? tx['date'] as String? ?? '';
    final timeStr =
        tx['transaction_time'] as String? ?? tx['time'] as String? ?? '';
    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Keep date as null
      }
    }

    // Determine color based on transaction type
    Color typeColor;
    String typeLabel;
    switch (transactionType.toUpperCase()) {
      case 'RECEIVED':
        typeColor = Colors.green;
        typeLabel = 'Received';
        break;
      case 'PAID':
        typeColor = Colors.red;
        typeLabel = 'Paid';
        break;
      case 'LOAN':
        typeColor = loanType == 'LENT' ? Colors.blue : Colors.orange;
        typeLabel = 'Loan ($loanType)';
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = transactionType;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTransaction(tx),
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: typeColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: textTheme.headlineLarge?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Details List
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(context, 'Name', name),
                    const Divider(),
                    _buildDetailRow(context, 'Email', email),
                    const Divider(),
                    _buildDetailRow(context, 'Category', category),
                    const Divider(),
                    if (remark != 'N/A') ...[
                      _buildDetailRow(context, 'Remark', remark),
                      const Divider(),
                    ],
                    _buildDetailRow(context, 'Payment Mode', paymentMode),
                    const Divider(),
                    _buildDetailRow(context, 'Transaction Type', typeLabel),
                    const Divider(),
                    if (loanType != 'N/A' && transactionType == 'LOAN')
                      _buildDetailRow(context, 'Loan Type', loanType),
                    if (loanType != 'N/A' && transactionType == 'LOAN')
                      const Divider(),
                    if (date != null)
                      _buildDetailRow(
                        context,
                        'Date',
                        DateFormat.yMMMd().format(date),
                      )
                    else
                      _buildDetailRow(context, 'Date', 'N/A'),
                    const Divider(),
                    if (timeStr.isNotEmpty)
                      _buildDetailRow(context, 'Time', timeStr)
                    else
                      _buildDetailRow(context, 'Time', 'N/A'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editTransaction(context, tx),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteTransaction(context, tx),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Loan Reminder Button
            if (transactionType == 'LOAN' && loanType == 'LENT') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showReminderOptions(context, tx),
                  icon: const Icon(Icons.notification_important),
                  label: const Text('Send Reminder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _shareTransaction(Map<String, dynamic> tx) {
    final amount = parseAmount(tx['amount']);
    final name = tx['name'] as String? ?? tx['personName'] as String? ?? 'N/A';
    final transactionType = tx['transactionType'] as String? ?? 'N/A';
    final category = tx['category'] as String? ?? 'N/A';
    final paymentMode = tx['paymentMode'] as String? ?? 'N/A';
    final dateStr = tx['date'] as String? ?? 'N/A';
    final remark = tx['remark'] as String? ?? '';

    final shareText = '''
Name : $name
Amount : ₹$amount
Type : $transactionType
Category : $category
Payment Mode : $paymentMode
Date : $dateStr
${remark.isNotEmpty ? 'Remark : $remark' : ''}
-----------------
''';

    Share.share(shareText);
  }

  void _editTransaction(BuildContext context, Map<String, dynamic> tx) {
    final transactionId = tx['_id'] as String? ?? tx['id'] as String?;
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit: Transaction ID not found')),
      );
      return;
    }

    // Navigate to AddExpenseScreen with transaction data
    context.push('/add-expense', extra: {
      'isBusiness': false,
      'transactionType': _parseTransactionType(tx['transactionType'] as String?),
      'transactionCategory': _parseTransactionCategory(tx['category'] as String?),
      'transactionId': transactionId,
      'existingTransaction': tx,
    });
  }

  String? _parseTransactionType(String? type) {
    switch (type?.toUpperCase()) {
      case 'RECEIVED':
        return 'RECEIVED';
      case 'PAID':
        return 'PAID';
      case 'LOAN':
        return 'LOAN';
      default:
        return null;
    }
  }

  String? _parseTransactionCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'INCOME':
        return 'INCOME';
      case 'EXPENSE':
        return 'EXPENSE';
      case 'LOAN':
        return 'LOAN';
      default:
        return null;
    }
  }

  Future<void> _deleteTransaction(BuildContext context, Map<String, dynamic> tx) async {
    final transactionId = tx['_id'] as String? ?? tx['id'] as String?;
    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete: Transaction ID not found')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.deleteTransaction(transactionId);

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        Navigator.of(context).pop(); // Go back
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  void _showReminderOptions(BuildContext context, Map<String, dynamic> tx) {
    final transactionId = tx['_id'] as String? ?? tx['id'] as String?;
    final name = tx['name'] as String? ?? tx['personName'] as String? ?? 'there';
    final amount = parseAmount(tx['amount']);
    final dateStr = tx['date'] as String? ?? '';

    if (transactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send reminder: Transaction ID not found')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Reminder'),
        content: Text('Send reminder to $name via:'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _sendReminder(context, transactionId, 'whatsapp', name, amount, dateStr);
            },
            icon: const Icon(Icons.message, color: Colors.green),
            label: const Text('WhatsApp'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _sendReminder(context, transactionId, 'sms', name, amount, dateStr);
            },
            icon: const Icon(Icons.sms, color: Colors.blue),
            label: const Text('SMS'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReminder(
    BuildContext context,
    String transactionId,
    String channel,
    String name,
    double amount,
    String dateStr,
  ) async {
    try {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      await provider.sendReminder(transactionId, channel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reminder sent via $channel')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reminder: $e')),
        );
      }
    }
  }
}