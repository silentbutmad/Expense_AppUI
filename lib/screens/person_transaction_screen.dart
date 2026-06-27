import 'package:flutter/material.dart';
import 'package:myapp/utils/amount_parser.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:myapp/providers/expense_provider.dart';
import 'package:provider/provider.dart';

class PersonTransactionScreen extends StatefulWidget {
  final String personName;

  const PersonTransactionScreen({
    super.key,
    required this.personName,
  });

  @override
  State<PersonTransactionScreen> createState() => _PersonTransactionScreenState();
}

class _PersonTransactionScreenState extends State<PersonTransactionScreen> {
  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.fetchTransactionsByPerson(widget.personName);
    await provider.fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions with ${widget.personName}'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final transactions = provider.personalTransactions;

          // Loading state
          if (provider.isLoadingTransactions) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (provider.errorMessage != null && transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Unable to fetch transactions. Pull down to retry.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadTransactions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Calculate totals
          double totalAmount = 0.0;
          double totalLent = 0.0;
          double totalBorrow = 0.0;

          for (final tx in transactions) {
            final amount = parseAmount(tx['amount']);
            final transactionType = tx['transaction_type'] as String?;
            final loanType = tx['loan_type'] as String?;

            totalAmount += amount;

            if (transactionType == 'LOAN') {
              if (loanType == 'LENT') {
                totalLent += amount;
              } else if (loanType == 'BORROW') {
                totalBorrow += amount;
              }
            }
          }

          final currentBalance = totalLent - totalBorrow;

          return RefreshIndicator(
            onRefresh: _loadTransactions,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          _buildSummaryRow(
                            'Total Transactions',
                            '₹${totalAmount.toStringAsFixed(2)}',
                            theme,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Total Lent',
                            '₹${totalLent.toStringAsFixed(2)}',
                            theme,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Total Borrow',
                            '₹${totalBorrow.toStringAsFixed(2)}',
                            theme,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Current Balance',
                            '₹${currentBalance.toStringAsFixed(2)}',
                            theme,
                            color: currentBalance >= 0 ? Colors.green : Colors.red,
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transactions List
                  Text(
                    'All Transactions',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  if (transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions found',
                              style: textTheme.bodyLarge?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return _TransactionCard(
                          transaction: tx,
                          onTap: () {
                            context.push('/transaction-detail', extra: tx);
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color ?? theme.colorScheme.primary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = parseAmount(transaction['amount']);
    final transactionType = transaction['transaction_type'] as String? ?? '';
    final category = transaction['category'] as String? ?? '';
    final dateStr = transaction['transaction_date'] as String? ?? '';
    final paymentMode = transaction['payment_mode'] as String? ?? '';

    DateTime? date;
    if (dateStr.isNotEmpty) {
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        // Keep date as null
      }
    }

    Color typeColor;
    IconData typeIcon;

    switch (transactionType.toUpperCase()) {
      case 'INCOME':
        typeColor = Colors.green;
        typeIcon = Icons.arrow_downward;
        break;
      case 'EXPENSE':
        typeColor = Colors.red;
        typeIcon = Icons.arrow_upward;
        break;
      case 'LOAN':
        final loanType = transaction['loan_type'] as String? ?? '';
        if (loanType == 'LENT') {
          typeColor = Colors.blue;
          typeIcon = Icons.account_balance_wallet;
        } else {
          typeColor = Colors.orange;
          typeIcon = Icons.account_balance;
        }
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (date != null)
                          Text(
                            '${DateFormat.yMMMd().format(date)} at ${DateFormat.jm().format(date)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        if (date != null && paymentMode.isNotEmpty)
                          Text(
                            ' • $paymentMode',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}