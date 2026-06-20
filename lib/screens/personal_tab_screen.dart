import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/expense_model.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class PersonalTabContent extends StatefulWidget {
  const PersonalTabContent({super.key});

  @override
  State<PersonalTabContent> createState() => _PersonalTabContentState();
}

class _PersonalTabContentState extends State<PersonalTabContent> {
  String? _selectedPersonName;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    final totalIncome = expenseProvider.getTotalByCategory(TransactionCategory.income);
    final totalExpense = expenseProvider.getTotalByCategory(TransactionCategory.expense);
    final totalLoan = expenseProvider.getTotalByCategory(TransactionCategory.loan);
    final grandTotal = expenseProvider.getGrandTotal();

    final List<Expense> displayedTransactions = _selectedPersonName == null
        ? expenseProvider.personalExpenses
        : expenseProvider.getPersonalTransactionsByPerson(_selectedPersonName!);

    return PopScope(
      canPop: _selectedPersonName == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedPersonName != null) {
          setState(() {
            _selectedPersonName = null;
          });
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💰 TOP SUMMARY CONTAINER
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Total',
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '\u20b9${grandTotal.toStringAsFixed(2)}',
                      style: textTheme.displayLarge?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Income',
                          '\u20b9${totalIncome.toStringAsFixed(2)}',
                          Colors.green,
                          textTheme,
                        ),
                        _buildSummaryItem(
                          'Expense',
                          '\u20b9${totalExpense.toStringAsFixed(2)}',
                          Colors.red,
                          textTheme,
                        ),
                        _buildSummaryItem(
                          'Loan',
                          '\u20b9${totalLoan.toStringAsFixed(2)}',
                          Colors.orange,
                          textTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🔘 ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/add-expense', extra: {
                        'isBusiness': false,
                        'transactionType': TransactionType.received,
                        'transactionCategory': TransactionCategory.income,
                      });
                    },
                    icon: const Icon(Icons.add_circle, color: Colors.white),
                    label: const Text('Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/add-expense', extra: {
                        'isBusiness': false,
                        'transactionType': TransactionType.paid,
                        'transactionCategory': TransactionCategory.expense,
                      });
                    },
                    icon: const Icon(Icons.remove_circle, color: Colors.white),
                    label: const Text('Expense'),
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/add-expense', extra: {
                        'isBusiness': false,
                        'transactionCategory': TransactionCategory.loan,
                      });
                    },
                    icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    label: const Text('Loan'),
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
            ),

            const SizedBox(height: 25),

            // 📋 TRANSACTIONS LIST
            Text(
              _selectedPersonName == null
                  ? 'All Transactions'
                  : 'Transactions with $_selectedPersonName',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            displayedTransactions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('No transactions found.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = displayedTransactions[index];
                      final isReceived =
                          transaction.transactionType == TransactionType.received;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () {
                            _showTransactionDetails(context, transaction);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Person name - clickable for filtered history
                                if (transaction.personName != null &&
                                    transaction.personName!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPersonName =
                                            transaction.personName;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isReceived
                                            ? Colors.green.withValues(alpha: 0.1)
                                            : Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isReceived
                                              ? Colors.green
                                              : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        transaction.personName!,
                                        style: TextStyle(
                                          color: isReceived
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (transaction.personName != null &&
                                    transaction.personName!.isNotEmpty)
                                  const SizedBox(width: 12),

                                // Transaction details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.title,
                                        style: textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat.yMMMd().format(
                                          transaction.date,
                                        ),
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),

                                // Amount
                                Text(
                                  '${isReceived ? '+' : '-'}\u20b9${transaction.amount.toStringAsFixed(2)}',
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isReceived ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, Color color, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: textTheme.bodyLarge?.copyWith(color: color),
        ),
      ],
    );
  }

  void _showTransactionDetails(BuildContext context, Expense transaction) {
    final isReceived = transaction.transactionType == TransactionType.received;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(transaction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.personName != null &&
                transaction.personName!.isNotEmpty)
              _buildDetailRow('Person', transaction.personName!),
            _buildDetailRow('Amount',
                '${isReceived ? '+' : '-'}\u20b9${transaction.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Type', isReceived ? 'Received' : 'Paid'),
            _buildDetailRow('Date',
                DateFormat.yMMMd().add_jm().format(transaction.date)),
            if (transaction.description != null &&
                transaction.description!.isNotEmpty)
              _buildDetailRow('Description', transaction.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
}